import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../mock/challenge_questions_mock.dart';
import '../models/challenge_question.dart';
import '../widgets/challenge_feedback_card.dart';
import '../widgets/challenge_option_tile.dart';
import '../widgets/challenge_prompt_message.dart';
import '../widgets/challenge_question_card.dart';
import '../widgets/challenges_top_bar.dart';
import '../widgets/point_reference_header.dart';

class ChallengesView extends StatefulWidget {
  const ChallengesView({super.key});

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView> {
  late final Random _random;
  late ChallengeQuestion _question;
  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _random = Random();
    _pickRandomQuestion();
  }

  void _pickRandomQuestion() {
    _question =
        challengeQuestionsMock[_random.nextInt(challengeQuestionsMock.length)];
    _selectedIndex = null;
    _answered = false;
  }

  void _nextQuestion() {
    setState(_pickRandomQuestion);
  }

  void _onOptionTap(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryMain,
      body: Column(
        children: [
          const ChallengesTopBar(points: 150),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SingleChildScrollView(
                    key: ValueKey(_question.id),
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PointReferenceHeader(question: _question),
                        const SizedBox(height: 14),
                        ChallengeQuestionCard(question: _question),
                        const SizedBox(height: 14),
                        ...List.generate(_question.options.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ChallengeOptionTile(
                              label: String.fromCharCode(65 + index),
                              text: _question.options[index],
                              selected: _selectedIndex == index,
                              answered: _answered,
                              isCorrect: index == _question.correctIndex,
                              onTap: () => _onOptionTap(index),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: !_answered
                              ? const ChallengePromptMessage()
                              : ChallengeFeedbackCard(
                                  key: ValueKey('feedback-${_selectedIndex ?? -1}'),
                                  success:
                                      _selectedIndex == _question.correctIndex,
                                  message: _selectedIndex ==
                                          _question.correctIndex
                                      ? _question.correctAnswerText
                                      : 'La respuesta correcta es ${_question.options[_question.correctIndex].toLowerCase()}. ${_question.correctAnswerText}',
                                ),
                        ),
                        SizedBox(height: 18 + bottomPadding),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _nextQuestion,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                            child: const Text('Siguiente pregunta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}