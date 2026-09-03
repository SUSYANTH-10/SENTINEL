import sqlite3

def check():
    conn = sqlite3.connect('sentinel.db')
    cursor = conn.cursor()
    cursor.execute("SELECT sql FROM sqlite_master WHERE name='transactions'")
    row = cursor.fetchone()
    if row:
        print("Schema:", row[0])
    cursor.execute("SELECT * FROM transactions LIMIT 5")
    rows = cursor.fetchall()
    print(f"Total rows in sample: {len(rows)}")
    for r in rows:
        print(r)
    conn.close()

if __name__ == '__main__':
    check()
