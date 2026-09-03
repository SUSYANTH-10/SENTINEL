import streamlit as st
import pandas as pd
import numpy as np
import joblib

# 1. Page Configuration
st.set_page_config(
    page_title="VEGA — Financial Intelligence Platform",
    page_icon="⚡",
    layout="wide",
    initial_sidebar_state="expanded"
)

# 2. Custom CSS Theme (Fintech Glassmorphism Design)
st.markdown("""
    <style>
    .stApp {
        background-color: #0b0f19;
        color: #e2e8f0;
    }
    .metric-card {
        background: rgba(30, 41, 59, 0.7);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }
    .badge-high {
        background-color: #ef4444;
        color: white;
        padding: 4px 12px;
        border-radius: 20px;
        font-weight: bold;
    }
    .badge-med {
        background-color: #f59e0b;
        color: white;
        padding: 4px 12px;
        border-radius: 20px;
        font-weight: bold;
    }
    .badge-low {
        background-color: #10b981;
        color: white;
        padding: 4px 12px;
        border-radius: 20px;
        font-weight: bold;
    }
    </style>
""", unsafe_allow_html=True)

# 3. Sidebar Header
st.sidebar.image("https://img.icons8.com/fluency/96/polygon.png", width=60)
st.sidebar.title("VEGA AI ENGINE")
st.sidebar.caption("Financial Digital Twin & Autonomous Risk Platform")
st.sidebar.markdown("---")

# 4. Global Status Indicator
st.sidebar.subheader("System Status")
st.sidebar.success("🟢 ML Models: Operational")
st.sidebar.info("🤖 Agent Command: Active")

# 5. Main Home Landing Banner
st.title("⚡ VEGA Autonomous Financial Intelligence")
st.markdown("### Real-Time Cash Flow Forecasting • Risk Engine • Scenario Simulator • 3D Digital Twin")

st.markdown("---")

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.markdown("""
        <div class="metric-card">
            <span style="color: #94a3b8; font-size: 0.9rem;">CURRENT CASH BALANCE</span>
            <h2 style="color: #38bdf8; margin: 5px 0;">₹32.60L</h2>
            <span style="color: #10b981;">▲ +4.2% vs last month</span>
        </div>
    """, unsafe_allow_html=True)

with col2:
    st.markdown("""
        <div class="metric-card">
            <span style="color: #94a3b8; font-size: 0.9rem;">30-DAY FORECAST</span>
            <h2 style="color: #f87171; margin: 5px 0;">₹24.10L</h2>
            <span style="color: #ef4444;">▼ Possible liquidity drop</span>
        </div>
    """, unsafe_allow_html=True)

with col3:
    st.markdown("""
        <div class="metric-card">
            <span style="color: #94a3b8; font-size: 0.9rem;">COMPOSITE RISK SCORE</span>
            <h2 style="color: #f59e0b; margin: 5px 0;">32 / 100</h2>
            <span class="badge-low">🟢 SAFE BUFFER</span>
        </div>
    """, unsafe_allow_html=True)

with col4:
    st.markdown("""
        <div class="metric-card">
            <span style="color: #94a3b8; font-size: 0.9rem;">DEFICIT PROBABILITY</span>
            <h2 style="color: #34d399; margin: 5px 0;">8.4%</h2>
            <span style="color: #34d399;">Monte Carlo (1,000 runs)</span>
        </div>
    """, unsafe_allow_html=True)

st.markdown("---")
st.info("👈 Select a module from the sidebar navigation menu to view deep intelligence, agent traces, or run scenario simulations.")