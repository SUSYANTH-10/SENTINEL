import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from preprocessing import prepare_delay_data

def train_delay_model():
    X, y = prepare_delay_data()
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    
    print(f"Payment Delay Model Trained. Accuracy: {round(acc * 100, 2)}%")
    
    joblib.dump(model, "models/payment_delay_model.pkl")
    print("Saved -> models/payment_delay_model.pkl")

if __name__ == "__main__":
    train_delay_model()