import datetime
import os
import sys
from typing import List, Optional

# --- ABSOLUTE PATH RESOLUTION FOR ML MODULE ---
# Get current file path (backend/main.py)
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
# Get parent directory (Project Root: SENTINEL)
PROJECT_ROOT = os.path.dirname(CURRENT_DIR)

# Insert project root at the very beginning of sys.path
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

# Now safely import from ml.inference
try:
    from app.ml.inference import assess_risk as evaluate_ml_risk
except ModuleNotFoundError:
    # Fallback in case main.py is run directly inside root
    from inference import assess_risk as evaluate_ml_risk

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="SENTINEL Enterprise Risk Engine")


class TelemetryData(BaseModel):
    call_status: str
    overlay_detected: bool
    touch_velocity: float


class TransactionData(BaseModel):
    amount: float
    recipient_id: str
    is_new_payee: bool = True


class UserContext(BaseModel):
    failed_login_attempts: int = 0


class RiskAssessmentRequest(BaseModel):
    telemetry: TelemetryData
    transaction: TransactionData
    user_context: Optional[UserContext] = None


@app.get("/")
def read_root():
    return {"status": "active", "service": "SENTINEL Fraud Shield API"}


@app.post("/api/v1/assess-risk")
def assess_risk_endpoint(request: RiskAssessmentRequest):
    telemetry = request.telemetry
    transaction = request.transaction
    user_ctx = request.user_context or UserContext()

    is_call_active = (
        "activeCall" in telemetry.call_status
        or telemetry.call_status == "CallStatus.activeCall"
    )

    # Call ML Inference Engine
    ml_result = evaluate_ml_risk(
        call_active=is_call_active,
        overlay_detected=telemetry.overlay_detected,
        touch_velocity=telemetry.touch_velocity,
        amount=transaction.amount,
        is_new_payee=transaction.is_new_payee,
        failed_login_attempts=user_ctx.failed_login_attempts,
    )

    return {
        "score": ml_result["score"],
        "risk_level": ml_result["risk_level"],
        "action": ml_result["action"],
        "reasons": ml_result["reasons"],
        "evaluated_at": datetime.datetime.now().isoformat(),
    }