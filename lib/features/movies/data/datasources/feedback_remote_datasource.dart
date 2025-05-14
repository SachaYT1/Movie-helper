import 'package:dio/dio.dart';
import '../models/feedback_model.dart';
import 'package:movie_helper/core/utils/logger.dart';

class FeedbackRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  FeedbackRemoteDataSource({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? 'http://localhost:5000/api';

  Future<bool> submitFeedback(FeedbackModel feedback) async {
    try {
      log.d('Submitting feedback: ${feedback.toJson()}');

      final url = '$_baseUrl/feedback';
      log.d('Request URL: $url');

      final response = await _dio.post(
        url,
        data: feedback.toJson(),
      );

      log.d('Server response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 201) {
        return true;
      } else {
        log.e('Error submitting feedback: ${response.statusMessage}');
        throw Exception(
            'Error submitting feedback: ${response.statusMessage}');
      }
    } catch (e) {
      log.e('Error submitting feedback: $e');
      if (e is DioException) {
        log.e('DioError type: ${e.type}');
        log.e('DioError message: ${e.message}');
        log.e('DioError response: ${e.response?.statusCode}, ${e.response?.data}');
      }
      return false;
    }
  }
}
