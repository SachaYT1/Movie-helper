import sqlite3
import csv
from pathlib import Path

def init_db():
    db_path = Path(__file__).parent / "movies.db"
    conn = sqlite3.connect(db_path)
    
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
    
    # Проверяем, есть ли уже данные в таблице movies
    if not conn.execute("SELECT COUNT(*) FROM movies").fetchone()[0]:
        csv_path = Path(__file__).parent.parent / "data" / "imdb_movies.csv"
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                conn.execute(
                    """INSERT INTO movies 
                    (title, date_x, score, genre, overview, crew, orig_title, 
                     status, orig_lang, budget_x, revenue, country) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        row['names'],
                        row['date_x'],
                        float(row['score']) if row['score'] else None,
                        row['genre'],
                        row['overview'],
                        row['crew'],
                        row['orig_title'],
                        row['status'],
                        row['orig_lang'],
                        float(row['budget_x']) if row['budget_x'] else None,
                        float(row['revenue']) if row['revenue'] else None,
                        row['country']
                    )
                )
    
    conn.commit()
    conn.close()


def add_email_column():
    db_path = Path(__file__).parent / "movies.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Проверяем, существует ли уже колонка email
    cursor.execute("PRAGMA table_info(users)")
    columns = cursor.fetchall()
    column_names = [column[1] for column in columns]
    
    if 'email' not in column_names:
        # Добавляем колонку email, если её ещё нет
        cursor.execute("ALTER TABLE users ADD COLUMN email TEXT UNIQUE")
        print("Колонка email успешно добавлена")
    else:
        print("Колонка email уже существует")
    
    conn.commit()
    conn.close()


def drop_users_table():
    db_path = Path(__file__).parent / "movies.db"
    conn = sqlite3.connect(db_path)
    conn.execute("DROP TABLE IF EXISTS users")
    conn.commit()
    conn.close()


if __name__ == "__main__":
   init_db()
