import sys
from pathlib import Path

# Fix module import paths for Streamlit subpages
ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.append(str(ROOT_DIR))

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go

st.set_page_config(page_title="VEGA - Receivables & Payables", page_icon="💳", layout="wide")

st.title("💳 Receivables & Payables Intelligence")
st.markdown("Monitor client invoice delay risk, Days Sales Outstanding (DSO), and payment schedules.")

# Mock data generation for receivables intelligence
@st.cache_data
def load_receivables_data():
    np.random.seed(42)
    clients = ["Acme Corp", "Apex Logistics", "Starlight Media", "Nexus Retail", "Horizon Tech", "Omni Health", "Vanguard Industries"]
    data = []
    
    for i in range(1, 26):
        client = np.random.choice(clients)
        amount = np.random.randint(50000, 850000)
        due_days = np.random.randint(-15, 60)  # Negative means overdue
        credit_score = np.random.randint(580, 820)
        
        # Calculate risk score based on credit score & overdue status
        delay_prob = np.clip((800 - credit_score) / 300 + (max(0, -due_days) / 40), 0.05, 0.95)
        
        status = "Overdue" if due_days < 0 else "Pending"
        risk_category = "High" if delay_prob > 0.6 else ("Medium" if delay_prob > 0.3 else "Low")
        
        data.append({
            "Invoice ID": f"INV-{1000 + i}",
            "Client": client,
            "Amount (₹)": amount,
            "Due In (Days)": due_days,
            "Credit Score": credit_score,
            "Delay Probability": round(delay_prob * 100, 1),
            "Status": status,
            "Risk Category": risk_category
        })
    return pd.DataFrame(data)

df = load_receivables_data()

# Summary Metrics Row
col1, col2, col3, col4 = st.columns(4)

total_receivables = df["Amount (₹)"].sum()
overdue_amount = df[df["Status"] == "Overdue"]["Amount (₹)"].sum()
high_risk_count = len(df[df["Risk Category"] == "High"])
avg_dso = 38  # Days Sales Outstanding baseline

col1.metric("Total Outstanding Receivables", f"₹{total_receivables:,.2f}")
col2.metric("Total Overdue Capital", f"₹{overdue_amount:,.2f}", delta="-12% vs last month", delta_color="inverse")
col3.metric("High-Risk Invoices", f"{high_risk_count} Invoices", delta="Requires Action", delta_color="inverse")
col4.metric("Days Sales Outstanding (DSO)", f"{avg_dso} Days", delta="-2 Days improvement")

st.markdown("---")

# Visual Layout
col_left, col_right = st.columns([3, 2])

with col_left:
    st.subheader("📊 Invoice Aging Distribution")
    
    # Categorize into aging buckets
    def get_aging_bucket(days):
        if days > 30: return "30+ Days Away"
        elif days > 0: return "0-30 Days Away"
        elif days >= -30: return "1-30 Days Overdue"
        else: return "30+ Days Overdue"

    df["Aging Bucket"] = df["Due In (Days)"].apply(get_aging_bucket)
    aging_summary = df.groupby("Aging Bucket")["Amount (₹)"].sum().reset_index()
    
    fig_aging = px.bar(
        aging_summary, 
        x="Aging Bucket", 
        y="Amount (₹)",
        color="Aging Bucket",
        color_discrete_map={
            "30+ Days Away": "#2ecc71",
            "0-30 Days Away": "#f1c40f",
            "1-30 Days Overdue": "#e67e22",
            "30+ Days Overdue": "#e74c3c"
        },
        title="Receivables Capital by Maturity Bucket"
    )
    fig_aging.update_layout(template="plotly_dark", showlegend=False)
    st.plotly_chart(fig_aging, use_container_width=True)

with col_right:
    st.subheader("🎯 Client Delay Risk Breakdown")
    risk_counts = df["Risk Category"].value_counts().reset_index()
    risk_counts.columns = ["Risk Category", "Count"]
    
    fig_pie = px.pie(
        risk_counts, 
        names="Risk Category", 
        values="Count",
        color="Risk Category",
        color_discrete_map={"Low": "#2ecc71", "Medium": "#f1c40f", "High": "#e74c3c"},
        hole=0.4,
        title="Invoices by Machine Learning Risk Profile"
    )
    fig_pie.update_layout(template="plotly_dark")
    st.plotly_chart(fig_pie, use_container_width=True)

st.markdown("---")

# Detailed Invoices Data Table
st.subheader("🔍 Active Invoices & Predictive Risk Table")

# Filter interaction
status_filter = st.multiselect("Filter by Risk Category:", ["High", "Medium", "Low"], default=["High", "Medium", "Low"])
filtered_df = df[df["Risk Category"].isin(status_filter)]

st.dataframe(
    filtered_df.style.format({
        "Amount (₹)": "₹{:,.2f}",
        "Delay Probability": "{:.1f}%"
    }),
    use_container_width=True
)