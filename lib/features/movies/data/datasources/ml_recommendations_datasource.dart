import 'package:dio/dio.dart';
import 'package:movie_helper/core/utils/logger.dart';
class MlRecommendationsDataSource {
  final Dio _dio;
  final String _baseUrl;

  MlRecommendationsDataSource({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? 'http://localhost:5000/api';

  Future<List<Map<String, dynamic>>> getMlRecommendations({
    required int userId,
    required String description,
    required List<String> genres,
  }) async {
    try {
      log.d('Sending request to API with:');
      log.d('userId: $userId');
      log.d('description: $description');
      log.d('genres: ${genres.join(',')}');

      // Правильный URL эндпоинта согласно app.py
      final url = '$_baseUrl/ml/recommendations';
      log.d('Using URL: $url');

      final response = await _dio.post(
        url,
        data: {
          'user_id': userId,
          'description': description,
          'genres': genres.join(','),
        },
      );

      log.d('ML API response status: ${response.statusCode}');
      log.d('ML API response data: ${response.data}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        log.e('Failed to get ML recommendations: ${response.statusMessage}');
        throw Exception(
            'Failed to get ML recommendations: ${response.statusMessage}');
      }
    } catch (e) {
      log.e('Error in ML recommendations: $e');
      if (e is DioException) {
        log.e('DioError type: ${e.type}');
        log.e('DioError message: ${e.message}');
        log.e(
            'DioError response: ${e.response?.statusCode}, ${e.response?.data}');
      }
      rethrow;
    }
  }
}
