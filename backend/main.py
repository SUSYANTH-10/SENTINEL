from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.auth import hash_password, verify_password
from app.database import Base, engine, get_db
from app.models.customer import Customer
from app.schemas.auth import LoginRequest, SignupRequest

from app.ml.inference import assess_risk


Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SENTINEL API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/")
def root():
    return {
        "message": "SENTINEL API is running"
    }


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

    customer = Customer(
        user_id=request.user_id,
        password_hash=hash_password(request.password),
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
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/api/v1/auth/login")
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

    if not verify_password(
        request.password,
        customer.password_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid user ID or password",
        )

    return {
        "message": "Login successful",
        "authenticated": True,
        "user_id": customer.user_id,
        "balance": customer.balance,
    }


# ============================================================
# RISK ASSESSMENT
# ============================================================

@app.post("/api/v1/assess-risk")
def risk_assessment(
    request: dict,
):
    return assess_risk(request)