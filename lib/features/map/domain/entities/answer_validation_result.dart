class AnswerValidationResult {
  final bool correct;
  final int pointsEarned;

  const AnswerValidationResult({
    required this.correct,
    required this.pointsEarned,
  });

  factory AnswerValidationResult.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        if (v == 'true' || v == 't' || v == '1' || v == 'yes' || v == 'y') {
          return true;
        }
        if (v == 'false' || v == 'f' || v == '0' || v == 'no' || v == 'n') {
          return false;
        }
      }
      return false;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value.trim()) ?? 0;
      }
      return 0;
    }

    dynamic readAny(List<String> keys) {
      for (final k in keys) {
        if (map.containsKey(k)) return map[k];
      }
      return null;
    }

    final correctValue = readAny([
      'v_acerto',
      'acerto',
      'correct',
      'is_correct',
      'es_correcta',
    ]);

    final pointsValue = readAny([
      'v_puntos_ganados',
      'puntos_ganados',
      'points_earned',
      'puntos',
      'puntos_obtenidos',
    ]);

    return AnswerValidationResult(
      correct: parseBool(correctValue),
      pointsEarned: parseInt(pointsValue),
    );
  }
}
