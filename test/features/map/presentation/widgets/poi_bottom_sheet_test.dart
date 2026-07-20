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
  group('PoiBottomSheet rating selector', () {
    testWidgets('shows the rating prompt and 5 stars when in range and locked',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: (_) async {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('¿Deseas calificar este punto?'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    });

    testWidgets('does not show the rating prompt when out of range',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 50,
              onUnlock: (_) async {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('¿Deseas calificar este punto?'),
        findsNothing,
      );
    });

    testWidgets('tapping the 4th star fills 4 stars and unlock passes 4',
        (tester) async {
      int? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: (calificacion) async {
                received = calificacion;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border_rounded).at(3));
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

      await tester.tap(find.text('Desbloquear'));
      await tester.pump();

      expect(received, 4);
    });

    testWidgets('tapping the selected star again deselects it',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: (_) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border_rounded).at(2));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.star_rounded).at(2));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    });

    testWidgets('unlocking without selecting a star passes null',
        (tester) async {
      int? received = -1; // sentinel to distinguish "never called"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiBottomSheet(
              punto: _lockedPunto(),
              distanceMeters: 2,
              onUnlock: (calificacion) async {
                received = calificacion;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Desbloquear'));
      await tester.pump();

      expect(received, isNull);
    });
  });
}
