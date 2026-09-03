import joblib
from xgboost import XGBRegressor
from sklearn.metrics import mean_absolute_error, r2_score
from preprocessing import prepare_forecasting_data

def train_forecasting_model():
    df = prepare_forecasting_data()
    
    X = df[['revenue', 'expenses', 'cash_lag_1', 'cash_lag_7', 'rolling_mean_7', 'rolling_std_7', 'month', 'day_of_week']]
    y = df['net_cash_flow']
    
    # Time-series split (80% train, 20% test)
    split_idx = int(len(X) * 0.8)
    X_train, X_test = X.iloc[:split_idx], X.iloc[split_idx:]
    y_train, y_test = y.iloc[:split_idx], y.iloc[split_idx:]
    
    model = XGBRegressor(n_estimators=100, learning_rate=0.05, random_state=42)
    model.fit(X_train, y_train)
    
    preds = model.predict(X_test)
    mae = mean_absolute_error(y_test, preds)
    r2 = r2_score(y_test, preds)
    
    print(f"Cash Forecast Model Trained. MAE: ₹{round(mae, 2)}, R2 Score: {round(r2, 4)}")
    
    joblib.dump(model, "models/cash_forecast_model.pkl")
    print("Saved -> models/cash_forecast_model.pkl")

if __name__ == "__main__":
    train_forecasting_model()