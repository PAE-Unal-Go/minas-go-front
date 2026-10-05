import '../entities/answer_validation_result.dart';
import '../repositories/map_repository.dart';

class ValidateAnswer {
  final MapRepository repository;
  const ValidateAnswer(this.repository);

  Future<AnswerValidationResult> call({
    required String userId,
    required int preguntaId,
    required int selectedIndex,
  }) {
    return repository.validateAnswer(
      userId: userId,
      preguntaId: preguntaId,
      selectedIndex: selectedIndex,
    );
  }
}
