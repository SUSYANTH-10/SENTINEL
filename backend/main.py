import datetime
import os
import uuid
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.auth import hash_password, verify_password
from app.database import Base, engine, get_db
from app.models.customer import Customer
from app.models.transaction import Transaction
from app.schemas.auth import LoginRequest, LoginResponse, SignupRequest
from app.schemas.risk import RiskAssessmentRequest
from app.schemas.transaction import TransactionCreateRequest, TransactionResponse
from app.services.ghost_session_service import (
    destroy_ghost_session,
    execute_shadow_transaction,
    get_shadow_balance,
    get_shadow_transactions,
    init_ghost_session,
)
from app.ml.inference import assess_risk


# Auto-migrate SQLite schema and seed standard demo accounts if missing
def _auto_migrate():
    with engine.connect() as conn:
        cursor = conn.connection.cursor()
        cursor.execute("PRAGMA table_info(customers)")
        cols = [row[1] for row in cursor.fetchall()]
        if "safety_password_hash" not in cols:
            cursor.execute("ALTER TABLE customers ADD COLUMN safety_password_hash VARCHAR(255)")
            conn.connection.commit()

        # Seed simulation accounts if not present
        demo_accounts = [
            ("fraudster@upi", "DemoPass123!", 0.0),
            ("scammer@upi", "DemoPass123!", 0.0),
            ("legit_store@upi", "DemoPass123!", 0.0),
            ("mule_account_scammer@upi", "DemoPass123!", 0.0),
            ("safe_vault_police@upi", "DemoPass123!", 0.0),
        ]
        for demo_id, demo_pwd, demo_bal in demo_accounts:
            cursor.execute("SELECT id FROM customers WHERE user_id = ?", (demo_id,))
            if not cursor.fetchone():
                p_hash = hash_password(demo_pwd)
                cursor.execute(
                    "INSERT INTO customers (user_id, password_hash, balance, average_transaction_amount) VALUES (?, ?, ?, ?)",
                    (demo_id, p_hash, demo_bal, 0.0),
                )
        conn.connection.commit()

_auto_migrate()
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SENTINEL API",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# HEALTH CHECK & FRONTEND DASHBOARD
# ============================================================

FRONTEND_INDEX_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "frontend", "index.html")

@app.get("/")
def root(request: Request):
    accept = request.headers.get("accept", "")
    if "text/html" in accept and os.path.exists(FRONTEND_INDEX_PATH):
        return FileResponse(FRONTEND_INDEX_PATH)
    return {
        "message": "SENTINEL API is running",
        "version": "2.0.0",
        "dashboard_url": "/dashboard"
    }

@app.get("/app", response_class=HTMLResponse)
@app.get("/dashboard", response_class=HTMLResponse)
def serve_dashboard():
    if os.path.exists(FRONTEND_INDEX_PATH):
        return FileResponse(FRONTEND_INDEX_PATH)
    return HTMLResponse("<h3>SENTINEL Frontend not found</h3>", status_code=404)


# ============================================================
# SIGN UP
# ============================================================

@app.post("/api/v1/auth/signup", status_code=201)
def signup(
    request: SignupRequest,
    db: Session = Depends(get_db),
):
    existing_customer = (
        db.query(Customer)
        .filter(Customer.user_id == request.user_id)
        .first()
    )

    if existing_customer:
        raise HTTPException(
            status_code=400,
            detail="User ID already exists",
        )

    safety_hash = None
    if request.safety_password:
        if request.safety_password == request.password:
            raise HTTPException(
                status_code=400,
                detail="Safety Password must be different from your normal password.",
            )
        safety_hash = hash_password(request.safety_password)

    customer = Customer(
        user_id=request.user_id,
        password_hash=hash_password(request.password),
        safety_password_hash=safety_hash,
        balance=request.balance,
        average_transaction_amount=0.0,
    )

    db.add(customer)
    db.commit()
    db.refresh(customer)

    return {
        "message": "Account created successfully",
        "user_id": customer.user_id,
        "balance": customer.balance,
        "has_safety_password": safety_hash is not None,
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/api/v1/auth/login", response_model=LoginResponse)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    customer = (
        db.query(Customer)
        .filter(Customer.user_id == request.user_id)
        .first()
    )

    if customer is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user ID or password",
        )

    login_mode = None
    if verify_password(request.password, customer.password_hash):
        login_mode = "normal"
    elif customer.safety_password_hash and verify_password(request.password, customer.safety_password_hash):
        login_mode = "ghost"
        # Initialize an isolated in-memory shadow session starting at real balance
        init_ghost_session(customer.user_id, customer.balance)
    else:
        raise HTTPException(
            status_code=401,
            detail="Invalid user ID or password",
        )

    return LoginResponse(
        message="Login successful",
        authenticated=True,
        user_id=customer.user_id,
        login_mode=login_mode,
        balance=customer.balance,
    )


# ============================================================
# TRANSACTIONS (NORMAL REAL LEDGER & GHOST SHADOW LEDGER)
# ============================================================
# TRANSACTIONS (NORMAL USER-TO-USER LEDGER & GHOST SHADOW LEDGER)
# ============================================================

