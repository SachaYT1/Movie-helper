// lib/features/movies/data/repositories/movie_repository_impl.dart
import 'package:movie_helper/core/constants/app_constants.dart';

import '../../domain/repositories/movie_repository.dart';
import '../../domain/entities/movie.dart';
import '../datasources/movie_remote_datasource.dart';
import '../datasources/similar_movies_datasource.dart';
import '../datasources/ml_recommendations_datasource.dart';
import '../models/movie_model.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;
  final SimilarMoviesDataSource similarMoviesDataSource;
  final MlRecommendationsDataSource mlRecommendationsDataSource;

  MovieRepositoryImpl({
    required this.remoteDataSource,
    required this.similarMoviesDataSource,
    required this.mlRecommendationsDataSource,
  });

  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await remoteDataSource.searchMovies(query);
      final List<Movie> movies = [];

      if (response['Response'] == 'True' && response['Search'] != null) {
        for (var item in response['Search']) {
          final details =
              await remoteDataSource.getMovieDetails(item['imdbID']);
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
      // final String year = movieDetails['Year']?.split('–')[0] ?? '';

      // Ищем фильмы с таким же жанром
      final response = await remoteDataSource.searchMovies(genre);
      final List<Movie> similarMovies = [];

      if (response['Response'] == 'True' && response['Search'] != null) {
        for (var item in response['Search']) {
          // Пропускаем тот же самый фильм
          if (item['imdbID'] == imdbId) continue;

          final details =
              await remoteDataSource.getMovieDetails(item['imdbID']);
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
          final details =
              await remoteDataSource.getMovieDetails(item['imdbID']);
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

  @override
  Future<List<Movie>> getUserSimilarMovies(int userId) async {
    try {
      final similarMoviesData =
          await similarMoviesDataSource.getUserSimilarMovies(userId);

      List<Movie> movies = [];
      for (var movieData in similarMoviesData) {
        try {
          print('Movie data from DB: $movieData');

          // Try to fetch poster and additional details if we have an imdbId
          String posterPath =
              'https://via.placeholder.com/300x450?text=No+Poster';
          String actors = '';
          String director = '';

          final imdbId = movieData['imdb_id'] ?? movieData['orig_title'] ?? '';

          // If we have an IMDb ID, try to fetch poster and additional details from OMDB API
          if (imdbId.isNotEmpty && imdbId.startsWith('tt')) {
            try {
              final details = await remoteDataSource.getMovieDetails(imdbId);
              if (details['Response'] == 'True') {
                posterPath =
                    details['Poster'] != 'N/A' ? details['Poster'] : posterPath;
                actors = details['Actors'] != 'N/A' ? details['Actors'] : '';
                director =
                    details['Director'] != 'N/A' ? details['Director'] : '';
              }
            } catch (e) {
              print('Error fetching movie details: $e');
            }
          }

          // We need to transform the DB movie data to match our Movie entity structure
          final movie = Movie(
            // Use the id field from the database - this is the primary key we'll need for deletion
            id: movieData['id'] ?? 0,
            imdbId: imdbId,
            title: movieData['title'] ?? '',
            overview: movieData['overview'] ?? '',
            posterPath: posterPath,
            genres: movieData['genre']?.toString().split(',') ?? [],
            voteAverage: movieData['score']?.toDouble() ?? 0.0,
            releaseDate: movieData['date_x'] ?? '',
            year: movieData['date_x']?.substring(0, 4) ?? '',
            director: director,
            actors: actors,
          );

          print(
              'Mapped movie: ID=${movie.id}, Title=${movie.title}, Poster=${movie.posterPath}');
          movies.add(movie);
        } catch (e) {
          print('Error mapping movie: $e');
        }
      }

      return movies;
    } catch (e) {
      throw Exception('Failed to get user similar movies: $e');
    }
  }

  @override
  Future<void> addSimilarMovie(int userId, Movie movie) async {
    try {
      print(
          'Adding movie to database: ${movie.title}, IMDb ID: ${movie.imdbId}');

      // Transform movie to backend API format
      final movieData = {
        'title': movie.title,
        'date_x': movie.releaseDate,
        'score': movie.voteAverage,
        'genre': movie.genres.join(', '),
        'overview': movie.overview,
        'orig_title': movie.imdbId, // Store IMDb ID in the orig_title field
        'crew': '{"Actors": "${movie.actors}"}'
      };

      await similarMoviesDataSource.addSimilarMovie(userId, movieData);
    } catch (e) {
      throw Exception('Failed to add similar movie: $e');
    }
  }

  @override
  Future<void> removeSimilarMovie(int userId, int movieId) async {
    try {
      await similarMoviesDataSource.removeSimilarMovie(userId, movieId);
    } catch (e) {
      throw Exception('Failed to remove similar movie: $e');
    }
  }

  @override
  Future<List<Movie>> getMlRecommendations({
    required int userId,
    required String description,
    required List<String> genres,
  }) async {
    try {
      print(
          'Getting ML recommendations for user $userId with genres: $genres, description: $description');

      final mlRecommendationsData =
          await mlRecommendationsDataSource.getMlRecommendations(
        userId: userId,
        description: description,
        genres: genres,
      );

      final List<Movie> recommendations = [];

      for (var movieData in mlRecommendationsData) {
        try {
          // Convert ML API recommendation to Movie entity
          final movie = Movie(
            id: movieData['id'] ?? 0,
            imdbId: movieData['imdb_id'] ?? '',
            title: movieData['title'] ?? '',
            overview: movieData['overview'] ?? '',
            posterPath: '', // We'll need to fetch this separately if needed
            genres: (movieData['genre'] as String?)?.split(', ') ?? [],
            voteAverage: (movieData['score'] as num?)?.toDouble() ?? 0.0,
            releaseDate: '',
            year: '',
            director: '',
            actors: (movieData['matched_actors'] as List<dynamic>?)
                    ?.map((actor) => actor.toString())
                    ?.join(', ') ??
                '',
          );

          recommendations.add(movie);

          // If we need posters, we could fetch them here using the OMDB API
          // but that might slow down the response
        } catch (e) {
          print('Error mapping ML recommendation to Movie: $e');
        }
      }

      return recommendations;
    } catch (e) {
      print('Failed to get ML recommendations: $e');
      throw Exception('Failed to get ML recommendations: $e');
    }
  }
}
