import '../entities/university_fact.dart';

abstract class FactsRepository {
  Future<List<UniversityFact>> getUnlockedFacts(String userId);

  /// Calls desbloquear_dato_random RPC. Returns the newly unlocked fact
  /// if a milestone was reached, or null if no new unlock occurred.
  Future<UniversityFact?> tryUnlockFact(String userId);

  Future<int> getVisitCount(String userId);
}
