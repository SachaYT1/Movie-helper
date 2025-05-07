// lib/features/movies/data/repositories/movie_repository_impl.dart
import 'package:movie_helper/core/constants/app_constants.dart';

import '../../domain/repositories/movie_repository.dart';
import '../../domain/entities/movie.dart';
import '../datasources/movie_remote_datasource.dart';
import '../models/movie_model.dart';


class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await remoteDataSource.searchMovies(query);
      final List<Movie> movies = [];

      if (response['Response'] == 'True' && response['Search'] != null) {
        for (var item in response['Search']) {
          final details = await remoteDataSource.getMovieDetails(item['imdbID']);
          if (details['Response'] == 'True') {
            movies.add(MovieModel.fromJson(details));
          }
        }
      }
      return movies;
    } catch (e) {
      throw Exception('Failed to search movies: $e');
    }
  }

  @override
  Future<List<Movie>> getSimilarMovies(String imdbId) async {
    try {
      // Получаем детали основного фильма
      final movieDetails = await remoteDataSource.getMovieDetails(imdbId);
      if (movieDetails['Response'] != 'True') {
        return [];
      }

      // Извлекаем жанр и год из деталей фильма
      final String genre = movieDetails['Genre']?.split(',')[0] ?? '';
      final String year = movieDetails['Year']?.split('–')[0] ?? '';

      // Ищем фильмы с таким же жанром
      final response = await remoteDataSource.searchMovies(genre);
      final List<Movie> similarMovies = [];

      if (response['Response'] == 'True' && response['Search'] != null) {
        for (var item in response['Search']) {
          // Пропускаем тот же самый фильм
          if (item['imdbID'] == imdbId) continue;

          final details = await remoteDataSource.getMovieDetails(item['imdbID']);
          if (details['Response'] == 'True') {
            similarMovies.add(MovieModel.fromJson(details));
          }

          // Ограничиваем количество результатов
          if (similarMovies.length >= 10) break;
        }
      }

      return similarMovies;
    } catch (e) {
      throw Exception('Failed to get similar movies: $e');
    }
  }

  @override
  Future<List<Movie>> getMoviesByGenre(String genre) async {
    try {
      final response = await remoteDataSource.searchMovies(genre);
      final List<Movie> movies = [];

      if (response['Response'] == 'True' && response['Search'] != null) {
        for (var item in response['Search']) {
          final details = await remoteDataSource.getMovieDetails(item['imdbID']);
          if (details['Response'] == 'True') {
            movies.add(MovieModel.fromJson(details));
          }
          if (movies.length >= 10) break;
        }
      }

      return movies;
    } catch (e) {
      throw Exception('Failed to get movies by genre: $e');
    }
  }

  @override
  Future<List<Movie>> getRecommendations({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  @override
  Future<Map<int, String>> getGenres() async {
    try {
      // Возвращаем предопределенный список жанров
      return MovieConstants.genres;
    } catch (e) {
      throw Exception('Failed to get genres: $e');
    }
  }
}