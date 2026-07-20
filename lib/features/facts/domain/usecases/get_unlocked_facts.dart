import '../entities/university_fact.dart';
import '../repositories/facts_repository.dart';

class GetUnlockedFacts {
  final FactsRepository repository;
  const GetUnlockedFacts(this.repository);

  Future<List<UniversityFact>> call(String userId) =>
      repository.getUnlockedFacts(userId);
}
