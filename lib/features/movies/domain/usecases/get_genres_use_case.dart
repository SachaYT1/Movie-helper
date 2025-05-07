import '../repositories/movie_repository.dart';

class GetGenresUseCase {
  final MovieRepository repository;

  GetGenresUseCase(this.repository);

  Future<Map<int, String>> execute() async {
    return await repository.getGenres();
  }
}