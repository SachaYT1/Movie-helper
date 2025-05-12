import '../entities/feedback.dart';

abstract class FeedbackRepository {
  /// Отправляет отзыв пользователя на сервер
  Future<bool> submitFeedback(Feedback feedback);
}
