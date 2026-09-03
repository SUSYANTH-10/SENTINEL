import hashlib
import hmac
import secrets

from app.database import get_connection
from app.models.customer import Customer


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)

    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        200_000,
    )

    return f"{salt.hex()}:{password_hash.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt_hex, hash_hex = stored_hash.split(":", 1)

        salt = bytes.fromhex(salt_hex)
        expected_hash = bytes.fromhex(hash_hex)

        actual_hash = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt,
            200_000,
        )

        return hmac.compare_digest(actual_hash, expected_hash)

    except (ValueError, TypeError):
        return False


def create_customer(
    user_id: str,
    password: str,
    balance: float,
    average_transaction_amount: float,
    highest_transaction_amount: float,
):
    connection = get_connection()

    password_hash = hash_password(password)

    connection.execute(
        """
        INSERT INTO customers (
            user_id,
            password_hash,
            balance,
            average_transaction_amount,
            highest_transaction_amount
        )
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            user_id,
            password_hash,
            balance,
            average_transaction_amount,
            highest_transaction_amount,
        ),
    )

    connection.commit()
    connection.close()


def get_customer(user_id: str):
    connection = get_connection()

    row = connection.execute(
        """
        SELECT
            user_id,
            password_hash,
            balance,
            average_transaction_amount,
            highest_transaction_amount
        FROM customers
        WHERE user_id = ?
        """,
        (user_id,),
    ).fetchone()

    connection.close()

    if row is None:
        return None

    return Customer(
        user_id=row["user_id"],
        password_hash=row["password_hash"],
        balance=row["balance"],
        average_transaction_amount=row["average_transaction_amount"],
        highest_transaction_amount=row["highest_transaction_amount"],
    )


def authenticate_customer(user_id: str, password: str):
    customer = get_customer(user_id)

    if customer is None:
        return None

    if not verify_password(password, customer.password_hash):
        return None

    return customer
