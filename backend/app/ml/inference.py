# ml/inference.py

def assess_risk(
    call_active: bool,
    overlay_detected: bool,
    touch_velocity: float,
    amount: float = 0.0,
    is_new_payee: bool = True,
    failed_login_attempts: int = 0
) -> dict:
    """
    Calculate a risk score based on telemetry signals and transaction context.
    """
    raw_score = 0
    reasons = []

    # 1. Base Telemetry Signals
    if call_active:
        raw_score += 30
        reasons.append("Active call detected during session")

    if overlay_detected:
        raw_score += 40
        reasons.append("Screen overlay / sharing tool active")

    if touch_velocity > 1000:
        raw_score += 30
        reasons.append("High touch velocity indicating stress or urgency")

    # 2. Contextual Multipliers
    context_multiplier = 1.0
    if is_new_payee:
        context_multiplier += 0.2
        reasons.append("Transfer requested to an unverified / new payee")

    if failed_login_attempts > 2:
        context_multiplier += 0.15
        reasons.append(f"Preceded by {failed_login_attempts} failed login attempts")

    evaluated_score = raw_score * context_multiplier

    # 3. HIGH-VALUE ESCALATION RULES (Fix for ₹2,50,000+ Transfers)

    # Rule A: High-value transfer + Active Call + New Payee = Hard BLOCK / High Risk
    if amount >= 100000 and call_active and is_new_payee:
        evaluated_score = max(evaluated_score, 80.0)
        reasons.append(f"CRITICAL: High-value transfer (₹{amount:,.2f}) during active call to new payee")

    # Rule B: Moderate-high value transfer + Active Call = At least WARN
    elif amount >= 25000 and call_active:
        evaluated_score = max(evaluated_score, 55.0)
        reasons.append(f"ELEVATED RISK: Significant amount (₹{amount:,.2f}) being transferred during active call")

    # Rule C: Coercion Combo (Call + Overlay + New Payee)
    if call_active and overlay_detected and is_new_payee:
        evaluated_score = max(evaluated_score, 85.0)
        reasons.append("CRITICAL: Call + Overlay + New Payee matches APP scam pattern")

    # 4. Micro-transaction Dampening (< ₹500)
    final_score = evaluated_score
    if amount > 0 and amount <= 500:
        final_score = min(evaluated_score * 0.5, 65.0)
        if call_active or overlay_detected:
            reasons.append(f"Micro-transaction (₹{amount:.2f}): Score capped to prevent friction")

    final_score = min(max(final_score, 0.0), 100.0)

    # 5. Action Matrix
    if final_score >= 70:
        risk_level = "HIGH"
        action_recommended = "BLOCK"
    elif final_score >= 40:
        risk_level = "MEDIUM"
        action_recommended = "WARN"
    else:
        risk_level = "LOW"
        action_recommended = "ALLOW"

    return {
        "score": round(final_score, 2),
        "risk_level": risk_level,
        "action": action_recommended,
        "reasons": reasons
    }