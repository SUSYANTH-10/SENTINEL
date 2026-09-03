import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String
from app.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(String(64), unique=True, index=True, nullable=False)
    user_id = Column(String(50), index=True, nullable=False)
    recipient_id = Column(String(100), nullable=False)
    amount = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    risk_level = Column(String(20), nullable=False, default="LOW")
    risk_score = Column(Float, nullable=False, default=0.0)
    status = Column(String(20), nullable=False, default="SUCCESS")
    is_shadow = Column(Boolean, nullable=False, default=False)
