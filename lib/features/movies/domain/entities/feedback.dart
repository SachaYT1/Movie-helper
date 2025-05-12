class Feedback {
  final int userId;
  final int grade;
  final String text;

  Feedback({
    required this.userId,
    required this.grade,
    this.text = '',
  });
}
