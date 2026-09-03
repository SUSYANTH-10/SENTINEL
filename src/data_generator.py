import numpy as np
import pandas as pd
from datetime import datetime, timedelta

def generate_vega_dataset(seed=42):
    np.random.seed(seed)
    
    # 1. Clients
    client_ids = [f"CLI_{i:03d}" for i in range(1, 51)]
    client_types = np.random.choice(["Corporate", "SME", "Retail"], size=50, p=[0.3, 0.5, 0.2])
    credit_limits = np.where(client_types == "Corporate", 500000, np.where(client_types == "SME", 150000, 50000))
    avg_delay_history = np.random.normal(loc=12, scale=8, size=50).clip(0, 45)
    
    clients_df = pd.DataFrame({
        "client_id": client_ids,
        "client_type": client_types,
        "credit_limit": credit_limits,
        "historical_delay_days": avg_delay_history.round(1)
    })
    
    # 2. Suppliers
    supplier_ids = [f"SUP_{i:03d}" for i in range(1, 21)]
    supplier_types = np.random.choice(["Airlines", "Hotels", "Transport"], size=20, p=[0.4, 0.4, 0.2])
    payment_terms_days = np.random.choice([15, 30, 45], size=20)
    
    suppliers_df = pd.DataFrame({
        "supplier_id": supplier_ids,
        "supplier_type": supplier_types,
        "payment_terms_days": payment_terms_days
    })
    
    # 3. Time Series Data (Daily transactions over 365 days)
    start_date = datetime(2025, 1, 1)
    dates = [start_date + timedelta(days=i) for i in range(365)]
    
    transactions = []
    bookings = []
    expenses = []
    
    for current_date in dates:
        # Seasonality factor (Peak travel in summer/holidays: Jun-Aug, Dec)
        month = current_date.month
        seasonality = 1.4 if month in [6, 7, 8, 12] else (0.8 if month in [1, 2] else 1.0)
        
        # Daily bookings count
        num_bookings = np.random.poisson(lam=5 * seasonality)
        for _ in range(num_bookings):
            client = clients_df.sample(1).iloc[0]
            supplier = suppliers_df.sample(1).iloc[0]
            booking_value = np.random.uniform(10000, 150000) * (1.5 if client["client_type"] == "Corporate" else 1.0)
            margin = np.random.uniform(0.08, 0.20)
            
            # Payment delay logic
            base_delay = client["historical_delay_days"]
            actual_delay = int(np.clip(np.random.normal(loc=base_delay, scale=5), 0, 60))
            is_late = actual_delay > 15
            
            b_id = f"BK_{len(bookings)+1:05d}"
            bookings.append({
                "booking_id": b_id,
                "date": current_date,
                "client_id": client["client_id"],
                "supplier_id": supplier["supplier_id"],
                "booking_value": round(booking_value, 2),
                "margin": round(margin, 4),
                "payment_delay_days": actual_delay,
                "is_late_payment": int(is_late)
            })
            
            # Transaction revenue
            transactions.append({
                "transaction_id": f"TX_{len(transactions)+1:05d}",
                "date": current_date,
                "type": "Inflow",
                "category": "Booking Revenue",
                "amount": round(booking_value * (1 + margin), 2),
                "client_id": client["client_id"]
            })
            
        # Daily Operating Expenses
        op_expense = np.random.uniform(5000, 20000)
        expenses.append({
            "date": current_date,
            "category": "Operations",
            "amount": round(op_expense, 2)
        })
        
        transactions.append({
            "transaction_id": f"TX_{len(transactions)+1:05d}",
            "date": current_date,
            "type": "Outflow",
            "category": "Operations",
            "amount": round(op_expense, 2),
            "client_id": None
        })

    bookings_df = pd.DataFrame(bookings)
    transactions_df = pd.DataFrame(transactions)
    expenses_df = pd.DataFrame(expenses)
    
    # Save datasets
    clients_df.to_csv("data/clients.csv", index=False)
    suppliers_df.to_csv("data/suppliers.csv", index=False)
    bookings_df.to_csv("data/bookings.csv", index=False)
    transactions_df.to_csv("data/transactions.csv", index=False)
    expenses_df.to_csv("data/expenses.csv", index=False)
    
    print("Data generation complete! Files saved in 'data/' directory.")

if __name__ == "__main__":
    generate_vega_dataset()