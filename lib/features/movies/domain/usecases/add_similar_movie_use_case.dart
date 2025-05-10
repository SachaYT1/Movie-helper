import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/domain/repositories/movie_repository.dart';

class AddSimilarMovieUseCase {
  final MovieRepository repository;

  AddSimilarMovieUseCase(this.repository);

  Future<void> execute(int userId, Movie movie) async {
    await repository.addSimilarMovie(userId, movie);
  }
}
