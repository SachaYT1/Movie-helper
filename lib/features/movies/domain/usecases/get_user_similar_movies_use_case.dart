import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/domain/repositories/movie_repository.dart';

class GetUserSimilarMoviesUseCase {
  final MovieRepository repository;

  GetUserSimilarMoviesUseCase(this.repository);

  Future<List<Movie>> execute(int userId) async {
    return await repository.getUserSimilarMovies(userId);
  }
}
