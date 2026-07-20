# POI Average Rating Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show each POI's backend-computed average rating (`calificacion_promedio`) on the unlock card and on the detail view, once the point is unlocked.

**Architecture:** Add a nullable `calificacionPromedio` field to the `PuntoDeInteres` entity (parsed from the backend map). Build one small reusable widget, `PoiRatingBadge`, that renders "★ 4.5" or "Sin calificar". Wire it into `PoiUnlockCard` and into each unlocked-state card variant of `PoiDetailView`.

**Tech Stack:** Flutter/Dart, `flutter_test` for unit/widget tests (no test suite exists yet in this repo — this plan adds the first test files).

## Global Constraints

- Rating format: `★` icon (`Icons.star_rounded`) + number with exactly one decimal (`toStringAsFixed(1)`), amber color `AppColors.warning` (`0xFFF59E0B`).
- Null or `0` rating → show text "Sin calificar" (gray/muted), same slot, block not hidden.
- Never show rating in the locked card (`_lockedCard()` in `PoiDetailView`) — only once `visitado == true`.
- No changes to `poi_bottom_sheet.dart` or `category_points_view.dart` — out of scope.
- No rating-input/write functionality — read-only display of a backend-computed value.

---

### Task 1: Add `calificacionPromedio` to `PuntoDeInteres`

**Files:**
- Modify: `lib/features/map/domain/entities/punto_de_interes.dart`
- Test: `test/features/map/domain/entities/punto_de_interes_test.dart`

**Interfaces:**
- Produces: `PuntoDeInteres.calificacionPromedio` (`double?`), settable via constructor and parsed by `PuntoDeInteres.fromMap`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/map/domain/entities/punto_de_interes_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/map/domain/entities/punto_de_interes_test.dart`
Expected: FAIL — `calificacionPromedio` is not a defined getter/named parameter on `PuntoDeInteres`.

- [ ] **Step 3: Implement the field and parsing**

Edit `lib/features/map/domain/entities/punto_de_interes.dart`:

```dart
class PuntoDeInteres {
  final int id;
  final String nombre;
  final String? descripcion;
  final List<String> imagesUrls;
  final String categoria;
  final String campus;
  final String universidad;
  final double latitud;
  final double longitud;
  final bool visitado;
  final String? rarity;
  final double? calificacionPromedio;

  const PuntoDeInteres({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagesUrls = const [],
    required this.categoria,
    required this.campus,
    required this.universidad,
    required this.latitud,
    required this.longitud,
    this.visitado = false,
    this.rarity,
    this.calificacionPromedio,
  });

  String? get mainImageUrl => imagesUrls.isNotEmpty ? imagesUrls.first : null;

