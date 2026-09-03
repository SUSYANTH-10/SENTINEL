import datetime
import os
import sys
from typing import Optional

# ============================================================
# ABSOLUTE PATH RESOLUTION
# ============================================================
# Current file:
# SENTINEL/backend/main.py
#
# Project root:
# SENTINEL/
#
# This allows imports such as:
# from app.ml.inference import assess_risk
# ============================================================

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(CURRENT_DIR)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)


# ============================================================
# IMPORTS
# ============================================================

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.ml.inference import assess_risk as evaluate_ml_risk

from app.database import initialize_database

from app.services.customer_service import (
    authenticate_customer,
    create_customer,
    get_customer,
)


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(
    title="SENTINEL Enterprise Risk Engine",
    description="SENTINEL Fraud Shield API",
    version="1.0.0",
)


# ============================================================
# DATABASE INITIALIZATION
# ============================================================

# Creates the SQLite database and customers table
# if they do not already exist.
initialize_database()


# ============================================================
# EXISTING RISK ENGINE MODELS
# ============================================================

class TelemetryData(BaseModel):
    """
    Telemetry collected by the SENTINEL mobile application.
    """

    call_status: str
    overlay_detected: bool
    touch_velocity: float


class TransactionData(BaseModel):
    """
    Transaction information sent to the risk engine.
    """

    amount: float = Field(ge=0)
    recipient_id: str
    is_new_payee: bool = True


class UserContext(BaseModel):
    """
    Additional context about the user's current session.
    """

    failed_login_attempts: int = Field(default=0, ge=0)


class RiskAssessmentRequest(BaseModel):
    """
    Complete request received from the mobile application
    for fraud-risk assessment.
    """

    telemetry: TelemetryData
    transaction: TransactionData
    user_context: Optional[UserContext] = None


# ============================================================
# CUSTOMER / AUTHENTICATION MODELS
# ============================================================

class CustomerRegistration(BaseModel):
    """
    Information required to create a SENTINEL customer.

    IMPORTANT:
    The password is only received temporarily so that it can
    be converted into a secure password hash.
    """

    user_id: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=8, max_length=128)

    balance: float = Field(ge=0)

    average_transaction_amount: float = Field(ge=0)

    highest_transaction_amount: float = Field(ge=0)


class LoginRequest(BaseModel):
    """
    Credentials supplied during login.
    """

    user_id: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=1, max_length=128)


# ============================================================
# ROOT / HEALTH CHECK
# ============================================================

@app.get("/")
def read_root():
    """
    Basic API health check.
    """

    return {
        "status": "active",
        "service": "SENTINEL Fraud Shield API",
    }


# ============================================================
# CUSTOMER REGISTRATION
# ============================================================

@app.post("/api/v1/customers/register")
def register_customer(request: CustomerRegistration):
    """
    Register a new SENTINEL customer.

    The password is hashed before being stored in SQLite.

    Stored customer information:

        user_id
        password_hash
        balance
        average_transaction_amount
        highest_transaction_amount
    """

    # --------------------------------------------------------
    # Check whether customer already exists
    # --------------------------------------------------------

    existing_customer = get_customer(request.user_id)

    if existing_customer is not None:
        raise HTTPException(
            status_code=409,
            detail="Customer already exists",
        )

    # --------------------------------------------------------
    # Validate transaction statistics
    # --------------------------------------------------------

    if (
        request.highest_transaction_amount
        < request.average_transaction_amount
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Highest transaction amount must be greater than "
                "or equal to average transaction amount"
            ),
        )

    # --------------------------------------------------------
    # Create customer
    # --------------------------------------------------------

    try:
        create_customer(
            user_id=request.user_id,
            password=request.password,
            balance=request.balance,
            average_transaction_amount=request.average_transaction_amount,
            highest_transaction_amount=request.highest_transaction_amount,
        )

    except Exception as exc:
        # Avoid exposing internal database details to the client.
        raise HTTPException(
            status_code=500,
            detail="Unable to create customer",
        ) from exc

    return {
        "status": "created",
        "user_id": request.user_id,
    }


# ============================================================
# CUSTOMER LOGIN
# ============================================================

@app.post("/api/v1/auth/login")
def login(request: LoginRequest):
    """
    Authenticate a SENTINEL customer.

    The supplied password is compared against the stored
    password hash.

    No plaintext password is returned or stored.
    """

    customer = authenticate_customer(
        request.user_id,
        request.password,
    )

    if customer is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user ID or password",
        )

    return {
        "status": "authenticated",
        "user_id": customer.user_id,

        "customer": {
            "balance": customer.balance,
            "average_transaction_amount": (
                customer.average_transaction_amount
            ),
            "highest_transaction_amount": (
                customer.highest_transaction_amount
            ),
        },
    }


# ============================================================
# CUSTOMER PROFILE
# ============================================================

@app.get("/api/v1/customers/{user_id}")
def customer_profile(user_id: str):
    """
    Retrieve customer financial statistics.

    NOTE:
    This endpoint is currently intended for the prototype.
    Later we will protect this endpoint using authentication
    tokens so that arbitrary users cannot request another
    customer's profile.
    """

    customer = get_customer(user_id)

    if customer is None:
        raise HTTPException(
            status_code=404,
            detail="Customer not found",
        )

    return {
        "user_id": customer.user_id,

        "balance": customer.balance,

        "average_transaction_amount": (
            customer.average_transaction_amount
        ),

        "highest_transaction_amount": (
            customer.highest_transaction_amount
        ),
    }


# ============================================================
# EXISTING SENTINEL RISK ASSESSMENT API
# ============================================================

@app.post("/api/v1/assess-risk")
def assess_risk_endpoint(request: RiskAssessmentRequest):
    """
    Evaluate transaction risk using:

        - Active call detection
        - Overlay detection
        - Touch velocity
        - Transaction amount
        - New payee status
        - Failed login attempts

    Returns:

        score
        risk_level
        action
        reasons
        evaluated_at
    """

    telemetry = request.telemetry
    transaction = request.transaction

    user_ctx = request.user_context or UserContext()

    # --------------------------------------------------------
    # Determine whether a call is currently active
    # --------------------------------------------------------

    is_call_active = (
        "activeCall" in telemetry.call_status
        or telemetry.call_status == "CallStatus.activeCall"
    )

    # --------------------------------------------------------
    # Run ML / heuristic risk engine
    # --------------------------------------------------------

    ml_result = evaluate_ml_risk(
        call_active=is_call_active,

        overlay_detected=telemetry.overlay_detected,

        touch_velocity=telemetry.touch_velocity,

        amount=transaction.amount,

        is_new_payee=transaction.is_new_payee,

        failed_login_attempts=user_ctx.failed_login_attempts,
    )

    # --------------------------------------------------------
    # Return risk assessment
    # --------------------------------------------------------

    return {
        "score": ml_result["score"],

        "risk_level": ml_result["risk_level"],

        "action": ml_result["action"],

        "reasons": ml_result["reasons"],

        "evaluated_at": datetime.datetime.now().isoformat(),
    }