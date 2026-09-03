import urllib.request
import json
import sqlite3
import uuid
import os

base = 'http://127.0.0.1:8000'
uid = f'live_user_{uuid.uuid4().hex[:6]}'

# 1. Signup with Safety Password
signup_data = json.dumps({
    'user_id': uid,
    'password': 'NormalPassword123!',
    'safety_password': 'SafetyPassword456!',
    'balance': 50000.0
}).encode()

req = urllib.request.Request(f'{base}/api/v1/auth/signup', data=signup_data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    print('1. Live Signup Status:', resp.status)

# 2. Normal Login
login_norm_data = json.dumps({'user_id': uid, 'password': 'NormalPassword123!'}).encode()
req = urllib.request.Request(f'{base}/api/v1/auth/login', data=login_norm_data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode())
    print('2. Live Normal Login Mode:', res['login_mode'])
    assert res['login_mode'] == 'normal'

# 3. Ghost Login
login_ghost_data = json.dumps({'user_id': uid, 'password': 'SafetyPassword456!'}).encode()
req = urllib.request.Request(f'{base}/api/v1/auth/login', data=login_ghost_data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode())
    print('3. Live Ghost Login Mode:', res['login_mode'])
    assert res['login_mode'] == 'ghost'

# 4. Ghost Transaction ₹10,000
tx_data = json.dumps({
    'user_id': uid,
    'recipient_id': 'fraudster@upi',
    'amount': 10000.0,
    'login_mode': 'ghost',
    'confirmed': True
}).encode()
req = urllib.request.Request(f'{base}/api/v1/transactions', data=tx_data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode())
    print('4. Live Ghost Tx Status:', res['status'], 'Shadow Balance:', res['balance'], 'is_shadow:', res['is_shadow'])
    assert res['status'] == 'SUCCESS'
    assert res['is_shadow'] is True
    assert res['balance'] == 40000.0

# 5. Check real DB (Customer balance must be untouched!)
db_path = os.path.join(os.path.dirname(__file__), 'sentinel.db')
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute('SELECT balance FROM customers WHERE user_id = ?', (uid,))
row = c.fetchone()
print('5. SQLITE REAL BALANCE (ZERO MUTATION):', row[0])
assert row[0] == 50000.0
conn.close()

# 6. Exit Ghost Session
exit_data = json.dumps({'user_id': uid}).encode()
req = urllib.request.Request(f'{base}/api/v1/ghost/exit', data=exit_data, headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as resp:
    print('6. Live Ghost Exit Status:', resp.status)

print('\n>>> LIVE FASTAPI SERVER PASSED ALL TESTS OVER HTTP! <<<')
