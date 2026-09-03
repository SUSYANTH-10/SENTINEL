import joblib
import pandas as pd
from sklearn.ensemble import IsolationForest

def train_anomaly_detector():
    transactions = pd.read_csv("data/transactions.csv")
    X = transactions[["amount"]]
    
    # Fit Isolation Forest (assuming ~3% anomaly contamination)
    iso = IsolationForest(contamination=0.03, random_state=42)
    transactions["is_anomaly"] = iso.fit_predict(X)
    
    # -1 represents an anomaly
    anomalies = transactions[transactions["is_anomaly"] == -1]
    
    joblib.dump(iso, "models/anomaly_detector_model.pkl")
    print(f"Anomaly Detector Trained. Detected {len(anomalies)} potential anomalies out of {len(transactions)} transactions.")
    print("Saved -> models/anomaly_detector_model.pkl")

if __name__ == "__main__":
    train_anomaly_detector()