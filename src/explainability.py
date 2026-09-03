import joblib
import pandas as pd
import shap

def get_feature_importance():
    """
    Loads trained Payment Delay model and extracts ranked feature importances.
    """
    model = joblib.load("models/payment_delay_model.pkl")
    feature_names = ['amount', 'credit_score', 'historical_delay_days', 'invoice_age_days']
    
    importances = model.feature_importances_
    
    features_df = pd.DataFrame({
        'Feature': feature_names,
        'Importance': importances
    }).sort_values(by='Importance', ascending=False)
    
    return features_df

def get_shap_explainer():
    """
    Returns TreeExplainer for interactive SHAP force/summary plots in Streamlit.
    """
    model = joblib.load("models/payment_delay_model.pkl")
    explainer = shap.TreeExplainer(model)
    return explainer

if __name__ == "__main__":
    df = get_feature_importance()
    print("--- FEATURE IMPORTANCE TABLE ---")
    print(df.to_string(index=False))