import '../entities/location_point.dart';
import '../entities/punto_de_interes.dart';
import '../entities/categoria.dart';

abstract class MapRepository {
  Future<LocationPoint> getCurrentLocation();
  Future<String> getPoisGeoJson();
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId);
  Future<List<Categoria>> getCategorias(String? userId);
}
