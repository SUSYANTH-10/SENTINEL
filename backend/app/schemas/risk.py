from typing import Optional, Any
from pydantic import BaseModel, Field


class TelemetryData(BaseModel):
    call_status: Optional[str] = None
    call_active: Optional[bool] = None
    overlay_detected: bool = False
    touch_velocity: float = 0.0


class TransactionData(BaseModel):
    amount: float = 0.0
    recipient_id: Optional[str] = None
    is_new_payee: bool = True


class UserContextData(BaseModel):
    failed_login_attempts: int = 0


class RiskAssessmentRequest(BaseModel):
    # Nested structure (as sent by mobile app)
    telemetry: Optional[TelemetryData] = None
    transaction: Optional[TransactionData] = None
    user_context: Optional[UserContextData] = None

    # Flat structure support (direct API usage)
    call_active: Optional[bool] = None
    call_status: Optional[str] = None
    overlay_detected: Optional[bool] = None
    touch_velocity: Optional[float] = None
    amount: Optional[float] = None
    recipient_id: Optional[str] = None
    is_new_payee: Optional[bool] = None
    failed_login_attempts: Optional[int] = None

    def to_inference_kwargs(self) -> dict[str, Any]:
        # 1. Resolve call_active
        is_call_active = False
        if self.call_active is not None:
            is_call_active = bool(self.call_active)
        elif self.call_status is not None:
            is_call_active = (
                "activecall" in self.call_status.lower()
                or self.call_status == "CallStatus.activeCall"
            )
        elif self.telemetry is not None:
            if self.telemetry.call_active is not None:
                is_call_active = bool(self.telemetry.call_active)
            elif self.telemetry.call_status is not None:
                is_call_active = (
                    "activecall" in self.telemetry.call_status.lower()
                    or self.telemetry.call_status == "CallStatus.activeCall"
                )

        # 2. Resolve overlay_detected
        is_overlay_detected = False
        if self.overlay_detected is not None:
            is_overlay_detected = bool(self.overlay_detected)
        elif self.telemetry is not None:
            is_overlay_detected = bool(self.telemetry.overlay_detected)

        # 3. Resolve touch_velocity
        t_velocity = 0.0
        if self.touch_velocity is not None:
            t_velocity = float(self.touch_velocity)
        elif self.telemetry is not None:
            t_velocity = float(self.telemetry.touch_velocity)

        # 4. Resolve amount
        tx_amount = 0.0
        if self.amount is not None:
            tx_amount = float(self.amount)
        elif self.transaction is not None:
            tx_amount = float(self.transaction.amount)

        # 5. Resolve is_new_payee
        new_payee = True
        if self.is_new_payee is not None:
            new_payee = bool(self.is_new_payee)
        elif self.transaction is not None:
            new_payee = bool(self.transaction.is_new_payee)

        # 6. Resolve failed_login_attempts
        failed_attempts = 0
        if self.failed_login_attempts is not None:
            failed_attempts = int(self.failed_login_attempts)
        elif self.user_context is not None:
            failed_attempts = int(self.user_context.failed_login_attempts)

        return {
            "call_active": is_call_active,
            "overlay_detected": is_overlay_detected,
            "touch_velocity": t_velocity,
            "amount": tx_amount,
            "is_new_payee": new_payee,
            "failed_login_attempts": failed_attempts,
        }
