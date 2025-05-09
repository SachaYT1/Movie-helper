from flask import Flask, request, jsonify
import sqlite3
from pathlib import Path

app = Flask(__name__)
app.config['DATABASE'] = Path(__file__).parent.parent / "database" / "movies.db"

def get_db():
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn

@app.teardown_appcontext
def close_db(error):
    """Закрываем соединение с БД после каждого запроса"""
    if hasattr(app, 'db'):
        app.db.close()

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    
    if not data or 'login' not in data or 'password' not in data:
        return jsonify({'error': 'Login and password are required'}), 400
    
    login = data['login']
    password = data['password']
    
    try:
        conn = get_db()
        conn.execute(
            "INSERT INTO users (login, password) VALUES (?, ?)",
            (login, password)
        )
        conn.commit()
        return jsonify({'message': 'User created successfully'}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'User with this login already exists'}), 409
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == '__main__':
    app.run(debug=True)