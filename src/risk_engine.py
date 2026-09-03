import joblib
import pandas as pd
import numpy as np

def calculate_vega_risk(current_cash, upcoming_obligations, avg_delay_prob):
    """
    Computes a composite financial risk score from 0 (Safe) to 100 (Critical).
    """
    # Liquidity pressure metric
    net_position = current_cash - upcoming_obligations
    liquidity_factor = 40 if net_position < 0 else max(0, 30 - (net_position / 10000))
    
    # Late payment risk weight
    delay_factor = avg_delay_prob * 40
    
    # Combined score (0 - 100)
    raw_score = liquidity_factor + delay_factor
    risk_score = int(np.clip(raw_score, 0, 100))
    
    status = "🔴 HIGH" if risk_score >= 70 else ("🟡 MEDIUM" if risk_score >= 40 else "🟢 LOW")
    
    return {
        "risk_score": risk_score,
        "status": status,
        "liquidity_factor": round(float(liquidity_factor), 1),
        "delay_factor": round(float(delay_factor), 1)
    }

if __name__ == "__main__":
    # Sample evaluation run
    test_risk = calculate_vega_risk(current_cash=250000, upcoming_obligations=400000, avg_delay_prob=0.75)
    print("VEGA Risk Engine Test Output:")
    print(f"Risk Score: {test_risk['risk_score']} / 100 | Status: {test_risk['status']}")