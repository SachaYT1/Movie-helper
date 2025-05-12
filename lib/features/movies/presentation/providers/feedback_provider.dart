import 'package:flutter/material.dart';
import '../../domain/entities/feedback.dart' as entity;
import '../../domain/repositories/feedback_repository.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository;

  bool _isLoading = false;
  String _error = '';
  bool _isSubmitted = false;

  FeedbackProvider({
    required FeedbackRepository feedbackRepository,
  }) : _feedbackRepository = feedbackRepository;

  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isSubmitted => _isSubmitted;

  Future<bool> submitFeedback(int userId, int grade, String text) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final feedback = entity.Feedback(
        userId: userId,
        grade: grade,
        text: text,
      );

      final result = await _feedbackRepository.submitFeedback(feedback);

      if (result) {
        _isSubmitted = true;
      } else {
        _error = 'Не удалось отправить отзыв';
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _error = 'Ошибка: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void resetState() {
    _isLoading = false;
    _error = '';
    _isSubmitted = false;
    notifyListeners();
  }
}
