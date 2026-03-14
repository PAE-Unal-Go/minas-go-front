import '../entities/categoria.dart';
import '../repositories/map_repository.dart';

class GetCategorias {
  final MapRepository repository;
  GetCategorias(this.repository);

  Future<List<Categoria>> call(String? userId) {
    return repository.getCategorias(userId);
  }
}
