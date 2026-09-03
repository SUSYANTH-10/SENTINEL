import json
import os
import sqlite3
import sys
import urllib.error
import urllib.request
import uuid

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

BASE_URL = "http://127.0.0.1:8000"

try:
    from fastapi.testclient import TestClient
    import main
    _client = TestClient(main.app)
except Exception:
    _client = None


def post_json(endpoint: str, data: dict):
    if _client is not None:
        r = _client.post(endpoint, json=data)
        try:
            return r.status_code, r.json()
        except Exception:
            return r.status_code, {"detail": r.text}
    req_data = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}{endpoint}",
        data=req_data,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"detail": body}


def get_json(endpoint: str):
    if _client is not None:
        r = _client.get(endpoint)
        try:
            return r.status_code, r.json()
        except Exception:
            return r.status_code, {"detail": r.text}
    req = urllib.request.Request(f"{BASE_URL}{endpoint}")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"detail": body}


def run_tests():
    suffix = uuid.uuid4().hex[:6]
    user_a = f"USER_A_{suffix}"
    user_b = f"USER_B_{suffix}"

    print(f"\n=======================================================")
    print(f"TESTING SENTINEL USER-TO-USER ATOMIC MONEY TRANSFERS")
    print(f"Users: {user_a} & {user_b}")
    print(f"=======================================================\n")

    # 1. Create USER_A with ₹20,000 and safety password
    status, res = post_json(
        "/api/v1/auth/signup",
        {
            "user_id": user_a,
            "password": "Password123!",
            "safety_password": "Safety123!",
            "balance": 20000.0,
        },
    )
    assert status == 201, f"Signup USER_A failed: {res}"
    print(f"✔ 1. Created {user_a} with ₹20,000.00")

    # 2. Create USER_B with ₹10,000
    status, res = post_json(
        "/api/v1/auth/signup",
        {
            "user_id": user_b,
            "password": "Password123!",
            "balance": 10000.0,
        },
    )
    assert status == 201, f"Signup USER_B failed: {res}"
    print(f"✔ 2. Created {user_b} with ₹10,000.00")
    print(f"     Total Money Before Transfer: ₹30,000.00")

    # 3. USER_A sends ₹5,000 to USER_B
    status, res = post_json(
        "/api/v1/transactions",
        {
            "user_id": user_a,
            "recipient_id": user_b,
            "amount": 5000.0,
            "login_mode": "normal",
            "confirmed": True,
        },
    )
    assert status == 200, f"Transfer failed: {res}"
    assert res["status"] == "SUCCESS", f"Expected SUCCESS: {res}"
    assert res["balance"] == 15000.0, f"Expected sender balance 15000: {res}"
    tx_id = res["transaction_id"]
    print(f"✔ 3. Successfully executed transfer: {user_a} → {user_b} (₹5,000.00) [TxID: {tx_id}]")

    # 4. Verify Authoritative Balances & Conservation in Database
    db_path = os.path.join(os.path.dirname(__file__), "sentinel.db")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("SELECT balance FROM customers WHERE user_id = ?", (user_a,))
    bal_a = cur.fetchone()[0]
    cur.execute("SELECT balance FROM customers WHERE user_id = ?", (user_b,))
    bal_b = cur.fetchone()[0]
    conn.close()

    print(f"✔ 4. Database Verification:")
    print(f"     {user_a} Balance: ₹{bal_a:,.2f} (Expected: ₹15,000.00)")
    print(f"     {user_b} Balance: ₹{bal_b:,.2f} (Expected: ₹15,000.00)")
    print(f"     Total Money After Transfer: ₹{bal_a + bal_b:,.2f} (Expected: ₹30,000.00)")
    assert bal_a == 15000.0, f"USER_A balance incorrect: {bal_a}"
    assert bal_b == 15000.0, f"USER_B balance incorrect: {bal_b}"
    assert bal_a + bal_b == 30000.0, f"Money conservation violated! Total={bal_a + bal_b}"

    # 5. Check USER_A History (Outgoing / Sent)
    status, res = get_json(f"/api/v1/transactions?user_id={user_a}&login_mode=normal")
    assert status == 200, f"Fetch tx USER_A failed: {res}"
    txs_a = res["transactions"]
    assert len(txs_a) >= 1, f"Expected >=1 transaction for USER_A: {txs_a}"
    tx_a = next(t for t in txs_a if t["transaction_id"] == tx_id)
    assert tx_a["type"] == "SENT", f"Expected type SENT: {tx_a}"
    assert tx_a["direction"] == "OUTGOING", f"Expected direction OUTGOING: {tx_a}"
    assert tx_a["counterparty"] == user_b, f"Expected counterparty {user_b}: {tx_a}"
    assert tx_a["amount"] == 5000.0
    print(f"✔ 5. USER_A History Verified: SENT -₹5,000.00 to {user_b}")

    # 6. Check USER_B History (Incoming / Received)
    status, res = get_json(f"/api/v1/transactions?user_id={user_b}&login_mode=normal")
    assert status == 200, f"Fetch tx USER_B failed: {res}"
    txs_b = res["transactions"]
    assert len(txs_b) >= 1, f"Expected >=1 transaction for USER_B: {txs_b}"
    tx_b = next(t for t in txs_b if t["transaction_id"] == tx_id)
    assert tx_b["type"] == "RECEIVED", f"Expected type RECEIVED: {tx_b}"
    assert tx_b["direction"] == "INCOMING", f"Expected direction INCOMING: {tx_b}"
    assert tx_b["counterparty"] == user_a, f"Expected counterparty {user_a}: {tx_b}"
    assert tx_b["amount"] == 5000.0
    print(f"✔ 6. USER_B History Verified: RECEIVED +₹5,000.00 from {user_a} (Shared TxID: {tx_id})")

    # 7. Logout & Login Persistence for USER_B
    status, res = post_json(
        "/api/v1/auth/login",
        {"user_id": user_b, "password": "Password123!"},
    )
    assert status == 200
    assert res["balance"] == 15000.0, f"Login balance for USER_B not persisted: {res}"
    print(f"✔ 7. USER_B Login Session Verified: Authoritative balance ₹15,000.00 persists across login")

    # 8. Test Unknown Recipient (Must NOT deduct money)
    status, res = post_json(
        "/api/v1/transactions",
        {
            "user_id": user_a,
            "recipient_id": "DOES_NOT_EXIST",
            "amount": 5000.0,
            "login_mode": "normal",
        },
    )
    assert status == 404, f"Expected 404 for unknown recipient: {status}, {res}"
    assert "User not found" in res.get("detail", ""), f"Unexpected error detail: {res}"
    print(f"✔ 8. Unknown Recipient Rejected Safely (404 Not Found): Zero funds deducted")

    # 9. Test Self-Transfer (Must NOT allow sending to own account)
    status, res = post_json(
        "/api/v1/transactions",
        {
            "user_id": user_a,
            "recipient_id": user_a,
            "amount": 1000.0,
            "login_mode": "normal",
        },
    )
    assert status == 400, f"Expected 400 for self-transfer: {status}, {res}"
    assert "own account" in res.get("detail", ""), f"Unexpected error detail: {res}"
    print(f"✔ 9. Self-Transfer Rejected Safely (400 Bad Request): Zero funds deducted")

    # 10. Test Insufficient Balance
    status, res = post_json(
        "/api/v1/transactions",
        {
            "user_id": user_a,
            "recipient_id": user_b,
            "amount": 99999.0,
            "login_mode": "normal",
        },
    )
    assert status == 400, f"Expected 400 for insufficient balance: {status}, {res}"
    assert "Insufficient balance" in res.get("detail", ""), f"Unexpected error detail: {res}"
    print(f"✔ 10. Insufficient Balance Rejected Safely (400 Bad Request): Zero funds deducted")

    # 11. Test Ghost Mode Isolation (Zero Real Money Moved)
    status, res = post_json(
        "/api/v1/transactions",
        {
            "user_id": user_a,
            "recipient_id": user_b,
            "amount": 3000.0,
            "login_mode": "ghost",
            "confirmed": True,
        },
    )
    assert status == 200, f"Ghost transfer failed: {res}"
    assert res["status"] == "SUCCESS"
    assert res["is_shadow"] is True
    assert res["balance"] == 12000.0, f"Expected shadow balance 12000: {res}"

    # Verify real DB balances were 100% UNMUTATED by Ghost Mode
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT balance FROM customers WHERE user_id = ?", (user_a,))
    real_bal_a = cur.fetchone()[0]
    cur.execute("SELECT balance FROM customers WHERE user_id = ?", (user_b,))
    real_bal_b = cur.fetchone()[0]
    conn.close()

    assert real_bal_a == 15000.0, f"Ghost mode mutated USER_A real balance! {real_bal_a}"
    assert real_bal_b == 15000.0, f"Ghost mode mutated USER_B real balance! {real_bal_b}"
    print(f"✔ 11. Ghost Mode Isolation Verified: Shadow balance = ₹12,000.00, Real Balances = ₹15,000.00 (Zero Real Mutation)")

    print(f"\n=======================================================")
    print(f"🎉 ALL USER-TO-USER TRANSFER REQUIREMENTS VERIFIED & PASSED!")
    print(f"=======================================================\n")


if __name__ == "__main__":
    run_tests()