@app.post("/api/v1/transactions", response_model=TransactionResponse)
def execute_transaction(
    request: TransactionCreateRequest,
    db: Session = Depends(get_db),
):
    # 1. Validate Authenticated Sender
    customer = (
        db.query(Customer)
        .filter(Customer.user_id == request.user_id.strip())
        .first()
    )
    if not customer:
        raise HTTPException(status_code=404, detail="Customer account not found")

    # 2. Validate Amount
    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be greater than zero")

    sender_id_clean = request.user_id.strip()
    recipient_id_clean = request.recipient_id.strip()

    # 3. Prevent Self-Transfer
    if sender_id_clean.lower() == recipient_id_clean.lower():
        raise HTTPException(
            status_code=400,
            detail="You can't transfer money to your own account.",
        )

    is_ghost = request.login_mode == "ghost"

    # 4. Validate Recipient Existence in Authoritative Database
    recipient_customer = (
        db.query(Customer)
        .filter(func.lower(Customer.user_id) == recipient_id_clean.lower())
        .first()
    )
    if not recipient_customer and not is_ghost:
        raise HTTPException(
            status_code=404,
            detail="User not found. We couldn't find an account with this User ID. Please check the ID and try again.",
        )

    # 5. Telemetry extraction & Risk Engine Evaluation
    telemetry = request.telemetry or {}
    call_status = str(telemetry.get("call_status", "CallStatus.idle"))
    is_call = "activecall" in call_status.lower() or telemetry.get("call_active") is True
    overlay = bool(telemetry.get("overlay_detected", False))
    velocity = float(telemetry.get("touch_velocity", 0.0))

    risk_result = assess_risk(
        call_active=is_call,
        overlay_detected=overlay,
        touch_velocity=velocity,
        amount=request.amount,
        is_new_payee=True,
        failed_login_attempts=0,
    )

    risk_level = risk_result["risk_level"]
    risk_score = risk_result["score"]
    reasons = risk_result.get("reasons", [])

    current_active_balance = (
        get_shadow_balance(request.user_id, customer.balance)
        if is_ghost
        else customer.balance
    )

    # 6. Check Insufficient Balance
    if request.amount > current_active_balance:
        raise HTTPException(
            status_code=400,
            detail="Insufficient balance. You don't have enough available balance for this payment.",
        )

    # 7. HIGH RISK Intervention
    if risk_level == "HIGH" and risk_result.get("action") == "BLOCK":
        return TransactionResponse(
            transaction_id=f"BLK-{uuid.uuid4().hex[:10].upper()}",
            user_id=sender_id_clean,
            recipient_id=recipient_id_clean,
            amount=request.amount,
            status="BLOCKED",
            risk_level=risk_level,
            risk_score=risk_score,
            is_shadow=is_ghost,
            balance=current_active_balance,
            reasons=reasons,
            timestamp=datetime.datetime.utcnow().isoformat(),
            message="Transaction paused by SENTINEL fraud prevention system.",
        )

    # 8. MEDIUM RISK Safety Check (if unconfirmed)
    if risk_level == "MEDIUM" and not request.confirmed:
        return TransactionResponse(
            transaction_id=f"WARN-{uuid.uuid4().hex[:10].upper()}",
            user_id=sender_id_clean,
            recipient_id=recipient_id_clean,
            amount=request.amount,
            status="REQUIRES_VERIFICATION",
            risk_level=risk_level,
            risk_score=risk_score,
            is_shadow=is_ghost,
            balance=current_active_balance,
            reasons=reasons,
            timestamp=datetime.datetime.utcnow().isoformat(),
            message="Moderate coercion or unusual activity detected. Verification required.",
        )

    # 9. EXECUTION BRANCH
    if is_ghost:
        # ============================================================
        # GHOST MODE: SHADOW LEDGER ONLY (ZERO REAL MONEY MOVES)
        # ============================================================
        try:
            shadow_tx, new_shadow_bal = execute_shadow_transaction(
                user_id=sender_id_clean,
                recipient_id=recipient_id_clean,
                amount=request.amount,
                risk_level=risk_level,
                risk_score=risk_score,
                status="SUCCESS",
                fallback_balance=customer.balance,
            )
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        return TransactionResponse(
            transaction_id=shadow_tx["transaction_id"],
            user_id=sender_id_clean,
            recipient_id=recipient_id_clean,
            amount=request.amount,
            status="SUCCESS",
            risk_level=risk_level,
            risk_score=risk_score,
            is_shadow=True,
            balance=new_shadow_bal,
            reasons=reasons,
            timestamp=shadow_tx["timestamp"],
            message="Transaction processed successfully.",
        )

    else:
        # ============================================================
        # NORMAL MODE: USER-TO-USER ATOMIC TRANSFER IN SQLITE
        # ============================================================
        customer.balance = round(customer.balance - request.amount, 2)
        customer.average_transaction_amount = round(
            (customer.average_transaction_amount + request.amount) / 2.0, 2
        )

        recipient_customer.balance = round(recipient_customer.balance + request.amount, 2)
        recipient_customer.average_transaction_amount = round(
            (recipient_customer.average_transaction_amount + request.amount) / 2.0, 2
        )

        tx_id = f"TX-{uuid.uuid4().hex[:10].upper()}"
        now = datetime.datetime.utcnow()
        real_tx = Transaction(
            transaction_id=tx_id,
            user_id=customer.user_id,
            recipient_id=recipient_customer.user_id,
            amount=request.amount,
            timestamp=now,
            risk_level=risk_level,
            risk_score=risk_score,
            status="SUCCESS",
            is_shadow=False,
        )

        try:
            db.add(real_tx)
            db.commit()
            db.refresh(customer)
            db.refresh(recipient_customer)
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database transfer failed: {str(e)}")

        return TransactionResponse(
            transaction_id=tx_id,
            user_id=customer.user_id,
            recipient_id=recipient_customer.user_id,
            amount=request.amount,
            status="SUCCESS",
            risk_level=risk_level,
            risk_score=risk_score,
            is_shadow=False,
            balance=customer.balance,
            reasons=reasons,
            timestamp=now.isoformat(),
            message="Transfer completed safely.",
        )


