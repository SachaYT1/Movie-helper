import 'package:dio/dio.dart';

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
      print('Sending request to API with:');
      print('userId: $userId');
      print('description: $description');
      print('genres: ${genres.join(',')}');

      // Правильный URL эндпоинта согласно app.py
      final url = '$_baseUrl/ml/recommendations';
      print('Using URL: $url');

      final response = await _dio.post(
        url,
        data: {
          'user_id': userId,
          'description': description,
          'genres': genres.join(','),
        },
      );

      print('ML API response status: ${response.statusCode}');
      print('ML API response data: ${response.data}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception(
            'Failed to get ML recommendations: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error in ML recommendations: $e');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print(
            'DioError response: ${e.response?.statusCode}, ${e.response?.data}');
      }
      rethrow;
    }
  }
}
