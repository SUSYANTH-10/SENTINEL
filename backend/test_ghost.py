import main
from app.database import SessionLocal
from fastapi.testclient import TestClient

client = TestClient(main.app)

def test_ghost_flow():
    import uuid
    uid = f"user_{uuid.uuid4().hex[:8]}"

    # 1. Signup with Safety Password
    signup_res = client.post('/api/v1/auth/signup', json={
        'user_id': uid,
        'password': 'NormalPass123!',
        'safety_password': 'SafetyPass456!',
        'balance': 50000.0
    })
    print('1. Signup Status:', signup_res.status_code)
    assert signup_res.status_code == 201

    # 2. Normal Login
    norm_login = client.post('/api/v1/auth/login', json={
        'user_id': uid,
        'password': 'NormalPass123!'
    })
    print('2. Normal Login Mode:', norm_login.json()['login_mode'])
    assert norm_login.json()['login_mode'] == 'normal'

    # 3. Ghost Login
    ghost_login = client.post('/api/v1/auth/login', json={
        'user_id': uid,
        'password': 'SafetyPass456!'
    })
    print('3. Ghost Login Mode:', ghost_login.json()['login_mode'])
    assert ghost_login.json()['login_mode'] == 'ghost'

    # 4. Ghost Transaction ₹8,000
    ghost_tx1 = client.post('/api/v1/transactions', json={
        'user_id': uid,
        'recipient_id': 'scammer@upi',
        'amount': 8000.0,
        'login_mode': 'ghost'
    })
    print('4. Ghost Tx 1 Status:', ghost_tx1.json()['status'], 'Shadow Balance:', ghost_tx1.json()['balance'])
    assert ghost_tx1.json()['status'] == 'SUCCESS'
    assert ghost_tx1.json()['is_shadow'] is True
    assert ghost_tx1.json()['balance'] == 42000.0

    # 5. Check real DB balance - MUST BE UNTOUCHED (50000.0)
    with SessionLocal() as session:
        c = session.query(main.Customer).filter(main.Customer.user_id == uid).first()
        print('5. Database Real Balance (untouched):', c.balance)
        assert c.balance == 50000.0

    # 6. Ghost Transaction ₹2,000
    ghost_tx2 = client.post('/api/v1/transactions', json={
        'user_id': uid,
        'recipient_id': 'scammer@upi',
        'amount': 2000.0,
        'login_mode': 'ghost'
    })
    print('6. Ghost Tx 2 Shadow Balance:', ghost_tx2.json()['balance'])
    assert ghost_tx2.json()['balance'] == 40000.0

    # 7. Check real DB balance again - MUST BE 50000.0
    with SessionLocal() as session:
        c = session.query(main.Customer).filter(main.Customer.user_id == uid).first()
        print('7. Database Real Balance still 50000.0:', c.balance)
        assert c.balance == 50000.0

    # 8. Ledger isolation
    ghost_history = client.get(f'/api/v1/transactions?user_id={uid}&login_mode=ghost').json()
    normal_history = client.get(f'/api/v1/transactions?user_id={uid}&login_mode=normal').json()
    print('8. Ghost Ledger count:', len(ghost_history['transactions']), 'Real Ledger count:', len(normal_history['transactions']))
    assert len(ghost_history['transactions']) == 2
    assert len(normal_history['transactions']) == 0

    # 9. Normal Transaction ₹5,000 -> Real balance mutates
    norm_tx = client.post('/api/v1/transactions', json={
        'user_id': uid,
        'recipient_id': 'legit_store@upi',
        'amount': 5000.0,
        'login_mode': 'normal'
    })
    print('9. Normal Tx Real Balance:', norm_tx.json()['balance'])
    assert norm_tx.json()['balance'] == 45000.0

    with SessionLocal() as session:
        c = session.query(main.Customer).filter(main.Customer.user_id == uid).first()
        print('Database Real Balance after normal tx:', c.balance)
        assert c.balance == 45000.0

    # 10. Exit Ghost Session
    exit_res = client.post('/api/v1/ghost/exit', json={'user_id': uid})
    assert exit_res.status_code == 200
    print('10. Ghost Exit: OK')

    print('\n>>> ALL 10 GHOST MODE INTEGRATION CHECKS PASSED PERFECTLY! <<<')

if __name__ == '__main__':
    test_ghost_flow()
