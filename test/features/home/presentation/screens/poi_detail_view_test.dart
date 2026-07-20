import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/home/presentation/screens/poi_detail_view.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';

PuntoDeInteres _punto({required String rarity, double? calificacion}) =>
    PuntoDeInteres(
      id: 1,
      nombre: 'Plaza Central',
      descripcion: 'Una plaza',
      categoria: 'historico',
      campus: 'El Volador',
      universidad: 'UNAL Medellín',
      latitud: 6.25,
      longitud: -75.57,
      visitado: true,
      rarity: rarity,
      calificacionPromedio: calificacion,
    );

Widget _wrap(PuntoDeInteres punto) => MaterialApp(
      home: PoiDetailView(
        punto: punto,
        categoryName: 'Histórico',
        pointName: punto.nombre,
        pointDescription: punto.descripcion ?? '',
      ),
    );

void main() {
  group('PoiDetailView rating badge', () {
    testWidgets('shows the rating on the basic (singular) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'singular', calificacion: 4.5)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('shows the rating on the important (epic) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'epic', calificacion: 3.2)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3.2'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows the rating on the legendary card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'legendary', calificacion: 5.0)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5.0'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows "Sin calificar" when there is no rating yet',
        (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'singular', calificacion: null)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sin calificar'), findsOneWidget);
    });

    testWidgets('does not show a rating badge on the locked card',
        (tester) async {
      const locked = PuntoDeInteres(
        id: 2,
        nombre: 'Zona Oculta',
        categoria: 'historico',
        campus: 'El Volador',
        universidad: 'UNAL Medellín',
        latitud: 6.25,
        longitud: -75.57,
        visitado: false,
        calificacionPromedio: 4.9,
      );

      await tester.pumpWidget(_wrap(locked));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4.9'), findsNothing);
      expect(find.text('Sin calificar'), findsNothing);
    });
  });
}
