# ==========================================
# SENTINAL Risk Inference Engine
# ==========================================


def assess_risk(
    call_active: bool,
    overlay_detected: bool,
    touch_velocity: float
):
    """
    Calculate a risk score based on telemetry signals.

    Returns:
        dict containing score, risk_level,
        and action_recommended.
    """

    score = 0

    # --------------------------------------
    # 1. Active phone call
    # --------------------------------------
    if call_active:
        score += 30

    # --------------------------------------
    # 2. Suspicious overlay detected
    # --------------------------------------
    if overlay_detected:
        score += 40

    # --------------------------------------
    # 3. Abnormally high touch velocity
    # --------------------------------------
    if touch_velocity > 1000:
        score += 30

    # --------------------------------------
    # Determine risk level and action
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

    return {
        "score": score,
        "risk_level": risk_level,
        "action_recommended": action_recommended
    }