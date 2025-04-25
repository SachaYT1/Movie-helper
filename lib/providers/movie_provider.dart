import 'package:flutter/material.dart';
import 'package:movie_helper/models/movie.dart';
import 'package:movie_helper/models/genre.dart';
import 'package:movie_helper/services/movie_service.dart';

class MovieProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  List<Movie> _recommendedMovies = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  bool _isLoading = false;
  String _error = '';

  // Геттеры
  List<Movie> get recommendedMovies => _recommendedMovies;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Загрузка жанров
  Future<void> loadGenres() async {
    _setLoading(true);
    try {
      final genresMap = await _movieService.getGenres();
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
      _searchResults = await _movieService.searchMovies(query);
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
      _recommendedMovies = await _movieService.getRecommendations(
        similarMovieIds: similarMovieIds,
        genres: genres,
        query: query,
      );
      _setError('');
    } catch (e) {
      _setError('Ошибка при получении рекомендаций: $e');
    } finally {
      _setLoading(false);
    }
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
