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
}