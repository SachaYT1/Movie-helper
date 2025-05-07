
import '../repositories/movie_repository.dart';
import '../entities/movie.dart';

class GetRecommendationsUseCase {
  final MovieRepository repository;

  GetRecommendationsUseCase(this.repository);

  Future<List<Movie>> execute({
    List<String>? similarMovieIds,
    List<String>? genres,
    String? query,
  }) async {
    return await repository.getRecommendations(
      similarMovieIds: similarMovieIds,
      genres: genres,
      query: query,
    );
  }
}