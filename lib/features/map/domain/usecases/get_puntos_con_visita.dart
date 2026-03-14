import '../entities/punto_de_interes.dart';
import '../repositories/map_repository.dart';

class GetPuntosConVisita {
  final MapRepository repository;
  GetPuntosConVisita(this.repository);

  Future<List<PuntoDeInteres>> call(String? userId) {
    return repository.getPuntosConVisita(userId);
  }
}
