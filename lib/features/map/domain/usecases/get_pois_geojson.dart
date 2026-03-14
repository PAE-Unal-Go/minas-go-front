import '../repositories/map_repository.dart';

class GetPoisGeoJson {
  final MapRepository repository;

  GetPoisGeoJson(this.repository);

  Future<String> call() async {
    return await repository.getPoisGeoJson();
  }
}
