import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../models/challenge_question.dart';
import '../widgets/challenge_feedback_card.dart';
import '../widgets/challenge_option_tile.dart';
import '../widgets/challenge_prompt_message.dart';
import '../widgets/challenge_question_card.dart';
import '../widgets/challenges_top_bar.dart';
import '../widgets/point_reference_header.dart';
import '../../../map/data/repositories/map_repository_impl.dart';
import '../../../map/domain/usecases/get_question_for_visited_points.dart';
import '../../../map/domain/usecases/get_user_total_points.dart';
import '../../../map/domain/usecases/validate_answer.dart';
import '../../../../core/services/proximity_service.dart';

class ChallengesView extends StatefulWidget {
  const ChallengesView({super.key});

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView> {
  static const String _noMoreQuestionsMessage =
      'No hay más preguntas disponibles. Desbloquea más puntos y vuelve a intentarlo.';

  // Prevent showing the same question more than once per view session.
  final Set<int> _shownQuestionIds = {};
  static const int _maxFetchAttempts = 6;

  late ChallengeQuestion _question;
  int? _selectedIndex;
  bool _answered = false;
  bool _isLoading = true;
  bool _isValidating = false;
  String? _error;
  int _lastPointsEarned = 0;
  bool _lastCorrect = false;
  int _userTotalPoints = 0;

  final _repo = MapRepositoryImpl();
  late final GetQuestionForVisitedPoints _getQuestion;
  late final GetUserTotalPoints _getUserTotalPoints;
  late final ValidateAnswer _validateAnswer;

  @override
  void initState() {
    super.initState();
    _getQuestion = GetQuestionForVisitedPoints(_repo);
    _getUserTotalPoints = GetUserTotalPoints(_repo);
    _validateAnswer = ValidateAnswer(_repo);
    _loadQuestion();
  }

  Future<void> _refreshUserPoints() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final points = await _getUserTotalPoints(userId);
      if (!mounted) return;
      setState(() => _userTotalPoints = points);
    } catch (_) {
    }
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedIndex = null;
      _answered = false;
      _lastPointsEarned = 0;
      _lastCorrect = false;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No hay sesión activa.');
      }

      await _refreshUserPoints();

      // Retry a few times to avoid repeated questions when the RPC returns
      // a random row that may already have been shown in this session.
      var attempts = 0;
      var quiz = await _getQuestion(userId);
      while (attempts < _maxFetchAttempts && quiz != null) {
        if (!_shownQuestionIds.contains(quiz.id)) break;
        attempts++;
        quiz = await _getQuestion(userId);
      }

      if (quiz == null) {
        throw Exception(_noMoreQuestionsMessage);
      }
      if (_shownQuestionIds.contains(quiz.id)) {
        throw Exception(_noMoreQuestionsMessage);
      }

      final q = quiz;
      _shownQuestionIds.add(q.id);

      final pointImage = ProximityService()
          .allPuntos
          .where((p) => p.nombre == q.pointName)
          .expand((p) => p.imagesUrls)
          .cast<String?>()
          .firstWhere(
            (e) => e != null && e.isNotEmpty,
            orElse: () => null,
          );

      setState(() {
        _question = ChallengeQuestion(
          id: q.id.toString(),
          pointName: q.pointName,
          pointLabel: 'Punto relacionado',
          pointImage: pointImage,
          question: q.question,
          rewardPoints: q.rewardPoints,
          options: q.options,
          correctIndex: q.correctIndex,
          correctAnswerText: null,
        );
        _isLoading = false;
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
        _isLoading = false;
      });
    }
  }

  void _nextQuestion() {
    _loadQuestion();
  }

  Future<void> _onOptionTap(int index) async {
    if (_answered || _isValidating) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isValidating = true;
      _selectedIndex = index;
    });

    try {
      final res = await _validateAnswer(
        userId: userId,
        preguntaId: int.parse(_question.id),
        selectedIndex: index,
      );

      setState(() {
        _lastCorrect = res.correct;
        _lastPointsEarned = res.pointsEarned;
        _answered = true;
      });

      await _refreshUserPoints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryMain,
      body: Column(
        children: [
          ChallengesTopBar(points: _userTotalPoints),
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryMain,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 40,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: AppTypography.weightMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    FilledButton(
                                      onPressed: _loadQuestion,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primaryMain,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.pill),
                                        ),
                                      ),
                                      child: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              key: ValueKey(_question.id),
                              padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PointReferenceHeader(question: _question),
                                  const SizedBox(height: 14),
                                  ChallengeQuestionCard(question: _question),
                                  const SizedBox(height: 14),
                                  ...List.generate(_question.options.length,
                                      (index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
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
                                    duration:
                                        const Duration(milliseconds: 220),
                                    child: !_answered
                                        ? const ChallengePromptMessage()
                                        : ChallengeFeedbackCard(
                                            key: ValueKey(
                                                'feedback-${_selectedIndex ?? -1}'),
                                            success: _lastCorrect,
                                            message: _lastCorrect
                                                ? 'Ganaste $_lastPointsEarned puntos.'
                                              : 'En la próxima lo lograrás.',
                                          ),
                                  ),
                                  SizedBox(height: 18 + bottomPadding),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _isValidating
                                          ? null
                                          : _nextQuestion,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primaryMain,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.pill),
                                        ),
                                      ),
                                      child: Text(
                                        _isValidating
                                            ? 'Validando...'
                                            : 'Siguiente pregunta',
                                      ),
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