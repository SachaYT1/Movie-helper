import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:movie_helper/models/movie.dart';

class MovieService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://www.omdbapi.com';
  final String _apiKey =
      '7daa216b'; // Замените на свой API ключ от OMDb

  // Получение списка жанров
  // OMDb не имеет отдельного API для жанров, поэтому используем предопределенный список
  Future<Map<int, String>> getGenres() async {
    // Предопределенный список жанров
    final Map<int, String> genres = {
      1: 'Боевик',
      2: 'Приключения',
      3: 'Анимация',
      4: 'Комедия',
      5: 'Криминал',
      6: 'Документальный',
      7: 'Драма',
      8: 'Семейный',
      9: 'Фэнтези',
      10: 'История',
      11: 'Ужасы',
      12: 'Музыка',
      13: 'Детектив',
      14: 'Мелодрама',
      15: 'Научная фантастика',
      16: 'Триллер',
      17: 'Военный',
      18: 'Вестерн',
    };

    return genres;
  }

  // Поиск фильмов по запросу
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'apikey': _apiKey,
          's': query,
          'type': 'movie',
          'page': 1,
        },
      );

      final List<Movie> movies = [];

      if (response.data['Response'] == 'True' &&
          response.data['Search'] != null) {
        for (var item in response.data['Search']) {
          // Получаем детальную информацию о фильме
          final detailsResponse = await _dio.get(
            _baseUrl,
            queryParameters: {
              'apikey': _apiKey,
              'i': item['imdbID'],
              'plot': 'full',
            },
          );

          if (detailsResponse.data['Response'] == 'True') {
            movies.add(_convertToMovie(detailsResponse.data));
          }
        }
      }

      return movies;
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }

  // Получение похожих фильмов
  // OMDb не имеет API для похожих фильмов, поэтому ищем по жанру и году
  Future<List<Movie>> getSimilarMovies(String imdbId) async {
    try {
      // Получаем информацию о фильме
      final movieResponse = await _dio.get(
        _baseUrl,
        queryParameters: {
          'apikey': _apiKey,
          'i': imdbId,
          'plot': 'full',
        },
      );

      if (movieResponse.data['Response'] != 'True') {
        return [];
      }

      // Извлекаем жанр и год
      final String genre = movieResponse.data['Genre']?.split(',')[0] ?? '';
      final String year = movieResponse.data['Year']?.split('–')[0] ?? '';

      // Ищем фильмы с таким же жанром
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'apikey': _apiKey,
          's': genre,
          'type': 'movie',
          'y': year,
          'page': 1,
        },
      );

      final List<Movie> movies = [];

      if (response.data['Response'] == 'True' &&
          response.data['Search'] != null) {
        for (var item in response.data['Search']) {
          // Пропускаем тот же самый фильм
          if (item['imdbID'] == imdbId) continue;

          // Получаем детальную информацию о фильме
          final detailsResponse = await _dio.get(
            _baseUrl,
            queryParameters: {
              'apikey': _apiKey,
              'i': item['imdbID'],
              'plot': 'full',
            },
          );

          if (detailsResponse.data['Response'] == 'True') {
            movies.add(_convertToMovie(detailsResponse.data));
          }

          // Ограничиваем количество результатов
          if (movies.length >= 10) break;
        }
      }

      return movies;
    } catch (e) {
      print('Error getting similar movies: $e');
      return [];
    }
  }

  // Получение фильмов по жанру
  Future<List<Movie>> getMoviesByGenre(String genre) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'apikey': _apiKey,
          's': genre,
          'type': 'movie',
          'page': 1,
        },
      );

      final List<Movie> movies = [];

      if (response.data['Response'] == 'True' &&
          response.data['Search'] != null) {
        for (var item in response.data['Search']) {
          // Получаем детальную информацию о фильме
          final detailsResponse = await _dio.get(
            _baseUrl,
            queryParameters: {
              'apikey': _apiKey,
              'i': item['imdbID'],
              'plot': 'full',
            },
          );

          if (detailsResponse.data['Response'] == 'True') {
            movies.add(_convertToMovie(detailsResponse.data));
          }

          // Ограничиваем количество результатов
          if (movies.length >= 10) break;
        }
      }

      return movies;
    } catch (e) {
      print('Error getting movies by genre: $e');
      return [];
    }
  }

  // Получение рекомендаций на основе нескольких критериев
  Future<List<Movie>> getRecommendations({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  }) async {
    List<Movie> recommendations = [];

    // Если указаны похожие фильмы
    if (similarMovieIds != null && similarMovieIds.isNotEmpty) {
      for (var movieId in similarMovieIds) {
        final similarMovies = await getSimilarMovies(movieId);
        recommendations.addAll(similarMovies);
      }
    }

    // Если указаны жанры
    if (genres != null && genres.isNotEmpty) {
      for (var genre in genres) {
        final genreMovies = await getMoviesByGenre(genre);
        recommendations.addAll(genreMovies);
      }
    }

    // Если указан поисковый запрос
    if (query != null && query.isNotEmpty) {
      final searchResults = await searchMovies(query);
      recommendations.addAll(searchResults);
    }

    // Удаляем дубликаты по ID
    final Map<String, Movie> uniqueMovies = {};
    for (var movie in recommendations) {
      uniqueMovies[movie.imdbId] = movie;
    }

    return uniqueMovies.values.toList();
  }

  // Вспомогательный метод для преобразования данных OMDb в нашу модель Movie
  Movie _convertToMovie(Map<String, dynamic> data) {
    // Преобразуем строку рейтинга в число
    double rating = 0.0;
    if (data['imdbRating'] != null && data['imdbRating'] != 'N/A') {
      rating = double.tryParse(data['imdbRating']) ?? 0.0;
    }

    // Преобразуем строку жанров в список
    List<String> genres = [];
    if (data['Genre'] != null && data['Genre'] != 'N/A') {
      genres = data['Genre'].split(', ');
    }

    return Movie(
      id: int.tryParse(data['imdbID']?.replaceAll('tt', '') ?? '0') ?? 0,
      imdbId: data['imdbID'] ?? '',
      title: data['Title'] ?? 'Без названия',
      overview: data['Plot'] != 'N/A' ? data['Plot'] : '',
      posterPath: data['Poster'] != 'N/A' ? data['Poster'] : '',
      genres: genres,
      voteAverage: rating,
      releaseDate: data['Released'] != 'N/A' ? data['Released'] : '',
      year: data['Year'] != 'N/A' ? data['Year'] : '',
      director: data['Director'] != 'N/A' ? data['Director'] : '',
      actors: data['Actors'] != 'N/A' ? data['Actors'] : '',
    );
  }
}
