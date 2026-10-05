import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/core/widgets/campus_dropdown.dart';
import 'package:minasgo_frontend/features/map/domain/entities/campus.dart';

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
  testWidgets('shows the first campus when nothing is selected',
      (tester) async {
    await tester.pumpWidget(_wrap(
      campuses: const [Campus.unalMedellin, Campus.benjaminConstant],
      onChanged: (_) {},
    ));

    expect(
      find.text('Universidad Nacional de Colombia (Medellín)'),
      findsOneWidget,
    );
    expect(find.text('Todos los campus'), findsNothing);
  });

  testWidgets('shows the readable name of the selected campus', (tester) async {
    await tester.pumpWidget(_wrap(
      campuses: const [Campus.unalMedellin, Campus.benjaminConstant],
      selected: Campus.benjaminConstant,
      onChanged: (_) {},
    ));

    expect(find.text('Instituto Benjamin Constant'), findsOneWidget);
    expect(find.text('rio_de_janeiro'), findsNothing);
  });

  testWidgets('lists only the two campus groups and reports the pick',
      (tester) async {
    final picked = <String?>[];
    await tester.pumpWidget(_wrap(
      campuses: const [Campus.unalMedellin, Campus.benjaminConstant],
      onChanged: picked.add,
    ));

    await tester.tap(find.byType(CampusDropdown));
    await tester.pumpAndSettle();

    expect(
      find.text('Universidad Nacional de Colombia (Medellín)'),
      findsWidgets,
    );
    expect(find.text('Instituto Benjamin Constant'), findsOneWidget);
    expect(find.text('Minas'), findsNothing);
    expect(find.text('El Volador'), findsNothing);
    expect(find.text('El Río'), findsNothing);
    expect(find.text('Todos los campus'), findsNothing);

    await tester.tap(find.text('Instituto Benjamin Constant'));
    await tester.pumpAndSettle();

    expect(picked, [Campus.benjaminConstant]);
  });

  testWidgets('is hidden when there is nothing to choose between',
      (tester) async {
    await tester.pumpWidget(
        _wrap(campuses: const [Campus.unalMedellin], onChanged: (_) {}));

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
                campuses: const [
                  Campus.unalMedellin,
                  Campus.benjaminConstant,
                ],
                selected: Campus.unalMedellin,
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
