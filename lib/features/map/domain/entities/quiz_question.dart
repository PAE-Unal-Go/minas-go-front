class QuizQuestion {
  final int id;
  final String pointName;
  final String question;
  final List<String> options;

  final int correctIndex;

  final int rewardPoints;

  const QuizQuestion({
    required this.id,
    required this.pointName,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.rewardPoints,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    int requireIntAny(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is num) return value.toInt();
        if (value != null) {
          throw FormatException(
            "RPC row inválida: '$key' debe ser num y llegó ${value.runtimeType} (value=$value). Row=$map",
          );
        }
      }

      throw FormatException(
        "RPC row inválida: faltan keys numéricas ${keys.join(', ')} (llegaron null o no existen). Row=$map",
      );
    }

    String readStringAny(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawOptions = map['opciones'];
    final options = switch (rawOptions) {
      final List list => list.map((e) => e.toString()).toList(growable: false),
      null => const <String>[],
      _ => <String>[rawOptions.toString()],
    };

    return QuizQuestion(
      // RPC can return either 'id' or 'pregunta_id' depending on SELECT aliases.
      id: requireIntAny(['id', 'pregunta_id']),
      // RPC can return either 'nombre' or 'nombre_punto'.
      pointName: readStringAny(['nombre', 'nombre_punto']),
      question: readStringAny(['enunciado', 'question']),
      options: options,
      correctIndex: requireIntAny(['respuesta_correcta_index', 'correct_index']),
      rewardPoints: requireIntAny(['puntos_recompensa', 'reward_points']),
    );
  }
}
