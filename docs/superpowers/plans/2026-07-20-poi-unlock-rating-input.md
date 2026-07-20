# POI Unlock Rating Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user pick an optional 1-5 star rating in `PoiBottomSheet` before unlocking a point, and thread that value through to the `registrar_visita` RPC as `p_calificacion`.

**Architecture:** Add an `int? calificacion` parameter end-to-end through the existing unlock pipeline: `PoiBottomSheet` (UI + local selection state) → `MapScreen._handleUnlock` → `UnlockPoi` usecase → `MapRepository.unlockPoi` → `MapRepositoryImpl.unlockPoi` (adds `p_calificacion` to the RPC params). No new backend function — `registrar_visita` already accepts the parameter.

**Tech Stack:** Flutter/Dart, `supabase_flutter`, `flutter_test`.

## Global Constraints

- Rating is optional: the user can unlock without selecting a star (`calificacion` stays `null`, matches `registrar_visita`'s own `IF p_calificacion IS NOT NULL AND (...)` guard).
- Only wired into the unlock flow (`PoiBottomSheet`). Not added to `PoiDetailView` or `PoiUnlockCard` — rating an already-visited point is out of scope (see the design spec: `registrar_visita` can't update an existing `visitas` row).
- Prompt copy above the star selector: "¿Deseas calificar este punto? Esto le ayudará a otros usuarios a decidir si visitarlo" — shown only when `!isVisitado && _inRange` (i.e., exactly where the "Desbloquear" button is already shown).
- Tapping an already-selected star deselects it (back to `null`), so the user can undo their pick without a separate "skip" button.

---

### Task 1: Thread `calificacion` through `UnlockPoi` and `MapRepository`

**Files:**
- Modify: `lib/features/map/domain/usecases/unlock_poi.dart`
- Modify: `lib/features/map/domain/repositories/map_repository.dart`
- Modify: `lib/features/map/data/repositories/map_repository_impl.dart`
- Test: `test/features/map/domain/usecases/unlock_poi_test.dart`

**Interfaces:**
- Produces: `UnlockPoi.call(String userId, int puntoId, {int? calificacion})` → `Future<int>`; `MapRepository.unlockPoi(String userId, int puntoId, {int? calificacion})` → `Future<int>`.

- [ ] **Step 1: Write the failing test**

Create `test/features/map/domain/usecases/unlock_poi_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';
import 'package:minasgo_frontend/features/map/domain/usecases/unlock_poi.dart';

class FakeMapRepository implements MapRepository {
  String? capturedUserId;
  int? capturedPuntoId;
  int? capturedCalificacion;
  final int pointsToReturn;

  FakeMapRepository({this.pointsToReturn = 10});

  @override
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) async {
    capturedUserId = userId;
    capturedPuntoId = puntoId;
    capturedCalificacion = calificacion;
    return pointsToReturn;
  }

  @override
  Future<PuntoDeInteres> getPuntoById(int id) => throw UnimplementedError();

  @override
  Future<LocationPoint> getCurrentLocation() => throw UnimplementedError();

  @override
  Future<String> getPoisGeoJson() => throw UnimplementedError();

  @override
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId) =>
      throw UnimplementedError();

  @override
  Future<List<Categoria>> getCategorias(String? userId) =>
      throw UnimplementedError();

  @override
  Future<QuizQuestion?> getQuestionForVisitedPoints(String userId) =>
      throw UnimplementedError();

  @override
  Future<AnswerValidationResult> validateAnswer({
    required String userId,
    required int preguntaId,
    required int selectedIndex,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> getUserTotalPoints(String userId) => throw UnimplementedError();
}

void main() {
  group('UnlockPoi', () {
    test('passes the calificacion through to the repository', () async {
      final repo = FakeMapRepository(pointsToReturn: 25);
      final unlockPoi = UnlockPoi(repo);

      final points = await unlockPoi('user-1', 42, calificacion: 4);

      expect(points, 25);
      expect(repo.capturedUserId, 'user-1');
      expect(repo.capturedPuntoId, 42);
      expect(repo.capturedCalificacion, 4);
    });

    test('defaults calificacion to null when not provided', () async {
      final repo = FakeMapRepository();
      final unlockPoi = UnlockPoi(repo);

      await unlockPoi('user-1', 42);

      expect(repo.capturedCalificacion, isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/map/domain/usecases/unlock_poi_test.dart`
Expected: FAIL — compile error, `unlockPoi` (both the abstract method and `UnlockPoi.call`) don't accept a `calificacion` named parameter yet.

- [ ] **Step 3: Update `MapRepository`**

Edit `lib/features/map/domain/repositories/map_repository.dart`, replace:

```dart
  /// RPC: registrar_visita(p_usuario, p_punto)
  /// Registers the visit and returns points earned from the unlock.
  Future<int> unlockPoi(String userId, int puntoId);
```

with:

```dart
  /// RPC: registrar_visita(p_usuario, p_punto, p_calificacion)
  /// Registers the visit and returns points earned from the unlock.
  /// calificacion is an optional 1-5 rating for the point (nullable).
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion});
```

- [ ] **Step 4: Update `MapRepositoryImpl`**

Edit `lib/features/map/data/repositories/map_repository_impl.dart`, replace:

```dart
  @override
  Future<int> unlockPoi(String userId, int puntoId) async {
    try {
      final res = await _supabase.rpc(
        'registrar_visita',
        params: {
          'p_usuario': userId,
          'p_punto': puntoId,
        },
      );
```

with:

```dart
  @override
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) async {
    try {
      final res = await _supabase.rpc(
        'registrar_visita',
        params: {
          'p_usuario': userId,
          'p_punto': puntoId,
          'p_calificacion': calificacion,
        },
      );
```

- [ ] **Step 5: Update `UnlockPoi`**

Replace the full contents of `lib/features/map/domain/usecases/unlock_poi.dart`:

```dart
import '../repositories/map_repository.dart';

class UnlockPoi {
  final MapRepository repository;
  const UnlockPoi(this.repository);

  Future<int> call(String userId, int puntoId, {int? calificacion}) {
    return repository.unlockPoi(userId, puntoId, calificacion: calificacion);
  }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/features/map/domain/usecases/unlock_poi_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 7: Run the full suite and analyzer**

Run: `flutter test`
Expected: all tests pass.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/map/domain/usecases/unlock_poi.dart lib/features/map/domain/repositories/map_repository.dart lib/features/map/data/repositories/map_repository_impl.dart test/features/map/domain/usecases/unlock_poi_test.dart
git commit -m "feat: thread optional calificacion through the unlock pipeline"
```

---

### Task 2: Add the star rating selector to `PoiBottomSheet`

**Files:**
- Modify: `lib/features/map/presentation/widgets/poi_bottom_sheet.dart`
- Test: `test/features/map/presentation/widgets/poi_bottom_sheet_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1 directly (this task only changes `PoiBottomSheet`'s own callback signature).
- Produces: `PoiBottomSheet.onUnlock` becomes `Future<void> Function(int? calificacion)` — Task 3 (`MapScreen`) consumes this new signature.

- [ ] **Step 1: Write the failing tests**

Create `test/features/map/presentation/widgets/poi_bottom_sheet_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/map/presentation/widgets/poi_bottom_sheet_test.dart`
Expected: FAIL — compile error (`onUnlock` doesn't accept a parameter yet) and the rating prompt/stars don't exist.

- [ ] **Step 3: Update `PoiBottomSheet`'s callback signature and add local state**

Edit `lib/features/map/presentation/widgets/poi_bottom_sheet.dart`, replace:

```dart
class PoiBottomSheet extends StatefulWidget {
  final PuntoDeInteres punto;
  final double distanceMeters;
  final Future<void> Function() onUnlock;

  const PoiBottomSheet({
    super.key,
    required this.punto,
    required this.distanceMeters,
    required this.onUnlock,
  });

  @override
  State<PoiBottomSheet> createState() => _PoiBottomSheetState();
}

class _PoiBottomSheetState extends State<PoiBottomSheet> {
  bool _isUnlocking = false;

  bool get _inRange => widget.distanceMeters <= proximityThresholdMeters;

  String _formatDistance(double meters) {
    if (meters == double.infinity) return '— m';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _triggerUnlock() async {
    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);
    await widget.onUnlock();
    if (mounted) setState(() => _isUnlocking = false);
  }
```

with:

```dart
class PoiBottomSheet extends StatefulWidget {
  final PuntoDeInteres punto;
  final double distanceMeters;
  final Future<void> Function(int? calificacion) onUnlock;

  const PoiBottomSheet({
    super.key,
    required this.punto,
    required this.distanceMeters,
    required this.onUnlock,
  });

  @override
  State<PoiBottomSheet> createState() => _PoiBottomSheetState();
}

class _PoiBottomSheetState extends State<PoiBottomSheet> {
  bool _isUnlocking = false;
  int? _selectedRating;

  bool get _inRange => widget.distanceMeters <= proximityThresholdMeters;

  String _formatDistance(double meters) {
    if (meters == double.infinity) return '— m';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _onRatingChanged(int? rating) {
    setState(() => _selectedRating = rating);
  }

  Future<void> _triggerUnlock() async {
    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);
    await widget.onUnlock(_selectedRating);
    if (mounted) setState(() => _isUnlocking = false);
  }
```

- [ ] **Step 4: Render the rating prompt above the unlock button**

In the same file, replace:

```dart
                // ── Action button ──
                if (!isVisitado)
                  _UnlockButton(
                    inRange: _inRange,
                    isUnlocking: _isUnlocking,
                    onUnlock: _triggerUnlock,
                  )
```

with:

```dart
                // ── Rating prompt (optional, only while unlockable) ──
                if (!isVisitado && _inRange) ...[
                  const Text(
                    '¿Deseas calificar este punto? Esto le ayudará a otros '
                    'usuarios a decidir si visitarlo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RatingSelector(
                    selected: _selectedRating,
                    onChanged: _onRatingChanged,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Action button ──
                if (!isVisitado)
                  _UnlockButton(
                    inRange: _inRange,
                    isUnlocking: _isUnlocking,
                    onUnlock: _triggerUnlock,
                  )
```

- [ ] **Step 5: Add the `_RatingSelector` widget**

In the same file, add this new widget in the "Sub-widgets" section, right after the `_PoiImageSection` class (after its closing `}`, before `class _PoiMetaRow`):

```dart
class _RatingSelector extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;

  const _RatingSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = selected != null && starValue <= selected!;
        return IconButton(
          onPressed: () {
            onChanged(filled && starValue == selected ? null : starValue);
          },
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.warning,
            size: 28,
          ),
          splashRadius: 22,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }),
    );
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/map/presentation/widgets/poi_bottom_sheet_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 7: Run the full suite and analyzer**

Run: `flutter test`
Expected: all tests pass (compile errors in `map_screen.dart` are expected and fixed in Task 3 — if `flutter test` fails to compile due to `map_screen.dart`, that's normal at this point; only confirm the two new/changed test files pass in isolation as in Steps 2 and 6, and move on to Task 3 before doing a full-repo check).

- [ ] **Step 8: Commit**

```bash
git add lib/features/map/presentation/widgets/poi_bottom_sheet.dart test/features/map/presentation/widgets/poi_bottom_sheet_test.dart
git commit -m "feat: add optional star rating selector to PoiBottomSheet"
```

---

### Task 3: Wire the selected rating from `MapScreen` to the unlock call

**Files:**
- Modify: `lib/features/map/presentation/screens/map_screen.dart`

**Interfaces:**
- Consumes: `PoiBottomSheet.onUnlock` (`Future<void> Function(int? calificacion)`) from Task 2; `UnlockPoi.call(String, int, {int? calificacion})` from Task 1.

- [ ] **Step 1: Update `_showPoiBottomSheet` and `_handleUnlock`**

Edit `lib/features/map/presentation/screens/map_screen.dart`, replace:

```dart
  void _showPoiBottomSheet(PuntoDeInteres punto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PoiBottomSheet(
        punto: punto,
        distanceMeters: _distanceTo(punto),
        onUnlock: () => _handleUnlock(punto),
      ),
    );
  }

  Future<void> _handleUnlock(PuntoDeInteres punto) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (mounted) Navigator.of(context).pop();

    try {
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(duration: 500);
      }
      final pointsEarned = await _unlockPoi(userId, punto.id);
```

with:

```dart
  void _showPoiBottomSheet(PuntoDeInteres punto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PoiBottomSheet(
        punto: punto,
        distanceMeters: _distanceTo(punto),
        onUnlock: (calificacion) => _handleUnlock(punto, calificacion),
      ),
    );
  }

  Future<void> _handleUnlock(PuntoDeInteres punto, int? calificacion) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (mounted) Navigator.of(context).pop();

    try {
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(duration: 500);
      }
      final pointsEarned =
          await _unlockPoi(userId, punto.id, calificacion: calificacion);
```

- [ ] **Step 2: Run the full suite and analyzer**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (this is the first point where the full suite compiles cleanly end-to-end for this feature).

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/screens/map_screen.dart
git commit -m "feat: pass selected rating from PoiBottomSheet through to unlock"
```
