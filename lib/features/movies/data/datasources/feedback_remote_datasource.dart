import 'package:dio/dio.dart';
import 'package:movie_helper/core/constants/app_constants.dart';
import '../models/feedback_model.dart';

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
      print('Отправка отзыва на сервер: ${feedback.toJson()}');

      final url = '$_baseUrl/feedback';
      print('URL запроса: $url');

      final response = await _dio.post(
        url,
        data: feedback.toJson(),
      );

      print('Ответ сервера: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
            'Ошибка при отправке отзыва: ${response.statusMessage}');
      }
    } catch (e) {
      print('Ошибка при отправке отзыва: $e');
      if (e is DioException) {
        print('DioError тип: ${e.type}');
        print('DioError сообщение: ${e.message}');
        print('DioError ответ: ${e.response?.statusCode}, ${e.response?.data}');
      }
      return false;
    }
  }
}
