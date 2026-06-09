import '../entities/university_fact.dart';
import '../repositories/facts_repository.dart';

class TryUnlockFact {
  final FactsRepository repository;
  const TryUnlockFact(this.repository);

  Future<UniversityFact?> call(String userId) =>
      repository.tryUnlockFact(userId);
}
