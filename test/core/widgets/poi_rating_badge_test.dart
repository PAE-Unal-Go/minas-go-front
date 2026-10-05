import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/core/widgets/poi_rating_badge.dart';

void main() {
  group('PoiRatingBadge', () {
    testWidgets('shows the rating with one decimal when present',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PoiRatingBadge(rating: 4.5)),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Sin calificar'), findsNothing);
    });

    testWidgets('rounds to one decimal for values with more precision',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PoiRatingBadge(rating: 3.777)),
        ),
      );

      expect(find.text('3.8'), findsOneWidget);
    });

    testWidgets('shows "Sin calificar" when rating is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PoiRatingBadge(rating: null)),
        ),
      );

      expect(find.text('Sin calificar'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('shows "Sin calificar" when rating is zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PoiRatingBadge(rating: 0)),
        ),
      );

      expect(find.text('Sin calificar'), findsOneWidget);
    });
  });
}
