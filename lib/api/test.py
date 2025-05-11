import unittest
import sqlite3
import json
from pathlib import Path
from app import app

class BaseTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Настройка тестового приложения
        app.config['TESTING'] = True
        app.config['DATABASE'] = Path(__file__).parent / "test_movies.db"
        
        cls.client = app.test_client()
        
        # Инициализация тестовой БД
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    login TEXT UNIQUE,
                    email TEXT UNIQUE,
                    password TEXT
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS similar_movies (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    title TEXT NOT NULL,
                    date_x TEXT,
                    score REAL,
                    genre TEXT,
                    overview TEXT,
                    crew TEXT,
                    orig_title TEXT,
                    status TEXT,
                    orig_lang TEXT,
                    budget_x REAL,
                    revenue REAL,
                    country TEXT
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS movies (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    date_x TEXT,
                    score REAL,
                    genre TEXT,
                    overview TEXT,
                    crew TEXT,
                    orig_title TEXT,
                    status TEXT,
                    orig_lang TEXT,
                    budget_x REAL,
                    revenue REAL,
                    country TEXT
                )
            """)
            conn.commit()
        finally:
            if conn:
                conn.close()

    @classmethod
    def tearDownClass(cls):
        # Удаление тестовой БД
        if Path(app.config['DATABASE']).exists():
            Path(app.config['DATABASE']).unlink()

class TestUserAPI(BaseTestCase):
    def setUp(self):
        # Очистка таблицы users перед каждым тестом
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute("DELETE FROM users")
            conn.commit()
        finally:
            if conn:
                conn.close()

    def test_create_user_success(self):
        """Тест успешного создания пользователя"""
        test_data = {'login': 'unique_user_1', 'password': 'testpass', 'email': 'user1@gmail.ru'}
        response = self.client.post('/api/users', json=test_data)
        
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.get_json(), {'message': 'User created successfully'})

    def test_create_user_missing_fields(self):
        """Тест с отсутствующими обязательными полями"""
        # Нет пароля
        response = self.client.post('/api/users', json={'login': 'testuser1'})
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.get_json())
        
        # Нет логина
        response = self.client.post('/api/users', json={'password': 'mypassword'})
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.get_json())

    def test_create_user_duplicate(self):
        """Тест создания дубликата пользователя"""
        test_data = {'login': 'duplicate_test', 'password': 'mypassword', 'email': 'user1@gmail.ru'}
        
        # Сначала создаем пользователя
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute("INSERT INTO users (login, password, email) VALUES (?, ?, ?)", 
                        (test_data['login'], test_data['password'], test_data['email']))
            conn.commit()
        finally:
            if conn:
                conn.close()
        
        # Пытаемся создать такого же пользователя
        response = self.client.post('/api/users', json=test_data)
        self.assertEqual(response.status_code, 409)
        self.assertIn('error', response.get_json())

class TestSimilarMoviesAPI(BaseTestCase):
    def setUp(self):
        # Очистка таблиц и создание тестового пользователя
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute("DELETE FROM similar_movies")
            conn.execute("DELETE FROM users")
            # Явно создаем пользователя с ID=1
            conn.execute(
                "INSERT INTO users (user_id, login, password, email) VALUES (?, ?, ?, ?)",
                (1, 'test_user', 'testpass', 'test_user@gmail.com')
            )
            conn.commit()
        finally:
            if conn:
                conn.close()

    def test_add_similar_movie_success(self):
        """Тест успешного добавления похожего фильма"""
        test_movie = {
            "title": "Inception",
            "date_x": "2010-07-16",
            "score": 8.8,
            "genre": "Sci-Fi, Action",
            "overview": "A thief who steals corporate secrets..."
        }
        
        # Проверяем существование пользователя перед тестом
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            cursor = conn.cursor()
            cursor.execute("SELECT 1 FROM users WHERE user_id = 1")
            result = cursor.fetchone()
            self.assertIsNotNone(result, "Test user should exist")
        finally:
            if conn:
                conn.close()
        
        response = self.client.post(
            '/api/users/1/similar_movies',
            json=test_movie,
            headers={'Content-Type': 'application/json'}
        )
        
        self.assertEqual(
            response.status_code, 
            201,
            f"Expected 201, got {response.status_code}. Response: {response.get_json()}"
        )
        self.assertEqual(
            response.get_json(),
            {'message': 'Similar movie added successfully'}
        )

    def test_add_similar_movie_missing_fields(self):
        """Тест с отсутствующими обязательными полями"""
        # Не хватает поля overview
        test_movie = {
            "title": "Inception",
            "date_x": "2010-07-16",
            "score": 8.8,
            "genre": "Sci-Fi, Action"
        }
        
        response = self.client.post('/api/users/1/similar_movies', json=test_movie)
        
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.get_json())

    def test_get_similar_movies(self):
        """Тест получения списка похожих фильмов"""
        # Сначала добавляем тестовые фильмы
        test_movies = [
            {
                "title": "Inception",
                "date_x": "2010-07-16",
                "score": 8.8,
                "genre": "Sci-Fi, Action",
                "overview": "A thief who steals corporate secrets..."
            },
            {
                "title": "Interstellar",
                "date_x": "2014-11-07",
                "score": 8.6,
                "genre": "Sci-Fi, Adventure",
                "overview": "A team of explorers travel through a wormhole..."
            }
        ]
        
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            for movie in test_movies:
                conn.execute(
                    """INSERT INTO similar_movies 
                    (user_id, title, date_x, score, genre, overview) 
                    VALUES (?, ?, ?, ?, ?, ?)""",
                    (1, movie['title'], movie['date_x'], 
                     movie['score'], movie['genre'], movie['overview'])
                )
            conn.commit()
        finally:
            if conn:
                conn.close()
        
        # Получаем список фильмов
        response = self.client.get('/api/users/1/similar_movies')
        
        self.assertEqual(response.status_code, 200)
        movies = response.get_json()
        self.assertEqual(len(movies), 2)
        self.assertEqual(movies[0]['title'], "Inception")
        self.assertEqual(movies[1]['title'], "Interstellar")

    def test_delete_similar_movie(self):
        """Тест удаления похожего фильма"""
        # Сначала добавляем тестовый фильм
        movie_id = None
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            cursor = conn.execute(
                """INSERT INTO similar_movies 
                (user_id, title, date_x, score, genre, overview) 
                VALUES (?, ?, ?, ?, ?, ?)""",
                (1, "The Matrix", "1999-03-31", 8.7, 
                 "Sci-Fi, Action", "A computer hacker learns...")
            )
            movie_id = cursor.lastrowid
            conn.commit()
        finally:
            if conn:
                conn.close()
        
        # Удаляем фильм
        response = self.client.delete(f'/api/users/1/similar_movies/{movie_id}')
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.get_json(),
            {'message': 'Movie deleted successfully'}
        )
        
        # Проверяем, что фильма больше нет
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            cursor = conn.execute(
                "SELECT 1 FROM similar_movies WHERE id = ?",
                (movie_id,)
            )
            self.assertIsNone(cursor.fetchone())
        finally:
            if conn:
                conn.close()

    def test_delete_nonexistent_movie(self):
        """Тест удаления несуществующего фильма"""
        response = self.client.delete('/api/users/1/similar_movies/999')
        
        self.assertEqual(response.status_code, 404)
        self.assertIn('error', response.get_json())

    def test_add_movie_to_nonexistent_user(self):
        """Тест добавления фильма несуществующему пользователю"""
        test_movie = {
            "title": "Inception",
            "date_x": "2010-07-16",
            "score": 8.8,
            "genre": "Sci-Fi, Action",
            "overview": "A thief who steals corporate secrets..."
        }
        
        # Проверяем количество фильмов до запроса
        count_before = 0
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM similar_movies")
            count_before = cursor.fetchone()[0]
        finally:
            if conn:
                conn.close()
        
        response = self.client.post('/api/users/999/similar_movies', json=test_movie)
        
        self.assertEqual(response.status_code, 404)
        self.assertIn('error', response.get_json())
        
        # Проверяем, что количество фильмов не изменилось
        count_after = 0
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM similar_movies")
            count_after = cursor.fetchone()[0]
        finally:
            if conn:
                conn.close()
        
        self.assertEqual(count_before, count_after)

class TestMLRecommendations(BaseTestCase):
    def setUp(self):
        # Очистка таблиц и добавление тестовых данных
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute("DELETE FROM movies")
            conn.execute("DELETE FROM similar_movies")
            conn.execute("DELETE FROM users")
            
            # Добавляем тестового пользователя
            conn.execute(
                "INSERT INTO users (login, password) VALUES (?, ?)",
                ("test_user", "testpass")
            )
            
            # Добавляем тестовые фильмы с актерами в crew поле (JSON)
            conn.executemany(
                """INSERT INTO movies (title, genre, overview, score, crew) 
                VALUES (?, ?, ?, ?, ?)""",
                [
                    ("The Matrix", "Sci-Fi, Action", 
                     "A computer hacker learns about reality", 8.7,
                     json.dumps({"Actors": "Keanu Reeves, Laurence Fishburne, Carrie-Anne Moss"})),
                    ("Inception", "Sci-Fi", 
                     "A thief steals secrets through dreams", 8.8,
                     json.dumps({"Actors": "Leonardo DiCaprio, Joseph Gordon-Levitt, Ellen Page"})),
                    ("Interstellar", "Sci-Fi", 
                     "Space travel to save humanity", 8.6,
                     json.dumps({"Actors": "Matthew McConaughey, Anne Hathaway, Jessica Chastain"}))
                ]
            )
            
            # Добавляем похожие фильмы
            conn.execute(
                """INSERT INTO similar_movies 
                (user_id, title, overview) VALUES 
                (1, 'Blade Runner', 'A story about replicants')"""
            )
            conn.commit()
        finally:
            if conn:
                conn.close()

    def test_ml_recommendations_with_actors(self):
        """Test recommendation system with actor matching from crew field"""
        # Добавляем фильм с конкретными актерами в тестовую базу
        conn = None
        try:
            conn = sqlite3.connect(app.config['DATABASE'])
            conn.execute(
                """INSERT INTO movies (title, genre, overview, score, crew) 
                VALUES (?, ?, ?, ?, ?)""",
                ("Gravity", "Sci-Fi, Drama", 
                 "A story about space survival",
                 7.7,
                 json.dumps({"Actors": "Sandra Bullock, George Clooney"}))
            )
            conn.commit()
        finally:
            if conn:
                conn.close()

        test_data = {
            "user_id": 1,
            "description": "A space movie with Sandra Bullock",
            "genres": "Sci-Fi"
        }
        
        response = self.client.post('/api/ml/recommendations', json=test_data)
        
        self.assertEqual(response.status_code, 200, "Should return status code 200")
        data = response.get_json()
        self.assertIsInstance(data, list, "Response should be a list")
        
        if len(data) > 0:
            gravity_found = any(movie['title'] == 'Gravity' for movie in data)
            self.assertTrue(gravity_found, "Movie with specified actors should be in results")
            
            if gravity_found:
                gravity_movie = next(movie for movie in data if movie['title'] == 'Gravity')
                self.assertIn('matched_actors', gravity_movie, "Should have matched_actors field")
                self.assertIsInstance(gravity_movie['matched_actors'], list, 
                                    "matched_actors should be a list")
                self.assertGreater(len(gravity_movie['matched_actors']), 0,
                                "Should have at least one matched actor")
                
                self.assertIn('Sandra Bullock', gravity_movie['matched_actors'],
                            "Sandra Bullock should be in matched actors")

    def test_actor_extraction_from_crew(self):
        """Test that actors are correctly extracted from crew JSON"""
        test_data = {
            "user_id": 1,
            "description": "A movie with Keanu Reeves",
            "genres": "Sci-Fi"
        }
        
        response = self.client.post('/api/ml/recommendations', json=test_data)
        
        self.assertEqual(response.status_code, 200, "Should return status code 200")
        data = response.get_json()
        
        if len(data) > 0:
            matrix_found = any(movie['title'] == 'The Matrix' for movie in data)
            self.assertTrue(matrix_found, "The Matrix should be in results")
            
            if matrix_found:
                matrix_movie = next(movie for movie in data if movie['title'] == 'The Matrix')
                self.assertIn('matched_actors', matrix_movie)
                self.assertIn('Keanu Reeves', matrix_movie['matched_actors'],
                            "Keanu Reeves should be matched from crew data")

    def test_multiple_actor_matching(self):
        """Test matching with multiple actors in request"""
        test_data = {
            "user_id": 1,
            "description": "A movie with Leonardo DiCaprio and Ellen Page",
            "genres": "Sci-Fi"
        }
        
        response = self.client.post('/api/ml/recommendations', json=test_data)
        
        self.assertEqual(response.status_code, 200, "Should return status code 200")
        data = response.get_json()
        
        if len(data) > 0:
            inception_found = any(movie['title'] == 'Inception' for movie in data)
            self.assertTrue(inception_found, "Inception should be in results")
            
            if inception_found:
                inception_movie = next(movie for movie in data if movie['title'] == 'Inception')
                self.assertIn('matched_actors', inception_movie)
                matched = set(inception_movie['matched_actors'])
                self.assertTrue({'Leonardo DiCaprio', 'Ellen Page'}.issubset(matched),
                              "Both actors should be matched")

class FeedbackAPITestCase(unittest.TestCase):
    def setUp(self):
        """Initialize test DB and client"""
        self.db_path = Path(__file__).parent / "test_movies.db"
        app.config['DATABASE'] = self.db_path
        app.config['TESTING'] = True
        app.config['SEND_TELEGRAM_NOTIFICATIONS'] = False
        self.client = app.test_client()
        
        conn = sqlite3.connect(self.db_path)
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                login TEXT UNIQUE,
                password TEXT
            );
            CREATE TABLE IF NOT EXISTS feedback (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER UNIQUE NOT NULL,
                grade INTEGER,
                text TEXT
            );
        """)
        conn.commit()
        conn.close()
        
        with app.app_context():
            conn = sqlite3.connect(self.db_path)
            conn.execute("INSERT INTO users (user_id, login) VALUES (1, 'testuser')")
            conn.commit()
            conn.close()

    def tearDown(self):
        """Clean up test DB"""
        if self.db_path.exists():
            self.db_path.unlink()

    def test_submit_valid_feedback(self):
        """Test successful feedback submission"""
        test_data = {
            "user_id": 1,
            "grade": 5,
            "text": "Excellent recommendations!"
        }
        
        response = self.client.post(
            '/api/feedback',
            data=json.dumps(test_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 201)
        self.assertIn('feedback_id', json.loads(response.data))
        
        with app.app_context():
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM feedback WHERE user_id = 1")
            record = cursor.fetchone()
            conn.close()
            
            self.assertIsNotNone(record)
            self.assertEqual(record[2], 5) 
            self.assertEqual(record[3], "Excellent recommendations!")

    def test_feedback_missing_required_fields(self):
        """Test missing user_id or grade"""
        test_cases = [
            ({"grade": 5}, "user_id"),
            ({"user_id": 1}, "grade"),
            ({}, "user_id and grade")
        ]
        
        for data, missing_field in test_cases:
            response = self.client.post(
                '/api/feedback',
                data=json.dumps(data),
                content_type='application/json'
            )
            
            self.assertEqual(response.status_code, 400)
            self.assertIn(missing_field, json.loads(response.data)['error'].lower())

    def test_invalid_grade_range(self):
        """Test grade outside 1-5 range"""
        test_cases = [0, 6, -1]
        
        for grade in test_cases:
            response = self.client.post(
                '/api/feedback',
                data=json.dumps({"user_id": 1, "grade": grade}),
                content_type='application/json'
            )
            
            self.assertEqual(response.status_code, 400)
            self.assertIn("between 1 and 5", json.loads(response.data)['error'])

    def test_nonexistent_user(self):
        """Test feedback for non-existent user"""
        response = self.client.post(
            '/api/feedback',
            data=json.dumps({"user_id": 999, "grade": 3}),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 404)
        self.assertIn("not found", json.loads(response.data)['error'].lower())

    def test_feedback_update_existing(self):
        """Test updating existing feedback"""
        
        self.client.post(
            '/api/feedback',
            data=json.dumps({"user_id": 1, "grade": 3}),
            content_type='application/json'
        )
        
    
        update_data = {
            "user_id": 1,
            "grade": 5,
            "text": "Changed my mind, these are great!"
        }
        
        response = self.client.post(
            '/api/feedback',
            data=json.dumps(update_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 201)
        
        with app.app_context():
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT grade, text FROM feedback WHERE user_id = 1")
            grade, text = cursor.fetchone()
            conn.close()
            
            self.assertEqual(grade, 5)
            self.assertEqual(text, "Changed my mind, these are great!")

if __name__ == '__main__':
    unittest.main()