// lib/features/movies/presentation/providers/movie_provider.dart
import 'package:flutter/material.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';
import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/domain/entities/genre.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_recommendation_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/search_movie_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_genres_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_user_similar_movies_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/add_similar_movie_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/remove_similar_movie_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_ml_recommendations_use_case.dart';
import 'package:movie_helper/core/utils/logger.dart';

class MovieProvider extends ChangeNotifier {
  final SearchMoviesUseCase _searchMoviesUseCase;
  final GetRecommendationsUseCase _getRecommendationsUseCase;
  final GetGenresUseCase _getGenresUseCase;
  final GetUserSimilarMoviesUseCase _getUserSimilarMoviesUseCase;
  final AddSimilarMovieUseCase _addSimilarMovieUseCase;
  final RemoveSimilarMovieUseCase _removeSimilarMovieUseCase;
  final GetMlRecommendationsUseCase _getMlRecommendationsUseCase;
  final AuthProvider _authProvider;

  final int? userId;

  List<Movie> _recommendedMovies = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  List<Movie> _similarMovies = [];
  List<String> _selectedGenres = [];
  bool _isLoading = false;
  String _error = '';
  bool _useMlRecommendations = true; // По умолчанию используем ML рекомендации

  // Геттеры
  List<Movie> get recommendedMovies => _recommendedMovies;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  List<Movie> get similarMovies => _similarMovies;
  List<String> get selectedGenres => _selectedGenres;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get useMlRecommendations => _useMlRecommendations;