  factory PuntoDeInteres.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images_urls'];
    List<String> parsedImages = const [];

    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final legacyMainImage = map['main_image_url'] as String?;
      if (legacyMainImage != null && legacyMainImage.isNotEmpty) {
        parsedImages = [legacyMainImage];
      }
    }

    return PuntoDeInteres(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      imagesUrls: parsedImages,
      categoria: map['categoria'] as String,
      campus: map['campus'] as String,
      universidad: map['universidad'] as String? ?? 'UNAL Medellín',
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      visitado: map['visitado'] as bool? ?? false,
      rarity: map['rarity'] as String?,
      calificacionPromedio: (map['calificacion_promedio'] as num?)?.toDouble(),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/map/domain/entities/punto_de_interes_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/map/domain/entities/punto_de_interes.dart test/features/map/domain/entities/punto_de_interes_test.dart
git commit -m "feat: parse calificacion_promedio into PuntoDeInteres"
```

---

### Task 2: Create the `PoiRatingBadge` widget

**Files:**
- Create: `lib/core/widgets/poi_rating_badge.dart`
- Test: `test/core/widgets/poi_rating_badge_test.dart`

**Interfaces:**
- Consumes: `AppColors.warning`, `AppColors.textSecondary` from `lib/core/theme/app_design_system.dart`.
- Produces: `PoiRatingBadge` widget with constructor `PoiRatingBadge({Key? key, required double? rating, Color? textColor})`. `textColor` overrides the default text color (used for dark backgrounds in `PoiDetailView`'s epic/legendary variants); the star icon color and "Sin calificar" gray are fixed regardless of `textColor`.

- [ ] **Step 1: Write the failing tests**

Create `test/core/widgets/poi_rating_badge_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/widgets/poi_rating_badge_test.dart`
Expected: FAIL — file `lib/core/widgets/poi_rating_badge.dart` does not exist.

- [ ] **Step 3: Implement the widget**

Create `lib/core/widgets/poi_rating_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';

class PoiRatingBadge extends StatelessWidget {
  final double? rating;
  final Color? textColor;

  const PoiRatingBadge({
    super.key,
    required this.rating,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = rating;
    if (value == null || value <= 0) {
      return Text(
        'Sin calificar',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: AppTypography.weightMedium,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 15),
        const SizedBox(width: 3),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/widgets/poi_rating_badge_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/poi_rating_badge.dart test/core/widgets/poi_rating_badge_test.dart
git commit -m "feat: add PoiRatingBadge widget"
```

---

### Task 3: Show rating in `PoiUnlockCard`

**Files:**
- Modify: `lib/features/map/presentation/widgets/poi_unlock_card.dart`
- Test: `test/features/map/presentation/widgets/poi_unlock_card_test.dart`

**Interfaces:**
- Consumes: `PoiRatingBadge({required double? rating})` from Task 2; `PuntoDeInteres.calificacionPromedio` from Task 1.

- [ ] **Step 1: Write the failing test**

Create `test/features/map/presentation/widgets/poi_unlock_card_test.dart`:

```dart
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

    await tester.pumpWidget(
      MaterialApp(
        home: PoiUnlockCard(punto: punto, onClose: () {}),
      ),
    );

    // Let the unlock flip animation reach the point where the card is built.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('4.5'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/map/presentation/widgets/poi_unlock_card_test.dart`
Expected: FAIL — `find.text('4.5')` finds nothing (rating not rendered yet).

- [ ] **Step 3: Wire the badge into the card**

In `lib/features/map/presentation/widgets/poi_unlock_card.dart`, add the import near the top (after the existing relative imports):

```dart
import '../../../../core/widgets/poi_rating_badge.dart';
```

Then, inside `_buildCard()` (around line 493), insert the badge right after `_buildRarityRow(punto.rarity, widget.pointsEarned)`:

```dart
                  const SizedBox(height: 10),
                  _buildRarityRow(punto.rarity, widget.pointsEarned),
                  const SizedBox(height: 8),
                  PoiRatingBadge(rating: punto.calificacionPromedio),
                  if (punto.descripcion != null && punto.descripcion!.isNotEmpty) ...[
```

(This replaces the existing `_buildRarityRow(...)` line and the line right after it, adding one `SizedBox` and the badge in between — the rest of the block, starting at `if (punto.descripcion...`, is unchanged.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/map/presentation/widgets/poi_unlock_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/map/presentation/widgets/poi_unlock_card.dart test/features/map/presentation/widgets/poi_unlock_card_test.dart
git commit -m "feat: show rating badge on POI unlock card"
```

---

### Task 4: Show rating in `PoiDetailView` (basic, important, legendary variants)

**Files:**
- Modify: `lib/features/home/presentation/screens/poi_detail_view.dart`
- Test: `test/features/home/presentation/screens/poi_detail_view_test.dart`

**Interfaces:**
- Consumes: `PoiRatingBadge({required double? rating, Color? textColor})` from Task 2; `PuntoDeInteres.calificacionPromedio` from Task 1.

- [ ] **Step 1: Write the failing tests**

Create `test/features/home/presentation/screens/poi_detail_view_test.dart`:

```dart
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
    });

    testWidgets('shows the rating on the legendary card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'legendary', calificacion: 5.0)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5.0'), findsOneWidget);
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/home/presentation/screens/poi_detail_view_test.dart`
Expected: FAIL — none of the rating texts are found (badge not wired in yet).

- [ ] **Step 3: Wire the badge into the three unlocked card variants**

In `lib/features/home/presentation/screens/poi_detail_view.dart`, add the import near the top (after the existing relative imports):

```dart
import '../../../../core/widgets/poi_rating_badge.dart';
```

**Basic card** — inside `_basicCard()`, replace the trailing category `Text` block (around line 349-356) with the category text followed by the badge:

```dart
                    const SizedBox(height: 4),
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color: Color(0xFF6A7587),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PoiRatingBadge(rating: widget.punto.calificacionPromedio),
```

**Important (epic) card** — inside `_importantCard()`, replace the trailing category `Text` block (around line 467-474) with:

```dart
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PoiRatingBadge(
                    rating: widget.punto.calificacionPromedio,
                    textColor: Colors.white,
                  ),
```

**Legendary card** — inside `_legendaryInfoOverlay()`, replace the trailing category `Text` block (around line 732-740) with:

```dart
              const SizedBox(height: 5),
              Text(
                widget.categoryName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              PoiRatingBadge(
                rating: widget.punto.calificacionPromedio,
                textColor: Colors.white,
              ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/home/presentation/screens/poi_detail_view_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: All tests pass (Tasks 1-4 combined).

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/screens/poi_detail_view.dart test/features/home/presentation/screens/poi_detail_view_test.dart
git commit -m "feat: show rating badge on POI detail view unlocked cards"
```
