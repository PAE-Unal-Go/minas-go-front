import '../repositories/map_repository.dart';

class RatePoi {
  final MapRepository repository;
  const RatePoi(this.repository);

  Future<void> call(String userId, int puntoId, int calificacion) {
    if (calificacion < 1 || calificacion > 5) {
      throw ArgumentError.value(calificacion, 'calificacion', 'must be 1-5');
    }
    return repository.ratePoi(userId, puntoId, calificacion);
  }
}
