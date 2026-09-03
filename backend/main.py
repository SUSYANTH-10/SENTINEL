from fastapi import FastAPI
from pydantic import BaseModel
from app.ml.inference import assess_risk


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
# RISK ASSESSMENT API
# ==========================================

@app.post("/api/v1/assess-risk", response_model=RiskResponse)
def assess_risk_endpoint(data: TelemetryData):

    result = assess_risk(
        call_active=data.call_active,
        overlay_detected=data.overlay_detected,
        touch_velocity=data.touch_velocity
    )

    return RiskResponse(**result)


# ==========================================
# HEALTH CHECK
# ==========================================

@app.get("/")
def health_check():
    return {
        "status": "SENTINAL backend is running"
    }