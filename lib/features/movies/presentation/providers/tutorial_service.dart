import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialService {
  late TutorialCoachMark tutorialCoachMark;
  final List<GlobalKey> targetKeys;
  final ScrollController scrollController;
  final BuildContext context;
  int currentStep = 0;

  TutorialService({
    required this.targetKeys,
    required this.scrollController,
    required this.context,
  });

  /// Начать показ туториала
  void startTutorial() async {
    currentStep = 0;
    if (targetKeys.isNotEmpty) {
      await scrollToWidget(targetKeys[0]);
      showTutorialStep();
    }
  }

  /// Показать текущий шаг туториала
  void showTutorialStep() {
    initTargetForCurrentStep();
    tutorialCoachMark.show(context: context);
  }

  /// Перейти к следующему шагу
  void moveToNextStep() async {
    currentStep++;
    if (currentStep < targetKeys.length) {
      await scrollToWidget(targetKeys[currentStep]);
      showTutorialStep();
    }
  }

  /// Перейти к предыдущему шагу
  void moveToPreviousStep() async {
    currentStep--;
    if (currentStep >= 0) {
      await scrollToWidget(targetKeys[currentStep]);
      showTutorialStep();
    }
  }

  /// Прокрутить экран к виджету с указанным ключом
  Future<void> scrollToWidget(GlobalKey key) async {
    // Даем немного времени для отрисовки UI
    await Future.delayed(const Duration(milliseconds: 100));

    final keyContext = key.currentContext;
    if (keyContext != null) {
      // Получаем позицию и размер виджета
      final box = keyContext.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);

      // Рассчитываем позицию для скролла, центрируя виджет на экране
      final screenHeight = MediaQuery.of(context).size.height;
      final widgetHeight = box.size.height;
      final scrollOffset =
          position.dy - (screenHeight / 2) + (widgetHeight / 2);

      // Проверяем доступность ScrollController
      if (!scrollController.hasClients) return;

      // Ограничиваем скролл в пределах возможного
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final minScrollExtent = scrollController.position.minScrollExtent;

      final targetOffset = scrollOffset.clamp(minScrollExtent, maxScrollExtent);

      // Прокручиваем к виджету
      await scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // Даем время для завершения анимации
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Создать подсказку для текущего шага
  void initTargetForCurrentStep() {
    GlobalKey currentKey = targetKeys[currentStep];
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "target_$currentStep",
        keyTarget: currentKey,
        alignSkip: Alignment.topRight,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: _getContentAlignForStep(currentStep),
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitleForStep(currentStep),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getDescriptionForStep(currentStep),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationButtons(currentStep),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: Theme.of(context).primaryColor,
        textSkip: "Пропустить",
        paddingFocus: 10,
        opacityShadow: 0.8,
        hideSkip: false,
        onFinish: () {
          print("Руководство завершено");
        },
        onSkip: () {
          print("Руководство пропущено");
          return true;
        });
  }

  /// Получить выравнивание контента для текущего шага
  ContentAlign _getContentAlignForStep(int step) {
    switch (step) {
      case 0: // Шаг с добавлением фильмов
        return ContentAlign.bottom;
      default:
        return ContentAlign.top;
    }
  }

  /// Получить заголовок для текущего шага
  String _getTitleForStep(int step) {
    switch (step) {
      case 0:
        return "Добавление похожих фильмов";
      case 1:
        return "Выбор жанров";
      case 2:
        return "Текстовое описание";
      default:
        return "Шаг ${step + 1}";
    }
  }

  /// Получить описание для текущего шага
  String _getDescriptionForStep(int step) {
    switch (step) {
      case 0:
        return "Нажмите на эту кнопку, чтобы найти и добавить фильмы, похожие на которые вы хотите посмотреть";
      case 1:
        return "Выберите интересующие вас жанры фильмов, чтобы получить более точные рекомендации";
      case 2:
        return "Опишите, какой фильм вы хотите посмотреть. Например: 'Научная фантастика с неожиданным финалом' или 'Триллер с Томом Харди'";
      default:
        return "Описание шага ${step + 1}";
    }
  }

  /// Создать кнопки навигации для текущего шага
  Widget _buildNavigationButtons(int step) {
    final isFirstStep = step == 0;
    final isLastStep = step == targetKeys.length - 1;

    return Row(
      mainAxisAlignment:
          isFirstStep ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirstStep)
          ElevatedButton(
            onPressed: () {
              tutorialCoachMark.previous();
              moveToPreviousStep();
            },
            child: const Text("Назад"),
          ),
        ElevatedButton(
          onPressed: () {
            if (isLastStep) {
              tutorialCoachMark.skip();
            } else {
              tutorialCoachMark.next();
              moveToNextStep();
            }
          },
          child: Text(isLastStep ? "Завершить" : "Далее"),
        ),
      ],
    );
  }
}
