import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';

Map<String, dynamic> _baseMap({dynamic calificacion}) => {
      'id': 1,
      'nombre': 'Plaza Central',
      'descripcion': 'Una plaza',
      'images_urls': <String>[],
      'categoria': 'historico',
      'campus': 'El Volador',
      'universidad': 'UNAL Medellín',
      'latitud': 6.25,
      'longitud': -75.57,
      'visitado': true,
      'rarity': 'singular',
      if (calificacion != null) 'calificacion_promedio': calificacion,
    };

void main() {
  group('PuntoDeInteres.calificacionPromedio', () {
    test('parses a double value from the map', () {
      final punto = PuntoDeInteres.fromMap(_baseMap(calificacion: 4.5));
      expect(punto.calificacionPromedio, 4.5);
    });

    test('parses an int value from the map as a double', () {
      final punto = PuntoDeInteres.fromMap(_baseMap(calificacion: 4));
      expect(punto.calificacionPromedio, 4.0);
    });

    test('defaults to null when the field is absent', () {
      final punto = PuntoDeInteres.fromMap(_baseMap());
      expect(punto.calificacionPromedio, isNull);
    });

    test('is null by default via the constructor', () {
      const punto = PuntoDeInteres(
        id: 1,
        nombre: 'Test',
        categoria: 'historico',
        campus: 'El Volador',
        universidad: 'UNAL Medellín',
        latitud: 6.25,
        longitud: -75.57,
      );
      expect(punto.calificacionPromedio, isNull);
    });
  });

  group('PuntoDeInteres.miCalificacion', () {
    test('parses mi_calificacion from the map', () {
      final map = {..._baseMap(), 'mi_calificacion': 4};
      expect(PuntoDeInteres.fromMap(map).miCalificacion, 4);
    });

    test('is null when the user has not rated', () {
      expect(PuntoDeInteres.fromMap(_baseMap()).miCalificacion, isNull);
    });

    test('copyWith updates the rating and keeps the rest', () {
      final punto = PuntoDeInteres.fromMap(_baseMap(calificacion: 3));
      final updated = punto.copyWith(miCalificacion: 5);
      expect(updated.miCalificacion, 5);
      expect(updated.id, punto.id);
      expect(updated.calificacionPromedio, punto.calificacionPromedio);
    });
  });
}
