// lib/features/movies/presentation/providers/movie_provider.dart
import 'package:flutter/material.dart';
import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/domain/entities/genre.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_recommendation_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/search_movie_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_genres_use_case.dart';

class MovieProvider extends ChangeNotifier {
  final SearchMoviesUseCase _searchMoviesUseCase;
  final GetRecommendationsUseCase _getRecommendationsUseCase;
  final GetGenresUseCase _getGenresUseCase;

  List<Movie> _recommendedMovies = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  List<Movie> _similarMovies = [];
  List<String> _selectedGenres = [];
  bool _isLoading = false;
  String _error = '';

  // Геттеры
  List<Movie> get recommendedMovies => _recommendedMovies;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  List<Movie> get similarMovies => _similarMovies;
  List<String> get selectedGenres => _selectedGenres;
  bool get isLoading => _isLoading;
  String get error => _error;

  MovieProvider({
    required SearchMoviesUseCase searchMoviesUseCase,
    required GetRecommendationsUseCase getRecommendationsUseCase,
    required GetGenresUseCase getGenresUseCase,
  })  : _searchMoviesUseCase = searchMoviesUseCase,
        _getRecommendationsUseCase = getRecommendationsUseCase,
        _getGenresUseCase = getGenresUseCase;

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

  // Получение рекомендаций
  Future<void> getRecommendations({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  }) async {
    _setLoading(true);
    try {
      _recommendedMovies = await _getRecommendationsUseCase.execute(
        similarMovieIds:
            similarMovieIds ?? _similarMovies.map((m) => m.imdbId).toList(),
        genres: genres ?? _selectedGenres,
        query: query,
      );
      _setError('');
    } catch (e) {
      _setError('Ошибка при получении рекомендаций: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Методы для управления похожими фильмами
  void addSimilarMovie(Movie movie) {
    if (!_similarMovies.any((m) => m.imdbId == movie.imdbId)) {
      _similarMovies.add(movie);
      notifyListeners();
    }
  }

  void removeSimilarMovie(Movie movie) {
    _similarMovies.removeWhere((m) => m.imdbId == movie.imdbId);
    notifyListeners();
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