  MovieProvider({
    required SearchMoviesUseCase searchMoviesUseCase,
    required GetRecommendationsUseCase getRecommendationsUseCase,
    required GetGenresUseCase getGenresUseCase,
    required GetUserSimilarMoviesUseCase getUserSimilarMoviesUseCase,
    required AddSimilarMovieUseCase addSimilarMovieUseCase,
    required RemoveSimilarMovieUseCase removeSimilarMovieUseCase,
    required GetMlRecommendationsUseCase getMlRecommendationsUseCase,
    required AuthProvider authProvider,
    this.userId,
  })  : _searchMoviesUseCase = searchMoviesUseCase,
        _getRecommendationsUseCase = getRecommendationsUseCase,
        _getGenresUseCase = getGenresUseCase,
        _getUserSimilarMoviesUseCase = getUserSimilarMoviesUseCase,
        _addSimilarMovieUseCase = addSimilarMovieUseCase,
        _removeSimilarMovieUseCase = removeSimilarMovieUseCase,
        _getMlRecommendationsUseCase = getMlRecommendationsUseCase,
        _authProvider = authProvider {
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated && _authProvider.user?.id != null) {
      // User logged in, load their similar movies
      loadSimilarMoviesFromBackend();
    } else {
      // User logged out, clear similar movies
      _similarMovies = [];
      notifyListeners();
    }
  }

  // Загрузка жанров
  Future<void> loadGenres() async {
    _setLoading(true);
    try {
      final genresMap = await _getGenresUseCase.execute();
      _genres = genresMap.entries
          .map((entry) => Genre(id: entry.key, name: entry.value))
          .toList();
      _setError('');
    } catch (e) {
      _setError('Ошибка при загрузке жанров: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load similar movies from backend
  Future<void> loadSimilarMoviesFromBackend() async {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId == null) {
      _setError('User not authenticated');
      return;
    }

    _setLoading(true);
    try {
      _similarMovies =
          await _getUserSimilarMoviesUseCase.execute(currentUserId);
      _setError('');
    } catch (e) {
      _setError('Ошибка при загрузке похожих фильмов: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Поиск фильмов
  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResults = await _searchMoviesUseCase.execute(query);
      _setError('');
    } catch (e) {
      _setError('Ошибка при поиске фильмов: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Переключение между ML-рекомендациями и обычными
  void toggleMlRecommendations() {
    _useMlRecommendations = !_useMlRecommendations;
    notifyListeners();
  }

  // Получение рекомендаций с использованием ML или обычный метод
  Future<void> getRecommendations({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  }) async {
    _setLoading(true);

    try {
      if (_useMlRecommendations && _authProvider.user?.id != null) {
        // Use ML recommendations if enabled and user is authenticated
        _recommendedMovies = await _getMlRecommendationsUseCase.execute(
          userId: _authProvider.user!.id!,
          description: query ?? '',
          genres: genres ?? _selectedGenres,
        );
      } else {
        // Use regular recommendations otherwise
        _recommendedMovies = await _getRecommendationsUseCase.execute(
          similarMovieIds:
              similarMovieIds ?? _similarMovies.map((m) => m.imdbId).toList(),
          genres: genres ?? _selectedGenres,
          query: query,
        );
      }
      _setError('');
    } catch (e) {
      log.e('Error getting recommendations', e);
      _setError('Ошибка при получении рекомендаций: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Методы для управления похожими фильмами
  Future<void> addSimilarMovie(Movie movie) async {
    log.i(
        'Adding similar movie: ${movie.title}, IMDb ID: ${movie.imdbId}, Poster: ${movie.posterPath}');

    if (!_similarMovies.any((m) => m.imdbId == movie.imdbId)) {
      final currentUserId = _authProvider.user?.id;
      if (currentUserId == null) {
        log.w('User not authenticated, adding movie only to local list');
        _similarMovies.add(movie);
        notifyListeners();
        return;
      }

      // Set loading state to show progress
      _setLoading(true);

      try {
        // First, add the movie to the backend
        log.d('Adding movie to backend...');
        await _addSimilarMovieUseCase.execute(currentUserId, movie);
        log.i('Movie added to backend successfully');

        // Then reload all similar movies to get the proper DB ID and ensure all data is consistent
        log.d('Reloading similar movies to get updated list with DB IDs');
        final updatedMovies =
            await _getUserSimilarMoviesUseCase.execute(currentUserId);

        // Replace the entire list with the updated one from the backend
        _similarMovies = updatedMovies;
        log.i(
            'Similar movies list updated with ${_similarMovies.length} movies');

        _setError('');
      } catch (e) {
        log.e('Error adding similar movie', e);
        _setError('Ошибка при добавлении фильма: $e');
      } finally {
        _setLoading(false);
        notifyListeners();
      }
    } else {
      log.i('Movie already in the similar movies list, skipping addition');
    }
  }

  Future<void> removeSimilarMovie(Movie movie) async {
    log.i(
        'Removing movie: ${movie.title}, ID: ${movie.id}, imdbId: ${movie.imdbId}, posterPath: ${movie.posterPath}');

    // Store a reference to the movie before removing it
    final movieToRemove = movie;

    // First remove from local list for immediate UI update
    _similarMovies.removeWhere((m) => m.imdbId == movie.imdbId);
    notifyListeners();

    // Then remove from backend if user is authenticated
    final currentUserId = _authProvider.user?.id;
    if (currentUserId != null) {
      if (movie.id > 0) {
        try {
          log.d('Attempting to remove movie with ID: ${movie.id} from backend');
          await _removeSimilarMovieUseCase.execute(currentUserId, movie.id);
          log.i('Movie successfully removed from backend');
          // Movie successfully removed, no need to add it back
        } catch (e) {
          log.e('Error removing movie from backend', e);
          // If backend operation fails, add back to local list
          _similarMovies.add(movieToRemove);
          _setError('Ошибка при удалении фильма: $e');
          notifyListeners();
        }
      } else {
        log.w(
            'Warning: Movie ID is invalid (${movie.id}), cannot delete from backend');
      }
    } else {
      log.i('User not authenticated, movie only removed from local list');
    }
  }

  void clearSimilarMovies() {
    _similarMovies.clear();
    notifyListeners();
  }

  // Методы для управления выбранными жанрами
  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    notifyListeners();
  }

  void clearSelectedGenres() {
    _selectedGenres.clear();
    notifyListeners();
  }

  // Вспомогательные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
