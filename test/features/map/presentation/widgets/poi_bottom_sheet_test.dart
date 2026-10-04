import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/presentation/widgets/poi_bottom_sheet.dart';

PuntoDeInteres _lockedPunto() => const PuntoDeInteres(
      id: 1,
      nombre: 'Plaza Central',
      descripcion: 'Una plaza',
      categoria: 'historico',
      campus: 'El Volador',
      universidad: 'UNAL Medellín',
      latitud: 6.25,
      longitud: -75.57,
      visitado: false,
    );

void main() {
  group('PoiBottomSheet', () {
    testWidgets('does not offer rating before unlocking', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: () async {},
            ),
          ),
        ),
      );

      expect(find.textContaining('calificar'), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      expect(find.text('Desbloquear'), findsOneWidget);
    });

    testWidgets('tapping Desbloquear calls onUnlock', (tester) async {
      var called = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: () async => called++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Desbloquear'));
      await tester.pump();

      expect(called, 1);
    });

    testWidgets('shows the locked state when out of range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 50,
              onUnlock: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Debes estar más cerca'), findsOneWidget);
    });
  });
}
