import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/presentation/widgets/poi_unlock_card.dart';

void main() {
  testWidgets('PoiUnlockCard shows the rating badge for the unlocked punto',
      (tester) async {
    const punto = PuntoDeInteres(
      id: 1,
      nombre: 'Plaza Central',
      descripcion: 'Una plaza',
      categoria: 'historico',
      campus: 'El Volador',
      universidad: 'UNAL Medellín',
      latitud: 6.25,
      longitud: -75.57,
      visitado: true,
      rarity: 'singular',
      calificacionPromedio: 4.5,
    );

    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PoiUnlockCard(punto: punto, onClose: () {}),
      ),
    );

    // Let the unlock flip animation reach the point where the card is built.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));
    // Flush the trailing 200ms delay in _runAnimation before the test ends.
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('4.5'), findsOneWidget);
  });
}
