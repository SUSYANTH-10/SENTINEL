import pandas as pd
from xgboost import XGBRegressor
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, r2_score
from preprocessing import prepare_forecasting_data

def benchmark_models():
    df = prepare_forecasting_data()
    X = df[['revenue', 'expenses', 'cash_lag_1', 'cash_lag_7', 'rolling_mean_7', 'rolling_std_7', 'month', 'day_of_week']]
    y = df['net_cash_flow']
    
    split_idx = int(len(X) * 0.8)
    X_train, X_test = X.iloc[:split_idx], X.iloc[split_idx:]
    y_train, y_test = y.iloc[:split_idx], y.iloc[split_idx:]
    
    models = {
        "Random Forest": RandomForestRegressor(n_estimators=100, random_state=42),
        "Gradient Boosting": GradientBoostingRegressor(n_estimators=100, random_state=42),
        "XGBoost": XGBRegressor(n_estimators=100, learning_rate=0.05, random_state=42)
    }
    
    results = []
    for name, model in models.items():
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        results.append({
            "Model": name,
            "MAE (₹)": round(mean_absolute_error(y_test, preds), 2),
            "R2 Score": round(r2_score(y_test, preds), 4)
        })
    
    results_df = pd.DataFrame(results)
    print("--- FORECASTING MODEL BENCHMARK RESULTS ---")
    print(results_df.to_string(index=False))
    results_df.to_csv("data/model_benchmark_results.csv", index=False)
    print("\nBenchmark saved -> data/model_benchmark_results.csv")

if __name__ == "__main__":
    benchmark_models()