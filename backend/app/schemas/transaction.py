from typing import Any, Optional
from pydantic import BaseModel, Field


class TransactionCreateRequest(BaseModel):
    user_id: str = Field(min_length=1)
    recipient_id: str = Field(min_length=1)
    amount: float = Field(gt=0)
    login_mode: str = Field(default="normal")  # "normal" or "ghost"
    telemetry: Optional[dict[str, Any]] = None
    confirmed: bool = Field(default=True)


class TransactionResponse(BaseModel):
    transaction_id: str
    user_id: str
    recipient_id: str
    amount: float
    status: str  # "SUCCESS", "BLOCKED", "CANCELLED", "REQUIRES_VERIFICATION"
    risk_level: str  # "LOW", "MEDIUM", "HIGH"
    risk_score: float
    is_shadow: bool
    balance: float  # Current balance (real if normal, shadow if ghost)
    reasons: list[str] = []
    timestamp: str
    message: str
