import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/core/widgets/campus_dropdown.dart';

Widget _wrap({
  required List<String> campuses,
  String? selected,
  required ValueChanged<String?> onChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0E147A),
        body: Center(
          child: CampusDropdown(
            campuses: campuses,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows "Todos los campus" when nothing is selected',
      (tester) async {
    await tester.pumpWidget(
        _wrap(campuses: const ['minas', 'volador'], onChanged: (_) {}));

    expect(find.text('Todos los campus'), findsOneWidget);
  });

  testWidgets('shows the readable name of the selected campus', (tester) async {
    await tester.pumpWidget(_wrap(
      campuses: const ['minas', 'volador'],
      selected: 'volador',
      onChanged: (_) {},
    ));

    expect(find.text('El Volador'), findsOneWidget);
    expect(find.text('volador'), findsNothing);
  });

  testWidgets('lists all campuses and reports the one the user picks',
      (tester) async {
    final picked = <String?>[];
    await tester.pumpWidget(_wrap(
      campuses: const ['minas', 'volador', 'rio'],
      onChanged: picked.add,
    ));

    await tester.tap(find.byType(CampusDropdown));
    await tester.pumpAndSettle();

    expect(find.text('Minas'), findsOneWidget);
    expect(find.text('El Volador'), findsOneWidget);
    expect(find.text('El Río'), findsOneWidget);

    await tester.tap(find.text('El Volador'));
    await tester.pumpAndSettle();

    expect(picked, ['volador']);
  });

  testWidgets('choosing "Todos los campus" reports null', (tester) async {
    final picked = <String?>[];
    await tester.pumpWidget(_wrap(
      campuses: const ['minas', 'volador'],
      selected: 'minas',
      onChanged: picked.add,
    ));

    await tester.tap(find.byType(CampusDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos los campus'));
    await tester.pumpAndSettle();

    expect(picked, [null]);
  });

  testWidgets('is hidden when there is nothing to choose between',
      (tester) async {
    await tester.pumpWidget(
        _wrap(campuses: const ['minas'], onChanged: (_) {}));

    expect(find.text('Todos los campus'), findsNothing);
    expect(find.byIcon(Icons.location_on_rounded), findsNothing);
  });

  testWidgets('does not overflow in a narrow space with a long name',
      (tester) async {
    tester.view.physicalSize = const Size(200, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            const Text('Explorar'),
            Flexible(
              child: CampusDropdown(
                campuses: const ['minas', 'rio_de_janeiro'],
                selected: 'rio_de_janeiro',
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
