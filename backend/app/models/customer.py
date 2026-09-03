from dataclasses import dataclass


@dataclass
class Customer:
    user_id: str
    password_hash: str
    balance: float
    average_transaction_amount: float
    highest_transaction_amount: float
    