# ============================================================
# TRANSACTION HISTORY (BIDIRECTIONAL SENT & RECEIVED)
# ============================================================

@app.get("/api/v1/transactions")
def get_transactions(
    user_id: str,
    login_mode: str = "normal",
    db: Session = Depends(get_db),
):
    clean_user_id = user_id.strip()
    if login_mode == "ghost":
        # Strictly return session-isolated shadow transactions
        customer = (
            db.query(Customer)
            .filter(func.lower(Customer.user_id) == clean_user_id.lower())
            .first()
        )
        fallback_bal = customer.balance if customer else 0.0
        shadow_bal = get_shadow_balance(clean_user_id, fallback_bal)
        return {
            "user_id": clean_user_id,
            "login_mode": "ghost",
            "balance": shadow_bal,
            "transactions": get_shadow_transactions(clean_user_id),
        }
    else:
        # Query real ledger from SQLite where user is either sender or recipient
        records = (
            db.query(Transaction)
            .filter(
                or_(
                    func.lower(Transaction.user_id) == clean_user_id.lower(),
                    func.lower(Transaction.recipient_id) == clean_user_id.lower(),
                ),
                Transaction.is_shadow == False,
            )
            .order_by(Transaction.timestamp.desc())
            .limit(50)
            .all()
        )

        customer = (
            db.query(Customer)
            .filter(func.lower(Customer.user_id) == clean_user_id.lower())
            .first()
        )
        current_bal = customer.balance if customer else 0.0

        tx_list = []
        for tx in records:
            is_sender = (tx.user_id.lower() == clean_user_id.lower())
            counterparty = tx.recipient_id if is_sender else tx.user_id
            direction_str = "SENT" if is_sender else "RECEIVED"
            flow_str = "OUTGOING" if is_sender else "INCOMING"
            tx_list.append({
                "transaction_id": tx.transaction_id,
                "user_id": clean_user_id,
                "sender_id": tx.user_id,
                "recipient_id": tx.recipient_id,
                "counterparty": counterparty,
                "counterparty_user_id": counterparty,
                "type": direction_str,
                "direction": flow_str,
                "transfer_direction": direction_str,
                "amount": tx.amount,
                "status": tx.status,
                "risk_level": tx.risk_level,
                "risk_score": tx.risk_score,
                "is_shadow": False,
                "timestamp": tx.timestamp.isoformat(),
            })

        return {
            "user_id": clean_user_id,
            "login_mode": "normal",
            "balance": current_bal,
            "transactions": tx_list,
        }


@app.get("/api/v1/user/balance")
def get_user_balance(
    user_id: str,
    login_mode: str = "normal",
    db: Session = Depends(get_db),
):
    clean_user_id = user_id.strip()
    customer = (
        db.query(Customer)
        .filter(func.lower(Customer.user_id) == clean_user_id.lower())
        .first()
    )
    if not customer:
        raise HTTPException(status_code=404, detail="User not found")

    if login_mode == "ghost":
        bal = get_shadow_balance(clean_user_id, customer.balance)
    else:
        bal = customer.balance

    return {
        "user_id": clean_user_id,
        "login_mode": login_mode,
        "balance": bal,
    }


# ============================================================
# GHOST SESSION EXIT
# ============================================================

@app.post("/api/v1/ghost/exit")
def exit_ghost(request: dict):
    user_id = request.get("user_id")
    if user_id:
        destroy_ghost_session(user_id)
    return {
        "message": "Ghost session ended safely.",
        "status": "ok",
    }


# ============================================================
# RISK ASSESSMENT (STANDALONE TELEMETRY EVALUATION)
# ============================================================

@app.post("/api/v1/assess-risk")
def risk_assessment(
    request: RiskAssessmentRequest,
):
    kwargs = request.to_inference_kwargs()
    return assess_risk(**kwargs)