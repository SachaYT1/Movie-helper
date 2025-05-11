import '../entities/movie.dart';
import '../repositories/movie_repository.dart';

class GetMlRecommendationsUseCase {
  final MovieRepository repository;

  GetMlRecommendationsUseCase(this.repository);

  Future<List<Movie>> execute({
    required int userId,
    required String description,
    required List<String> genres,
  }) async {
    return await repository.getMlRecommendations(
      userId: userId,
      description: description,
      genres: genres,
    );
  }
}
