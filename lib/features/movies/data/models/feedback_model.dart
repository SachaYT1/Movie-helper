import '../../domain/entities/feedback.dart';

class FeedbackModel extends Feedback {
  FeedbackModel({
    required super.userId,
    required super.grade,
    super.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'grade': grade,
      'text': text,
    };
  }

  factory FeedbackModel.fromEntity(Feedback feedback) {
    return FeedbackModel(
      userId: feedback.userId,
      grade: feedback.grade,
      text: feedback.text,
    );
  }
}
