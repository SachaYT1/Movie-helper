import '../entities/movie.dart';

abstract class MovieRepository {
  Future<List<Movie>> searchMovies(String query);
  Future<List<Movie>> getSimilarMovies(String imdbId);
  Future<List<Movie>> getMoviesByGenre(String genre);
  Future<List<Movie>> getRecommendations({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  });
  Future<Map<int, String>> getGenres();

  // New methods for user-specific similar movies operations
  Future<List<Movie>> getUserSimilarMovies(int userId);
  Future<void> addSimilarMovie(int userId, Movie movie);
  Future<void> removeSimilarMovie(int userId, int movieId);

  // New ML recommendations method
  Future<List<Movie>> getMlRecommendations({
    required int userId,
    required String description,
    required List<String> genres,
  });
}
