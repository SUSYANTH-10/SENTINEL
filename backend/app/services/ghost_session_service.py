import datetime
import threading
import uuid
from typing import Optional

# Isolated in-memory shadow ledger storage.
# Data here NEVER touches SQLite or Customer.balance.
_lock = threading.Lock()
_ghost_sessions: dict[str, dict] = {}


def init_ghost_session(user_id: str, initial_balance: float) -> dict:
    """Initialize or reset an ephemeral Ghost Mode session for a user."""
    with _lock:
        session = {
            "shadow_balance": float(initial_balance),
            "transactions": [],
            "created_at": datetime.datetime.utcnow().isoformat(),
        }
        _ghost_sessions[user_id] = session
        return session


def has_ghost_session(user_id: str) -> bool:
    with _lock:
        return user_id in _ghost_sessions


def get_shadow_balance(user_id: str, fallback_balance: float = 0.0) -> float:
    with _lock:
        if user_id not in _ghost_sessions:
            _ghost_sessions[user_id] = {
                "shadow_balance": float(fallback_balance),
                "transactions": [],
                "created_at": datetime.datetime.utcnow().isoformat(),
            }
        return _ghost_sessions[user_id]["shadow_balance"]


def execute_shadow_transaction(
    user_id: str,
    recipient_id: str,
    amount: float,
    risk_level: str,
    risk_score: float,
    status: str,
    fallback_balance: float = 0.0,
) -> tuple[dict, float]:
    """
    Execute a shadow transaction entirely within the Ghost session memory.
    NEVER mutates real database customer balance.
    """
    with _lock:
        if user_id not in _ghost_sessions:
            _ghost_sessions[user_id] = {
                "shadow_balance": float(fallback_balance),
                "transactions": [],
                "created_at": datetime.datetime.utcnow().isoformat(),
            }

        session = _ghost_sessions[user_id]
        current_balance = session["shadow_balance"]

        if status == "SUCCESS":
            if amount > current_balance:
                raise ValueError("Insufficient shadow balance for payment")
            session["shadow_balance"] = round(current_balance - amount, 2)

        tx_record = {
            "transaction_id": f"GHOST-{uuid.uuid4().hex[:12].upper()}",
            "user_id": user_id,
            "recipient_id": recipient_id,
            "amount": amount,
            "status": status,
            "risk_level": risk_level,
            "risk_score": risk_score,
            "is_shadow": True,
            "balance": session["shadow_balance"],
            "timestamp": datetime.datetime.utcnow().isoformat(),
        }

        # Store in session transactions list
        session["transactions"].insert(0, tx_record)

        return tx_record, session["shadow_balance"]


def get_shadow_transactions(user_id: str) -> list[dict]:
    with _lock:
        if user_id in _ghost_sessions:
            return list(_ghost_sessions[user_id]["transactions"])
        return []


def destroy_ghost_session(user_id: str) -> None:
    """Wipe all shadow state, balance, and shadow transactions for the user."""
    with _lock:
        _ghost_sessions.pop(user_id, None)
