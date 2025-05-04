import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import sqlite3
from pathlib import Path
import re

def get_db_connection():
    """Подключение к базе данных."""
    db_path = Path(__file__).parent.parent.parent / "database" / "movies.db"
    return sqlite3.connect(db_path)

def preprocess_text(text):
    """Очистка текста (можно добавить стемминг/лемматизацию)."""
    return text.lower().replace(",", "").replace(".", "").strip()

def recommend_movies(user_text, omdb_movies, top_n=10):
    """
    Рекомендует фильмы на основе схожести описаний и актеров.
    
    Args:
        user_text (str): Текст пользователя (например: "Хочу фильм с Томом Харди про войну").
        omdb_movies (list[dict]): Список фильмов из OMDb API.
        top_n (int): Сколько фильмов вернуть.
    
    Returns:
        list[dict]: Топ-N фильмов, отсортированных по релевантности.
    """
    # 1. Извлекаем понравившиеся описания из similar_movies
    conn = get_db_connection()
    liked_overviews = conn.execute("SELECT overview FROM similar_movies").fetchall()
    conn.close()
    
    # 2. Объединяем их в один эталонный текст
    reference_text = " ".join([overview[0] for overview in liked_overviews if overview[0]])
    
    # 3. Подготавливаем тексты для сравнения (описания OMDb + запрос пользователя)
    omdb_texts = [movie.get("Plot", "") for movie in omdb_movies]
    all_texts = [user_text, reference_text] + omdb_texts
    
    # 4. Создаем TF-IDF векторы
    vectorizer = TfidfVectorizer(stop_words="english")
    tfidf_matrix = vectorizer.fit_transform(all_texts)
    
    # 5. Сравниваем запрос пользователя с описаниями OMDb
    user_vector = tfidf_matrix[0]
    omdb_vectors = tfidf_matrix[2:]  # Пропускаем reference_text
    
    similarities = cosine_similarity(user_vector, omdb_vectors).flatten()
    
    # 6. Проверяем наличие актеров из запроса в фильмах OMDb
    actors_in_query = extract_actors(user_text)  # Функция для извлечения актеров (пример ниже)
    
    for i, movie in enumerate(omdb_movies):
        movie["similarity"] = similarities[i]
        movie["actor_match"] = check_actor_match(movie.get("Actors", ""), actors_in_query)
    
    # 7. Сортируем по схожести и совпадению актеров
    sorted_movies = sorted(
        omdb_movies,
        key=lambda x: (x["similarity"], x["actor_match"]),
        reverse=True
    )
    
    return sorted_movies[:top_n]

import re

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

def check_actor_match(movie_actors, query_actors):
    """Проверяет, есть ли актеры из запроса в фильме."""
    if not query_actors:
        return 0
    movie_actors_lower = movie_actors.lower()
    return sum(actor.lower() in movie_actors_lower for actor in query_actors)


# user_text = "I want to see a film Bulgarian"
# omdb_movies = [{"Title":"Pork with Pickled Cabbage","Year":"2015","Rated":"N/A","Released":"N/A","Runtime":"17 min","Genre":"Documentary, Short","Director":"Anna Velikova","Writer":"N/A","Actors":"N/A","Plot":"A short ethnographic documentary based on a disappearing Bulgarian tradition.","Language":"Bulgarian","Country":"Bulgaria, UK","Awards":"N/A","Poster":"N/A","Ratings":[],"Metascore":"N/A","imdbRating":"N/A","imdbVotes":"N/A","imdbID":"tt4969014","Type":"movie","DVD":"N/A","BoxOffice":"N/A","Production":"N/A","Website":"N/A","Response":"True"}, {"Title":"Spider Man: Lost Cause","Year":"2014","Rated":"N/A","Released":"26 Sep 2014","Runtime":"140 min","Genre":"Action, Adventure, Comedy","Director":"Joey Lever","Writer":"Steve Ditko, Stan Lee, Joey Lever","Actors":"Joey Lever, Craig Ellis, Teravis Ward","Plot":"Peter Parker a lone child discovers that his parents were in a horrifying plot to make mankind change. getting bitten by his fathers invention he develops super powers to tries to find answers to his whole life, try and juggle a relationship with his girlfriend and try and find the murderer of his uncle. (Fan Made Film)","Language":"English","Country":"United Kingdom","Awards":"N/A","Poster":"https://m.media-amazon.com/images/M/MV5BZGQzZjY1MGItYmVjZS00ZmFkLWIwYzYtZDg4ODBjYzE5NzU2XkEyXkFqcGc@._V1_SX300.jpg","Ratings":[{"Source":"Internet Movie Database","Value":"4.1/10"}],"Metascore":"N/A","imdbRating":"4.1","imdbVotes":"477","imdbID":"tt2803854","Type":"movie","DVD":"N/A","BoxOffice":"N/A","Production":"N/A","Website":"N/A","Response":"True"}, {"Title":"Rota Inter TV","Year":"2015–","Rated":"N/A","Released":"28 Mar 2015","Runtime":"N/A","Genre":"Reality-TV","Director":"N/A","Writer":"N/A","Actors":"Leo Souza","Plot":"N/A","Language":"Portuguese","Country":"Brazil","Awards":"N/A","Poster":"https://m.media-amazon.com/images/M/MV5BMDI4ZmUyNTAtOGI0MS00MWEyLTkyMzktNjBmMmQ0YTI3NzJmXkEyXkFqcGdeQXVyMTUyMDYyMjU3._V1_SX300.jpg","Ratings":[],"Metascore":"N/A","imdbRating":"N/A","imdbVotes":"N/A","imdbID":"tt25145550","Type":"series","totalSeasons":"N/A","Response":"True"}]  # 100 фильмов из OMDb API
# print(recommend_movies(user_text, omdb_movies, top_n=5))