import json
import os
import sqlite3
import sys
import uuid

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from fastapi.testclient import TestClient
import main

client = TestClient(main.app)


def run_all_tests():
    suffix = uuid.uuid4().hex[:6]
    user_a = f"alice_{suffix}"
    user_b = f"BOB_{suffix}"  # Mixed case testing

    print(f"\n=======================================================")
    print(f"COMPREHENSIVE TRANSFER SUITE: {user_a} <-> {user_b}")
    print(f"=======================================================\n")

    # 1. Signup Alice (₹50,000)
    r = client.post("/api/v1/auth/signup", json={
        "user_id": user_a,
        "password": "Password123!",
        "safety_password": "SafetyPassword123!",
        "balance": 50000.0,
    })
    assert r.status_code == 201, f"Signup failed: {r.text}"
    print(f"[PASS] 1. Created Alice with ₹50,000.00")

    # 2. Signup Bob (₹10,000)
    r = client.post("/api/v1/auth/signup", json={
        "user_id": user_b,
        "password": "Password123!",
        "balance": 10000.0,
    })
    assert r.status_code == 201, f"Signup failed: {r.text}"
    print(f"[PASS] 2. Created Bob with ₹10,000.00")

    # TEST CASE 1: Single transfer (Alice -> Bob ₹5,000)
    # Notice: Alice types Bob's username in lowercase "bob_<suffix>" to verify case-insensitivity
    r = client.post("/api/v1/transactions", json={
        "user_id": user_a,
        "recipient_id": user_b.lower(),
        "amount": 5000.0,
        "login_mode": "normal",
        "confirmed": True,
    })
    assert r.status_code == 200, f"Transfer failed: {r.text}"
    tx1_res = r.json()
    assert tx1_res["status"] == "SUCCESS"
    assert tx1_res["balance"] == 45000.0
    tx1_id = tx1_res["transaction_id"]
    print(f"[PASS] 3. Alice transferred ₹5,000 to Bob (case-insensitive) [TxID: {tx1_id}]")

    # Verify Alice's history
    r = client.get(f"/api/v1/transactions?user_id={user_a}&login_mode=normal")
    assert r.status_code == 200
    a_history = r.json()
    assert a_history["balance"] == 45000.0
    txs = [t for t in a_history["transactions"] if t["transaction_id"] == tx1_id]
    assert len(txs) == 1, "Expected exactly 1 transaction in Alice's history"
    tx_a = txs[0]
    assert tx_a["type"] == "SENT"
    assert tx_a["direction"] == "OUTGOING"
    assert tx_a["counterparty"] == user_b
    assert tx_a["amount"] == 5000.0
    print(f"[PASS] 4. Alice's history reflects Sent to Bob (-₹5,000.00)")

    # Verify Bob's history
    r = client.get(f"/api/v1/transactions?user_id={user_b}&login_mode=normal")
    assert r.status_code == 200
    b_history = r.json()
    assert b_history["balance"] == 15000.0
    txs = [t for t in b_history["transactions"] if t["transaction_id"] == tx1_id]
    assert len(txs) == 1, "Expected exactly 1 transaction in Bob's history"
    tx_b = txs[0]
    assert tx_b["type"] == "RECEIVED"
    assert tx_b["direction"] == "INCOMING"
    assert tx_b["counterparty"] == user_a
    assert tx_b["amount"] == 5000.0
    print(f"[PASS] 5. Bob's history reflects Received from Alice (+₹5,000.00)")

    # TEST CASE 2: Reverse transfer (Bob -> Alice ₹2,000)
    r = client.post("/api/v1/transactions", json={
        "user_id": user_b,
        "recipient_id": user_a.upper(),  # Testing uppercase target
        "amount": 2000.0,
        "login_mode": "normal",
        "confirmed": True,
    })
    assert r.status_code == 200, f"Reverse transfer failed: {r.text}"
    tx2_res = r.json()
    assert tx2_res["status"] == "SUCCESS"
    assert tx2_res["balance"] == 13000.0
    tx2_id = tx2_res["transaction_id"]
    print(f"[PASS] 6. Bob transferred ₹2,000 back to Alice [TxID: {tx2_id}]")

    # Check Alice's updated history: should have 2 transactions (1 sent, 1 received)
    r = client.get(f"/api/v1/transactions?user_id={user_a}&login_mode=normal")
    a_history = r.json()
    assert a_history["balance"] == 47000.0
    assert len(a_history["transactions"]) == 2
    # Latest transaction is the ₹2,000 incoming
    latest_a = a_history["transactions"][0]
    assert latest_a["transaction_id"] == tx2_id
    assert latest_a["type"] == "RECEIVED"
    assert latest_a["direction"] == "INCOMING"
    assert latest_a["counterparty"] == user_b
    assert latest_a["amount"] == 2000.0
    print(f"[PASS] 7. Alice's history now shows both transfers: +₹2,000 from Bob, -₹5,000 to Bob")

    # Check Bob's updated history: should have 2 transactions (1 sent, 1 received)
    r = client.get(f"/api/v1/transactions?user_id={user_b}&login_mode=normal")
    b_history = r.json()
    assert b_history["balance"] == 13000.0
    assert len(b_history["transactions"]) == 2
    latest_b = b_history["transactions"][0]
    assert latest_b["transaction_id"] == tx2_id
    assert latest_b["type"] == "SENT"
    assert latest_b["direction"] == "OUTGOING"
    assert latest_b["counterparty"] == user_a
    assert latest_b["amount"] == 2000.0
    print(f"[PASS] 8. Bob's history now shows both transfers: -₹2,000 to Alice, +₹5,000 from Alice")

    # TEST CASE 3: Refresh persistence
    for i in range(3):
        r = client.get(f"/api/v1/transactions?user_id={user_b}&login_mode=normal")
        assert r.status_code == 200
        assert r.json()["balance"] == 13000.0
        assert len(r.json()["transactions"]) == 2
    print(f"[PASS] 9. Transaction history is idempotent and persistent across multiple refreshes")

    # TEST CASE 4: Logout / Login persistence
    # Simulate Bob logging back in
    r = client.post("/api/v1/auth/login", json={
        "user_id": user_b,
        "password": "Password123!",
    })
    assert r.status_code == 200
    login_data = r.json()
    assert login_data["balance"] == 13000.0
    # Query history after re-login
    r = client.get(f"/api/v1/transactions?user_id={user_b}&login_mode=normal")
    assert r.status_code == 200
    assert len(r.json()["transactions"]) == 2
    print(f"[PASS] 10. Balances and history persist across logout/login")

    # TEST CASE 5: Ghost mode isolation
    r = client.post("/api/v1/transactions", json={
        "user_id": user_a,
        "recipient_id": "scammer_threat@upi",
        "amount": 10000.0,
        "login_mode": "ghost",
        "confirmed": True,
    })
    assert r.status_code == 200
    assert r.json()["is_shadow"] is True
    # Alice normal balance remains 47,000.0
    r = client.get(f"/api/v1/transactions?user_id={user_a}&login_mode=normal")
    assert r.json()["balance"] == 47000.0
    assert len(r.json()["transactions"]) == 2, "Ghost tx must NOT leak into normal history"
    print(f"[PASS] 11. Ghost Mode shadow transaction isolated from normal history")

    # TEST CASE 6: Balance endpoint check
    r = client.get(f"/api/v1/user/balance?user_id={user_a}&login_mode=normal")
    assert r.status_code == 200
    assert r.json()["balance"] == 47000.0
    r = client.get(f"/api/v1/user/balance?user_id={user_b}&login_mode=normal")
    assert r.status_code == 200
    assert r.json()["balance"] == 13000.0
    print(f"[PASS] 12. Dedicated /api/v1/user/balance endpoint verified")

    print("\n=======================================================")
    print("ALL INTEGRATION TESTS PASSED SUCCESSFULLY!")
    print("=======================================================\n")


if __name__ == "__main__":
    run_all_tests()
