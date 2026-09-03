import sqlite3
from pathlib import Path


DATABASE_PATH = Path(__file__).resolve().parent.parent / "sentinel.db"


def get_connection():
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def initialize_database():
    connection = get_connection()

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS customers (
            user_id TEXT PRIMARY KEY,
            password_hash TEXT NOT NULL,
            balance REAL NOT NULL,
            average_transaction_amount REAL NOT NULL,
            highest_transaction_amount REAL NOT NULL
        )
        """
    )

    connection.commit()
    connection.close()