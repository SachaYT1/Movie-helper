from flask import Flask, request, jsonify
import sqlite3
import re
from pathlib import Path
from sentence_transformers import SentenceTransformer
import numpy as np
import json
from sklearn.metrics.pairwise import cosine_similarity
import requests
from threading import Thread
from werkzeug.security import generate_password_hash, check_password_hash


model = SentenceTransformer('all-MiniLM-L6-v2')

app = Flask(__name__)
app.config['DATABASE'] = Path(__file__).parent.parent.parent / "backend" / "database" / "movies.db"
app.config['SEND_TELEGRAM_NOTIFICATIONS'] = True
app.config['TELEGRAM_CHAT_ID'] = [922279354, 471661173]
app.config['TELEGRAM_BOT_TOKEN'] = '7578670137:AAEqEP36zQ-aAFaDm7uHRyjkfIGkPC8Gqvg'
           
print(app.config['DATABASE'])
def get_db():
    print(app.config['DATABASE'])
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn

def send_telegram_notification(feedback_data):
    """Отправка уведомления в Telegram"""
    if not app.config['SEND_TELEGRAM_NOTIFICATIONS']:
        return
    
    # Проверяем наличие обязательных полей
    if not isinstance(feedback_data, dict) or 'user_id' not in feedback_data or 'grade' not in feedback_data:
        app.logger.error("Invalid feedback data format")
        return
        
    message = (
        "📝 Новый отзыв!\n"
        f"Пользователь ID: {feedback_data['user_id']}\n"
        f"Оценка: {'★' * feedback_data['grade']}\n"
        f"Текст: {feedback_data.get('text', 'Без текста')}"
    )
    
    try:
        for id in app.config['TELEGRAM_CHAT_ID']:
            requests.post(
                f"https://api.telegram.org/bot{app.config['TELEGRAM_BOT_TOKEN']}/sendMessage",
                json={
                    'chat_id': id,
                    'text': message,
                    'parse_mode': 'Markdown'
                }
            )
    except Exception as e:
        app.logger.error(f"Ошибка отправки в Telegram: {e}")

def extract_actors(text):
    """
    Извлекает имена актеров из текста, корректно разделяя их по 'and' и запятым.
    Пример:
        "with Tom Hardi and Elizabeth Groth" -> ["Tom Hardi", "Elizabeth Groth"]
        "film with Roman Shechin, Tom Hardi and Elizabeth Groth" 
        -> ["Roman Shechin", "Tom Hardi", "Elizabeth Groth"]
    """
    # Находим всю часть текста после 'with'
    match = re.search(r'with\s+(.*)', text, re.IGNORECASE)
    if not match:
        return []
    
    actors_part = match.group(1)
    
    # Разделяем актеров по запятым и 'and'
    actors = re.split(r',\s*|\s+and\s+', actors_part)
    
    # Очищаем и проверяем каждое имя
    result = []
    for actor in actors:
        actor = actor.strip()
        if re.match(r'^[A-Z][a-z]+\s+[A-Z][a-z]+', actor):
            result.append(actor)
    
    return result

@app.teardown_appcontext
def close_db(error):
    """Закрываем соединение с БД после каждого запроса"""
    if hasattr(app, 'db'):
        app.db.close()

