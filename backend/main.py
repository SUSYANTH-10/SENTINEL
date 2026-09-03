from fastapi import FastAPI
from pydantic import BaseModel


# ==========================================
# SENTINAL Backend API
# ==========================================

app = FastAPI(
    title="SENTINAL Backend API",
    description="Risk assessment API for protecting vulnerable banking customers",
    version="1.0.0"
)


# ==========================================
# REQUEST SCHEMA
# ==========================================

class TelemetryData(BaseModel):
    call_active: bool
    overlay_detected: bool
    touch_velocity: float


# ==========================================
# RESPONSE SCHEMA
# ==========================================

class RiskResponse(BaseModel):
    score: int
    risk_level: str
    action_recommended: str


# ==========================================
# RISK ASSESSMENT
# ==========================================

@app.post("/api/v1/assess-risk", response_model=RiskResponse)
def assess_risk(data: TelemetryData):

    score = 0

    # --------------------------------------
    # 1. Active phone call
    # --------------------------------------
    if data.call_active:
        score += 30

    # --------------------------------------
    # 2. Suspicious overlay detected
    # --------------------------------------
    if data.overlay_detected:
        score += 40

    # --------------------------------------
    # 3. Abnormally high touch velocity
    # --------------------------------------
    if data.touch_velocity > 1000:
        score += 30

    # --------------------------------------
    # Determine risk level
    # --------------------------------------

    if score >= 70:
        risk_level = "HIGH"
        action_recommended = "BLOCK_TRANSACTION"

    elif score >= 40:
        risk_level = "MEDIUM"
        action_recommended = "WARN_USER"

    else:
        risk_level = "LOW"
        action_recommended = "ALLOW"

    # --------------------------------------
    # Return result
    # --------------------------------------

    return RiskResponse(
        score=score,
        risk_level=risk_level,
        action_recommended=action_recommended
    )


# ==========================================
# HEALTH CHECK
# ==========================================

@app.get("/")
def health_check():
    return {
        "status": "SENTINAL backend is running"
    }