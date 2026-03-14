import '../entities/location_point.dart';
import '../repositories/map_repository.dart';

class GetUserLocation {
  final MapRepository repository;

  GetUserLocation(this.repository);

  Future<LocationPoint> call() async {
    return await repository.getCurrentLocation();
  }
}
