import 'package:movie_helper/features/movies/domain/repositories/movie_repository.dart';

class RemoveSimilarMovieUseCase {
  final MovieRepository repository;

  RemoveSimilarMovieUseCase(this.repository);

  Future<void> execute(int userId, int movieId) async {
    await repository.removeSimilarMovie(userId, movieId);
  }
}
