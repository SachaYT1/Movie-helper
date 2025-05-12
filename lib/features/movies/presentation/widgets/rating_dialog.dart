import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';
import '../providers/feedback_provider.dart';

class RatingDialog extends StatefulWidget {
  final Function? onSubmitted;

  const RatingDialog({
    Key? key,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _showThankYou = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = Provider.of<FeedbackProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return AlertDialog(
      title: !_showThankYou
          ? const Text('Как вам наши рекомендации?')
          : const Text('Спасибо за ваш отзыв!'),
      content: !_showThankYou
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Оцените нашу рекомендательную систему:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Оставьте комментарий (необязательно)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  if (feedbackProvider.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        feedbackProvider.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            )
          : const Text(
              'Мы ценим ваше мнение и будем стараться делать наш сервис ещё лучше!'),
      actions: !_showThankYou
          ? [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: _rating == 0 || feedbackProvider.isLoading
                    ? null
                    : () async {
                        if (authProvider.isAuthenticated &&
                            authProvider.user != null) {
                          final success = await feedbackProvider.submitFeedback(
                            authProvider.user!.id!,
                            _rating,
                            _commentController.text,
                          );

                          if (success) {
                            setState(() {
                              _showThankYou = true;
                            });

                            if (widget.onSubmitted != null) {
                              widget.onSubmitted!();
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Необходимо авторизоваться для отправки отзыва'),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                child: feedbackProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Отправить'),
              ),
            ]
          : [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Закрыть'),
              ),
            ],
    );
  }
}
