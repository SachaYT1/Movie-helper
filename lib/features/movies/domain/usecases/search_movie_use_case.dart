import '../repositories/movie_repository.dart';
import '../entities/movie.dart';

class SearchMoviesUseCase {
  final MovieRepository repository;

  SearchMoviesUseCase(this.repository);

  Future<List<Movie>> execute(String query) async {
    if (query.isEmpty) {
      throw Exception('Search query cannot be empty');
    }
    return await repository.searchMovies(query);
  }
}