import pandas as pd
import numpy as np

def prepare_forecasting_data():
    """
    Loads raw transaction data and performs feature engineering 
    for cash flow forecasting (Lags, Rolling Averages, Date Features).
    """
    df = pd.read_csv("data/transactions.csv")
    df['date'] = pd.to_datetime(df['date'])
    
    # Aggregate daily net cash flow
    daily_df = df.groupby('date').agg({
        'amount': lambda x: df.loc[x.index[df.loc[x.index, 'type'] == 'Inflow'], 'amount'].sum() - 
                            df.loc[x.index[df.loc[x.index, 'type'] == 'Outflow'], 'amount'].sum()
    }).reset_index().rename(columns={'amount': 'net_cash_flow'})
    
    # Feature Engineering (Lags and Rolling Window Statistics)
    daily_df['cash_lag_1'] = daily_df['net_cash_flow'].shift(1)
    daily_df['cash_lag_7'] = daily_df['net_cash_flow'].shift(7)
    daily_df['rolling_mean_7'] = daily_df['net_cash_flow'].shift(1).rolling(window=7).mean()
    daily_df['rolling_std_7'] = daily_df['net_cash_flow'].shift(1).rolling(window=7).std()
    
    # Calendar features
    daily_df['month'] = daily_df['date'].dt.month
    daily_df['day_of_week'] = daily_df['date'].dt.dayofweek
    
    # Baseline columns needed for model benchmarks
    daily_df['revenue'] = daily_df['net_cash_flow'].apply(lambda x: max(x, 0))
    daily_df['expenses'] = daily_df['net_cash_flow'].apply(lambda x: abs(min(x, 0)))
    
    # Handle lag-generated NaN values
    daily_df = daily_df.bfill().ffill()
    
    return daily_df

def prepare_delay_data():
    """
    Loads receivables data for client payment delay risk prediction.
    """
    df = pd.read_csv("data/receivables.csv")
    X = df[['amount', 'credit_score', 'historical_delay_days', 'invoice_age_days']]
    y = df['is_delayed']  # Target binary flag
    return X, y

if __name__ == "__main__":
    forecast_df = prepare_forecasting_data()
    print("--- PREPROCESSING PREVIEW ---")
    print(forecast_df.head())