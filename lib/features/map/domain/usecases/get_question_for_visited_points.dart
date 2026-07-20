import '../entities/quiz_question.dart';
import '../repositories/map_repository.dart';

class GetQuestionForVisitedPoints {
  final MapRepository repository;
  const GetQuestionForVisitedPoints(this.repository);

  Future<QuizQuestion?> call(String userId) {
    return repository.getQuestionForVisitedPoints(userId);
  }
}
