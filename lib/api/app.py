from flask import Flask, request, jsonify
import sqlite3
import re
from pathlib import Path
from sentence_transformers import SentenceTransformer
import numpy as np
import json
from sklearn.metrics.pairwise import cosine_similarity

model = SentenceTransformer('all-MiniLM-L6-v2')

app = Flask(__name__)
app.config['DATABASE'] = Path(__file__).parent.parent.parent / "backend" / "database" / "movies.db"


print(app.config['DATABASE'])
def get_db():
    print(app.config['DATABASE'])
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn

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