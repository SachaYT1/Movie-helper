import sqlite3
import csv
from pathlib import Path

def init_db():
    db_path = Path(__file__).parent / "movies.db"
    conn = sqlite3.connect(db_path)
    
    conn.execute("""
    CREATE TABLE IF NOT EXISTS similar_movies (
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
    
    conn.execute("""
    CREATE TABLE IF NOT EXISTS movie_names (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        search_title TEXT NOT NULL
    )
    """)

    conn.execute("CREATE INDEX IF NOT EXISTS idx_search_title ON movie_names(search_title)")
    
    if not conn.execute("SELECT COUNT(*) FROM movie_names").fetchone()[0]:
        csv_path = Path(__file__).parent.parent / "data" / "imdb_movies.csv"
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                search_title = row['names'].lower().replace(':', '').replace('-', '').strip()
                conn.execute(
                    "INSERT INTO movie_names VALUES (NULL, ?)",
                    (
                        search_title,
                    )
                )
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()