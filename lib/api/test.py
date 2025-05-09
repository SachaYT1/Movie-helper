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

if __name__ == '__main__':
    unittest.main()