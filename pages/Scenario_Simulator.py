import os
import sys

# 1. Force the root directory (VEGA/) to be the primary search path
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

# 2. Force the src directory into sys.path as well
SRC_DIR = os.path.join(ROOT_DIR, "src")
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

import numpy as np
import pandas as pd
import plotly.graph_objects as go
import streamlit as st

# 3. Robust import strategy
try:
    from src.scenario_engine import run_scenario_simulation
except ModuleNotFoundError:
    from scenario_engine import run_scenario_simulation

# Page Layout Configuration
st.set_page_config(page_title="VEGA — Scenario Simulator", page_icon="🔮", layout="wide")

st.title("🔮 Interactive Scenario & Stress Test Engine")
st.caption("Simulate real-time financial impact by adjusting payment delays, expenses, and market demand.")
st.markdown("---")

# Controls
st.sidebar.header("🎛️ Scenario Control Panel")

delay_days = st.sidebar.slider(
    "Client Receivable Delay (Days)",
    min_value=0,
    max_value=60,
    value=15,
    step=5,
    help="Simulate average payment delays across active client invoices."
)

expense_mult = st.sidebar.slider(
    "Expense / Cost Multiplier",
    min_value=0.8,
    max_value=1.8,
    value=1.1,
    step=0.05,
    help="Simulate unexpected overhead spikes or supplier price increases."
)

demand_mult = st.sidebar.slider(
    "Market Demand / Revenue Multiplier",
    min_value=0.5,
    max_value=1.5,
    value=0.95,
    step=0.05,
    help="Simulate seasonal demand drops or booking surges."
)

# Simulation Execution
sim_results = run_scenario_simulation(
    delay_days_shift=delay_days,
    expense_multiplier=expense_mult,
    demand_multiplier=demand_mult
)

# Metric Display
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        label="Baseline Cash Buffer",
        value=f"₹{sim_results['base_cash']:,.2f}"
    )

with col2:
    st.metric(
        label="Simulated Cash Position",
        value=f"₹{sim_results['simulated_cash']:,.2f}",
        delta=f"₹{sim_results['cash_difference']:,.2f}",
        delta_color="normal" if sim_results['cash_difference'] >= 0 else "inverse"
    )

with col3:
    st.metric(
        label="Simulated Risk Score",
        value=f"{sim_results['simulated_risk']} / 100",
        delta=f"{sim_results['simulated_risk'] - sim_results['base_risk']} points",
        delta_color="inverse"
    )

with col4:
    st.markdown("### Status")
    status = sim_results["status"].upper()

if "CRITICAL" in status or "HIGH" in status:
    st.error(f"**{sim_results['status']}**")

elif "MEDIUM" in status:
    st.warning(f"**{sim_results['status']}**")

else:
    st.success(f"**{sim_results['status']}**")

st.markdown("---")

# Visualizations & Insights
col_left, col_right = st.columns([1.2, 1])

with col_left:
    st.subheader("📊 Capital Balance Impact Comparison")
    
    fig_comp = go.Figure(data=[
        go.Bar(name='Baseline', x=['Cash Reserves'], y=[sim_results['base_cash']], marker_color='#38bdf8'),
        go.Bar(name='Simulated', x=['Cash Reserves'], y=[sim_results['simulated_cash']], marker_color='#ef4444' if sim_results['cash_difference'] < 0 else '#10b981')
    ])
    fig_comp.update_layout(
        barmode='group',
        height=350,
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font={'color': "#e2e8f0"}
    )
    st.plotly_chart(fig_comp, use_container_width=True)

with col_right:
    st.subheader("💡 Engine Insights")
    st.write(f"• **Receivable Latency Impact:** Delayed payments by **{delay_days} days** tie up approximately **₹{abs(sim_results['cash_difference']):,.2f}** in liquidity.")
    st.write(f"• **Expense Sensitivity:** Operating at a **{int(expense_mult * 100)}%** expense multiplier reduces cash buffers rapidly over 30 days.")
    
    if sim_results['simulated_risk'] >= 70:
        st.error("🚨 **Critical Action Required:** High risk of cash deficit within 30 days. Recommend activating credit lines or issuing early payment discounts to high-volume clients.")
    else:
        st.info("✅ **Buffer Intact:** Current scenario parameters maintain a safe liquidity cushion.")