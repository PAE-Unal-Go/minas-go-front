import '../repositories/map_repository.dart';

class UnlockPoi {
  final MapRepository repository;
  const UnlockPoi(this.repository);

  Future<void> call(String userId, int puntoId) {
    return repository.unlockPoi(userId, puntoId);
  }
}
