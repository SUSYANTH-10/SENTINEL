from sqlalchemy import Column, Integer, String, Float
from app.database import Base


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(50), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    safety_password_hash = Column(String(255), nullable=True)
    balance = Column(Float, nullable=False, default=0.0)
    average_transaction_amount = Column(Float, nullable=False, default=0.0)
