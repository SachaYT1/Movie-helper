import '../../domain/entities/feedback.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../models/feedback_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<bool> submitFeedback(Feedback feedback) async {
    try {
      final feedbackModel = FeedbackModel.fromEntity(feedback);
      final result = await remoteDataSource.submitFeedback(feedbackModel);
      return result;
    } catch (e) {
      print('Ошибка при отправке отзыва: $e');
      return false;
    }
  }
}