@app.route('/api/ml/recommendations', methods=['POST'])
def get_ml_recommendations():
    data = request.get_json()
    
    # Проверка обязательных полей в запросе
    if not data or 'description' not in data or 'genres' not in data or 'user_id' not in data:
        return jsonify({'error': 'Description, genres and user_id are required'}), 400
    
    try:
        # Получаем параметры из запроса
        user_id = data['user_id']
        description = data['description']
        genres = [g.strip() for g in data['genres'].split(',')]
        actors = extract_actors(description)
        
        conn = get_db()
        cursor = conn.cursor()
        
        # 1. Получаем похожие фильмы пользователя
        cursor.execute("""
            SELECT overview 
            FROM similar_movies 
            WHERE user_id = ? 
            AND overview IS NOT NULL 
            AND overview != ''
        """, (user_id,))
        similar_movies = [row[0] for row in cursor.fetchall()]
        
        # 2. Получаем фильмы по жанрам
        query = """
            SELECT id, title, overview, genre, score, crew 
            FROM movies 
            WHERE genre LIKE ? 
            AND overview IS NOT NULL 
            AND overview != ''
        """
        params = [f"%{genres[0]}%"]
        
        cursor.execute(query, params)
        movies = cursor.fetchall()
        
        if not movies:
            return jsonify({'error': 'No movies found with specified genres'}), 404
        
        # Фильтрация по актерам
        if actors:
            filtered_movies = []
            for movie in movies:
                try:
                    crew_data = json.loads(movie['crew']) if movie['crew'] else {}
                    movie_actors = crew_data.get('Actors', '').split(', ') if 'Actors' in crew_data else []
                    if any(actor in movie_actors for actor in actors):
                        filtered_movies.append(movie)
                except json.JSONDecodeError:
                    continue
                    
            if not filtered_movies:
                return jsonify({'error': 'No movies found with specified actors'}), 404
            movies = filtered_movies
        
        # 3. Подготовка текстов для сравнения
        target_texts = [description] + similar_movies
        movie_overviews = [m['overview'] for m in movies]
        
        # 4. Получение векторных представлений
        target_embeddings = model.encode(target_texts)
        movie_embeddings = model.encode(movie_overviews)
        
        # 5. Взвешенное сравнение
        weights = [1.0] + [0.5] * len(similar_movies)
        weighted_similarities = []
        
        for i, embedding in enumerate(target_embeddings):
            sim = cosine_similarity([embedding], movie_embeddings)[0]
            weighted_sim = sim * weights[i]
            weighted_similarities.append(weighted_sim)
        
        # 6. Усреднение результатов
        avg_similarities = np.mean(weighted_similarities, axis=0)
        
        # 7. Бонус за совпадение актеров
        if actors:
            for i, movie in enumerate(movies):
                try:
                    crew_data = json.loads(movie['crew']) if movie['crew'] else {}
                    movie_actors = crew_data.get('Actors', '').split(', ') if 'Actors' in crew_data else []
                    actor_count = sum(1 for actor in actors if actor in movie_actors)
                    if actor_count > 0:
                        avg_similarities[i] += actor_count * 0.1
                except json.JSONDecodeError:
                    continue
        
        # 8. Формирование рекомендаций
        recommendations = []
        for i in np.argsort(avg_similarities)[-20:][::-1]:
            movie = movies[i]
            matched_actors = []
            if actors:
                try:
                    crew_data = json.loads(movie['crew']) if movie['crew'] else {}
                    movie_actors = crew_data.get('Actors', '').split(', ') if 'Actors' in crew_data else []
                    matched_actors = [actor for actor in actors if actor in movie_actors]
                except json.JSONDecodeError:
                    pass
            
            recommendations.append({
                'id': movie['id'],
                'title': movie['title'],
                'overview': movie['overview'],
                'genre': movie['genre'],
                'score': movie['score'],
                'similarity_score': float(avg_similarities[i]),
                'matched_actors': matched_actors
            })
        
        return jsonify(recommendations), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if 'conn' in locals():
            conn.close()

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    
    # Сначала проверяем наличие всех обязательных полей
    if not data or 'login' not in data or 'password' not in data:
        return jsonify({'error': 'Login, password and email are required'}), 400
    
    # Только после проверки получаем значения
    login = data['login']
    password = data['password']
    email = data['email']
    
    try:
        # Хешируем пароль
        hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')
        
        conn = get_db()
        conn.execute(
            "INSERT INTO users (login, password, email) VALUES (?, ?, ?)",
            (login, hashed_password, email)
        )
        conn.commit()
        return jsonify({'message': 'User created successfully'}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'User with this login already exists'}), 409
    except Exception as e:
        app.logger.error(f"User creation error: {str(e)}")
        return jsonify({'error': 'Registration failed'}), 500
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
            "SELECT user_id, login, email, password FROM users WHERE login = ?",
            (login,)
        )
        user = cursor.fetchone()
        
        if user:
            if check_password_hash(password, user['password']):
                return jsonify({
                    'message': 'Login successful',
                    'user_id': user['user_id'],
                    'login': user['login'],
                    'email': user['email']
                }), 200
            else:
                return jsonify({'error': 'Invalid login or password'}), 401
        else:
            return jsonify({'error': 'Invalid login or password'}), 401
            
    except Exception as e:
    
        app.logger.error(f"Login error: {str(e)}")
        return jsonify({'error': 'Authentication failed'}), 500
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


@app.route('/api/feedback', methods=['POST'])
def add_feedback():
    """Endpoint для добавления отзыва с отправкой в Telegram"""
    data = request.get_json()
    
    # Валидация данных
    if not data or 'user_id' not in data or 'grade' not in data:
        return jsonify({'error': 'user_id and grade are required fields'}), 400
    
    try:
        grade = int(data['grade'])
        if not (1 <= grade <= 5):
            return jsonify({'error': 'grade must be between 1 and 5'}), 400
    except (ValueError, TypeError):
        return jsonify({'error': 'grade must be an integer value'}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Проверка существования пользователя
        cursor.execute("SELECT 1 FROM users WHERE user_id = ?", (data['user_id'],))
        if not cursor.fetchone():
            return jsonify({'error': 'specified user not found'}), 404
        
        # Вставка отзыва с возвратом всех полей
        cursor.execute("""
            INSERT INTO feedback (user_id, grade, text)
            VALUES (?, ?, ?)
            ON CONFLICT(user_id) 
            DO UPDATE SET 
                grade = excluded.grade,
                text = excluded.text
            RETURNING id, user_id, grade, text
        """, (data['user_id'], grade, data.get('text', '')))
        
        # Получаем полные данные добавленного отзыва
        feedback = cursor.fetchone()
        conn.commit()
        
        # Преобразуем в словарь
        feedback_dict = dict(feedback)
        
        # Отправка уведомления в Telegram
        if app.config['SEND_TELEGRAM_NOTIFICATIONS']:
            try:
                Thread(target=send_telegram_notification, args=(feedback_dict,)).start()
            except Exception as e:
                app.logger.error(f"error: {e}")
        
        return jsonify({
            'message': 'Отзыв добавлен',
            'feedback_id': feedback_dict['id']
        }), 201
        
    except sqlite3.Error as e:
        return jsonify({'error': f'database error: {str(e)}'}), 500
    finally:
        if 'conn' in locals():
            conn.close()


if __name__ == '__main__':
    app.run(debug=True)