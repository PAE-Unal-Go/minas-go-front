class ChallengeQuestion {
  final String id;
  final String pointName;
  final String pointLabel;
  final String pointImage;
  final String question;
  final int rewardPoints;
  final List<String> options;
  final int correctIndex;
  final String correctAnswerText;

  const ChallengeQuestion({
    required this.id,
    required this.pointName,
    required this.pointLabel,
    required this.pointImage,
    required this.question,
    required this.rewardPoints,
    required this.options,
    required this.correctIndex,
    required this.correctAnswerText,
  });
}
