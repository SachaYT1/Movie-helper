import '../../domain/entities/feedback.dart';

class FeedbackModel extends Feedback {
  FeedbackModel({
    required int userId,
    required int grade,
    String text = '',
  }) : super(
          userId: userId,
          grade: grade,
          text: text,
        );

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
