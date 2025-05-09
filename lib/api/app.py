from flask import Flask, request, jsonify
import sqlite3
from pathlib import Path

app = Flask(__name__)
app.config['DATABASE'] = Path(__file__).parent.parent.parent / "backend" / "database" / "movies.db"


print(app.config['DATABASE'])
def get_db():
    print(app.config['DATABASE'])
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
    email = data['email']
    
    try:
        conn = get_db()
        conn.execute(
            "INSERT INTO users (login, password, email) VALUES (?, ?, ?)",
            (login, password, email)
        )
        conn.commit()
        return jsonify({'message': 'User created successfully'}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'User with this login already exists'}), 409
    finally:
        if 'conn' in locals():
            conn.close()


@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data or 'login' not in data or 'password' not in data:
        return jsonify({'error': 'Login and password are required'}), 400
    
    login = data['login']
    password = data['password']
    
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT user_id, login, email FROM users WHERE login = ? AND password = ?",
            (login, password)
        )
        user = cursor.fetchone()
        
        if user:
            return jsonify({
                'message': 'Login successful',
                'user_id': user['user_id'],
                'login': user['login'],
                'email': user['email']
            }), 200
        else:
            return jsonify({'error': 'Invalid login or password'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route('/api/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    
    if not data or 'email' not in data:
        return jsonify({'error': 'Email is required'}), 400
    
    email = data['email']
    
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT password FROM users WHERE email = ?",
            (email,)
        )
        user = cursor.fetchone()
        
        if user:
            # В реальном приложении здесь должна быть отправка email
            # с инструкциями по сбросу пароля, но для демонстрации
            # просто возвращаем пароль
            return jsonify({
                'message': 'Password retrieved successfully',
                'password': user['password']
            }), 200
        else:
            return jsonify({'error': 'User with this email not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()


# Эндпоинты для похожих фильмов
@app.route('/api/users/<int:user_id>/similar_movies', methods=['POST'])
def add_similar_movie(user_id):
    data = request.get_json()
    
    required_fields = ['title', 'date_x', 'score', 'genre', 'overview']
    if not data or not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Проверяем существование пользователя
        cursor.execute("SELECT 1 FROM users WHERE user_id = ?", (user_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'User not found'}), 404
        
        # Добавляем фильм
        cursor.execute(
            """INSERT INTO similar_movies 
            (user_id, title, date_x, score, genre, overview, crew, orig_title, 
             status, orig_lang, budget_x, revenue, country) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                user_id,
                data['title'],
                data.get('date_x'),
                float(data['score']) if data.get('score') else None,
                data['genre'],
                data['overview'],
                data.get('crew', ''),
                data.get('orig_title', data['title']),
                data.get('status', ''),
                data.get('orig_lang', ''),
                float(data['budget_x']) if data.get('budget_x') else None,
                float(data['revenue']) if data.get('revenue') else None,
                data.get('country', '')
            )
        )
        conn.commit()
        return jsonify({'message': 'Similar movie added successfully'}), 201
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route('/api/users/<int:user_id>/similar_movies/<int:movie_id>', methods=['DELETE'])
def delete_similar_movie(user_id, movie_id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Проверяем существование фильма
        cursor.execute(
            "SELECT 1 FROM similar_movies WHERE id = ? AND user_id = ?",
            (movie_id, user_id)
        )
        if not cursor.fetchone():
            return jsonify({'error': 'Movie not found'}), 404
        
        # Удаляем фильм
        cursor.execute(
            "DELETE FROM similar_movies WHERE id = ? AND user_id = ?",
            (movie_id, user_id)
        )
        conn.commit()
        
        return jsonify({'message': 'Movie deleted successfully'}), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route('/api/users/<int:user_id>/similar_movies', methods=['GET'])
def get_similar_movies(user_id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute(
            "SELECT * FROM similar_movies WHERE user_id = ?",
            (user_id,)
        )
        movies = cursor.fetchall()
        
        # Преобразуем Row объекты в словари
        movies_list = [dict(movie) for movie in movies]
        
        return jsonify(movies_list), 200
    except sqlite3.Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == '__main__':
    app.run(debug=True)