import '../repositories/map_repository.dart';

class UnlockPoi {
  final MapRepository repository;
  const UnlockPoi(this.repository);

  Future<int> call(String userId, int puntoId, {int? calificacion}) {
    return repository.unlockPoi(userId, puntoId, calificacion: calificacion);
  }
}
