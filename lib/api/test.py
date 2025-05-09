import unittest
import sqlite3
from pathlib import Path
from app import app

class TestUserAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Настраиваем тестовое приложение
        app.config['TESTING'] = True
        app.config['DATABASE'] = Path(__file__).parent / "test_movies.db"
        cls.client = app.test_client()

        # Создаем тестовую БД
        conn = sqlite3.connect(app.config['DATABASE'])
        conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                login TEXT UNIQUE,
                password TEXT
            )
        """)
        conn.commit()
        conn.close()

    @classmethod
    def tearDownClass(cls):
        # Удаляем тестовую БД после всех тестов
        if Path(app.config['DATABASE']).exists():
            Path(app.config['DATABASE']).unlink()

    def setUp(self):
        # Очищаем таблицу перед каждым тестом
        conn = sqlite3.connect(app.config['DATABASE'])
        conn.execute("DELETE FROM users")
        conn.commit()
        conn.close()

    def test_create_user_success(self):
        """Тест успешного создания пользователя"""
        test_data = {'login': 'unique_user_1', 'password': 'testpass'}
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
        test_data = {'login': 'duplicate_test', 'password': 'mypassword'}
        
        # Сначала создаем пользователя
        conn = sqlite3.connect(app.config['DATABASE'])
        conn.execute("INSERT INTO users (login, password) VALUES (?, ?)", 
                    (test_data['login'], test_data['password']))
        conn.commit()
        conn.close()
        
        # Пытаемся создать такого же пользователя
        response = self.client.post('/api/users', json=test_data)
        self.assertEqual(response.status_code, 409)
        self.assertIn('error', response.get_json())

class TestSimilarMoviesAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Настраиваем тестовое приложение
        app.config['TESTING'] = True
        app.config['DATABASE'] = Path(__file__).parent / "test_movies.db"
        cls.client = app.test_client()

        # Создаем тестовую БД со всеми таблицами
        conn = sqlite3.connect(app.config['DATABASE'])
        conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                login TEXT UNIQUE,
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
        conn.commit()
        conn.close()

        # Создаем тестового пользователя
        with sqlite3.connect(app.config['DATABASE']) as conn:
            conn.execute(
                "INSERT INTO users (login, password) VALUES (?, ?)",
                ('test_user', 'testpass')
            )
            conn.commit()

    @classmethod
    def tearDownClass(cls):
        # Удаляем тестовую БД после всех тестов
        if Path(app.config['DATABASE']).exists():
            Path(app.config['DATABASE']).unlink()

    def setUp(self):
        # Очищаем таблицу похожих фильмов перед каждым тестом
        with sqlite3.connect(app.config['DATABASE']) as conn:
            conn.execute("DELETE FROM similar_movies")
            conn.commit()

    def test_add_similar_movie_success(self):
        """Тест успешного добавления похожего фильма"""
        test_movie = {
            "title": "Inception",
            "date_x": "2010-07-16",
            "score": 8.8,
            "genre": "Sci-Fi, Action",
            "overview": "A thief who steals corporate secrets..."
        }
        
        response = self.client.post(
            '/api/users/1/similar_movies',
            json=test_movie
        )
        
        self.assertEqual(response.status_code, 201)
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
        
        response = self.client.post(
            '/api/users/1/similar_movies',
            json=test_movie
        )
        
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
        
        with sqlite3.connect(app.config['DATABASE']) as conn:
            for movie in test_movies:
                conn.execute(
                    """INSERT INTO similar_movies 
                    (user_id, title, date_x, score, genre, overview) 
                    VALUES (?, ?, ?, ?, ?, ?)""",
                    (1, movie['title'], movie['date_x'], 
                     movie['score'], movie['genre'], movie['overview'])
                )
            conn.commit()
        
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
        with sqlite3.connect(app.config['DATABASE']) as conn:
            cursor = conn.execute(
                """INSERT INTO similar_movies 
                (user_id, title, date_x, score, genre, overview) 
                VALUES (?, ?, ?, ?, ?, ?)""",
                (1, "The Matrix", "1999-03-31", 8.7, 
                 "Sci-Fi, Action", "A computer hacker learns...")
            )
            movie_id = cursor.lastrowid
            conn.commit()
        
        # Удаляем фильм
        response = self.client.delete(
            f'/api/users/1/similar_movies/{movie_id}'
        )
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.get_json(),
            {'message': 'Movie deleted successfully'}
        )
        
        # Проверяем, что фильма больше нет
        with sqlite3.connect(app.config['DATABASE']) as conn:
            cursor = conn.execute(
                "SELECT 1 FROM similar_movies WHERE id = ?",
                (movie_id,)
            )
            self.assertIsNone(cursor.fetchone())

    def test_delete_nonexistent_movie(self):
        """Тест удаления несуществующего фильма"""
        response = self.client.delete(
            '/api/users/1/similar_movies/999'
        )
        
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
        with sqlite3.connect(app.config['DATABASE']) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM similar_movies")
            count_before = cursor.fetchone()[0]
        
        response = self.client.post(
            '/api/users/999/similar_movies',
            json=test_movie
        )
        
        self.assertEqual(response.status_code, 404)
        self.assertIn('error', response.get_json())
        
        # Проверяем, что количество фильмов не изменилось
        with sqlite3.connect(app.config['DATABASE']) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM similar_movies")
            count_after = cursor.fetchone()[0]
        
        self.assertEqual(count_before, count_after)

if __name__ == '__main__':
    unittest.main()