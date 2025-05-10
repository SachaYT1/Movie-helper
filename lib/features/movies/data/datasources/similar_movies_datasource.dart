import 'package:dio/dio.dart';

class SimilarMoviesDataSource {
  final Dio _dio;
  final String _baseUrl;

  SimilarMoviesDataSource({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> getUserSimilarMovies(int userId) async {
    final response = await _dio.get('$_baseUrl/users/$userId/similar_movies');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> addSimilarMovie(
      int userId, Map<String, dynamic> movieData) async {
    await _dio.post(
      '$_baseUrl/users/$userId/similar_movies',
      data: movieData,
    );
  }

  Future<void> removeSimilarMovie(int userId, int movieId) async {
    try {
      print('Removing movie with ID: $movieId for user: $userId');
      final response =
          await _dio.delete('$_baseUrl/users/$userId/similar_movies/$movieId');
      print('Delete response: ${response.statusCode}');
    } catch (e) {
      print('Error removing movie: $e');
      if (e is DioException) {
        print('DioError status: ${e.response?.statusCode}');
        print('DioError data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
