import pandas as pd
import numpy as np

def run_scenario_simulation(delay_days_shift=0, expense_multiplier=1.0, demand_multiplier=1.0):
    """
    Simulates real-time cash impact and risk shifts when interactive scenario sliders move.
    """
    base_cash = 3260000  # Baseline Cash Buffer: ₹32.6L
    
    # Baseline expected monthly projections
    expected_inflows = 4500000 * demand_multiplier
    expected_outflows = 2800000 * expense_multiplier
    
    # Impact of delayed receivables (20% of inflows affected by shift)
    delayed_capital = (expected_inflows * 0.20) * (delay_days_shift / 30.0)
    
    simulated_cash = base_cash + expected_inflows - expected_outflows - delayed_capital
    
    # Composite Risk Score Shift
    base_risk = 32
    risk_delta = int((delay_days_shift * 1.5) + ((expense_multiplier - 1.0) * 60) - ((demand_multiplier - 1.0) * 40))
    simulated_risk = int(np.clip(base_risk + risk_delta, 0, 100))
    
    status = "🔴 HIGH RISK" if simulated_risk >= 70 else ("🟡 MEDIUM RISK" if simulated_risk >= 40 else "🟢 LOW RISK")
    
    return {
        "base_cash": base_cash,
        "simulated_cash": round(simulated_cash, 2),
        "cash_difference": round(simulated_cash - base_cash, 2),
        "base_risk": base_risk,
        "simulated_risk": simulated_risk,
        "status": status
    }

if __name__ == "__main__":
    test_result = run_scenario_simulation(delay_days_shift=15, expense_multiplier=1.1, demand_multiplier=0.95)
    print("--- SCENARIO SIMULATION TEST ---")
    print(test_result)