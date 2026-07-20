# POI Detail Pull-to-Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user pull-to-refresh on `PoiDetailView` to re-fetch a single punto's current data from `puntos_de_interes` (fixing stale `calificacion_promedio` and other fields cached since app startup), without reloading the whole app's point list.

**Architecture:** Add `MapRepository.getPuntoById(int id)` (single-row Supabase select). `PoiDetailView` keeps a mutable `_punto` in its State (seeded from `widget.punto`), wraps its scrollable body in a standard `RefreshIndicator`, and replaces `_punto` wholesale on refresh. `PoiDetailView` gains an optional injectable `repository` constructor parameter so the refresh call is testable without hitting a real Supabase backend.

**Tech Stack:** Flutter/Dart, `supabase_flutter`, `flutter_test`.

## Global Constraints

- `getPuntoById` always returns `visitado: true` — this view is only reachable for already-unlocked points (locked tiles aren't tappable; see `category_points_view.dart`'s `_PointGridTile.onTap`, and `PoiUnlockCard` navigates here right after unlocking).
- Refresh re-fetches the full row (nombre, descripcion, images_urls, rarity, calificacion_promedio) — not just the rating.
- On refresh failure, fail silently: keep showing previously loaded data, no error UI (a background refresh shouldn't interrupt the user).
- No changes to `CategoryPointsView` or any other screen — this is scoped to `PoiDetailView` only.

---

### Task 1: Add `getPuntoById` to `MapRepository`

**Files:**
- Modify: `lib/features/map/domain/repositories/map_repository.dart`
- Modify: `lib/features/map/data/repositories/map_repository_impl.dart`

**Interfaces:**
- Produces: `MapRepository.getPuntoById(int id)` → `Future<PuntoDeInteres>`, implemented by `MapRepositoryImpl`.

- [ ] **Step 1: Add the method to the abstract repository**

Edit `lib/features/map/domain/repositories/map_repository.dart`, add after `getPuntosConVisita`:

```dart
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId);

  /// Refetches a single punto de interés by id (used for pull-to-refresh on
  /// the detail view). Always returns visitado = true, since this is only
  /// called for points the user has already unlocked.
  Future<PuntoDeInteres> getPuntoById(int id);

  Future<List<Categoria>> getCategorias(String? userId);
```

(Only the `getPuntoById` block is new; `getPuntosConVisita` and `getCategorias` already exist and are shown here only to anchor the insertion point.)

- [ ] **Step 2: Implement it in `MapRepositoryImpl`**

Edit `lib/features/map/data/repositories/map_repository_impl.dart`, add this method right after `getPuntosConVisita` (after its closing `}` around line 134):

```dart
  @override
  Future<PuntoDeInteres> getPuntoById(int id) async {
    try {
      final res = await _supabase
          .from('puntos_de_interes')
          .select()
          .eq('id', id)
          .single();
      final map = Map<String, dynamic>.from(res);
      map['visitado'] = true;
      return PuntoDeInteres.fromMap(map);
    } catch (e) {
      return Future.error('Error fetching punto by id: $e');
    }
  }
```

- [ ] **Step 3: Verify it compiles and the existing suite still passes**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all existing tests still pass (no behavior change to existing code paths).

- [ ] **Step 4: Commit**

```bash
git add lib/features/map/domain/repositories/map_repository.dart lib/features/map/data/repositories/map_repository_impl.dart
git commit -m "feat: add getPuntoById to MapRepository for single-point refresh"
```

---

### Task 2: Add pull-to-refresh to `PoiDetailView`

**Files:**
- Modify: `lib/features/home/presentation/screens/poi_detail_view.dart`
- Test: `test/features/home/presentation/screens/poi_detail_view_test.dart` (existing file — new tests added to it)

**Interfaces:**
- Consumes: `MapRepository.getPuntoById(int id)` from Task 1.
- Produces: `PoiDetailView({..., MapRepository? repository})` — new optional constructor parameter, defaults to `MapRepositoryImpl()` when omitted, so all existing call sites (`category_points_view.dart`, `poi_unlock_card.dart`) keep working unchanged.

- [ ] **Step 1: Write the failing tests**

Open `test/features/home/presentation/screens/poi_detail_view_test.dart` (created in the previous plan) and add a `FakeMapRepository` plus two new tests. Insert the following near the top, after the existing imports:

```dart
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';

class FakeMapRepository implements MapRepository {
  final PuntoDeInteres Function(int id) onGetPuntoById;

  FakeMapRepository(this.onGetPuntoById);

  @override
  Future<PuntoDeInteres> getPuntoById(int id) async => onGetPuntoById(id);

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
  Future<int> unlockPoi(String userId, int puntoId) =>
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
```

Then add these tests inside the existing `main()`, as a new `group`:

```dart
  group('PoiDetailView pull-to-refresh', () {
    testWidgets('refreshing re-fetches the punto and shows the new rating',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3.0);
      final refreshed = PuntoDeInteres(
        id: original.id,
        nombre: original.nombre,
        descripcion: original.descripcion,
        categoria: original.categoria,
        campus: original.campus,
        universidad: original.universidad,
        latitud: original.latitud,
        longitud: original.longitud,
        visitado: true,
        rarity: original.rarity,
        calificacionPromedio: 4.8,
      );

      final fakeRepo = FakeMapRepository((id) => refreshed);

      await tester.pumpWidget(
        MaterialApp(
          home: PoiDetailView(
            punto: original,
            categoryName: 'Histórico',
            pointName: original.nombre,
            pointDescription: original.descripcion ?? '',
            repository: fakeRepo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3.0'), findsOneWidget);

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('keeps showing old data when the refresh fails',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3.0);
      final fakeRepo = FakeMapRepository((id) => throw Exception('network'));

      await tester.pumpWidget(
        MaterialApp(
          home: PoiDetailView(
            punto: original,
            categoryName: 'Histórico',
            pointName: original.nombre,
            pointDescription: original.descripcion ?? '',
            repository: fakeRepo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('3.0'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/home/presentation/screens/poi_detail_view_test.dart`
Expected: FAIL — `PoiDetailView` has no `repository` constructor parameter yet (compile error), and the fake repository's response is never consulted.

- [ ] **Step 3: Add the injectable repository and mutable `_punto` state**

In `lib/features/home/presentation/screens/poi_detail_view.dart`, add imports after the existing ones (after line 11, `import '../../../map/domain/entities/punto_de_interes.dart';`):

```dart
import '../../../map/data/repositories/map_repository_impl.dart';
import '../../../map/domain/repositories/map_repository.dart';
```

Update the widget class (replace lines 13-27):

```dart
class PoiDetailView extends StatefulWidget {
  final PuntoDeInteres punto;
  final String categoryName;
  final String pointName;
  final String pointDescription;
  final List<String> imagesUrls;
  final MapRepository? repository;

  const PoiDetailView({
    super.key,
    required this.punto,
    required this.categoryName,
    required this.pointName,
    required this.pointDescription,
    this.imagesUrls = const [],
    this.repository,
  });

  @override
  State<PoiDetailView> createState() => _PoiDetailViewState();
}
```

Update the State class fields and getters (replace lines 33-64):

```dart
class _PoiDetailViewState extends State<PoiDetailView>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late final AnimationController _anim;
  late final AnimationController _shimmerOpacity;
  late final MapRepository _repo = widget.repository ?? MapRepositoryImpl();
  late PuntoDeInteres _punto;

  String? get _rarity => _punto.visitado ? _punto.rarity : null;

  bool get _isVisitado => _punto.visitado;

  String get _displayName {
    return widget.pointName.trim().isNotEmpty
        ? widget.pointName
        : _punto.nombre;
  }

  String? get _displayDescription {
    if (!_isVisitado) return null;
    if (widget.pointDescription.trim().isNotEmpty) {
      return widget.pointDescription;
    }
    return _punto.descripcion;
  }

  List<String> get _images {
    final merged = [...widget.imagesUrls, ..._punto.imagesUrls]
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
    return merged;
  }
```

Set `_punto` in `initState` — update the start of `initState` (replace line 66-68):

```dart
  @override
  void initState() {
    super.initState();
    _punto = widget.punto;
    _anim = AnimationController(
```

- [ ] **Step 4: Replace the remaining `widget.punto` references with `_punto`**

Three more spots reference `widget.punto` directly in card builders:

In `_buildCard()` (around line 203), replace:

```dart
  Widget _buildCard() {
    if (!widget.punto.visitado) {
      return _lockedCard();
    }
```

with:

```dart
  Widget _buildCard() {
    if (!_punto.visitado) {
      return _lockedCard();
    }
```

In `_basicCard()` (around line 359), replace:

```dart
                    PoiRatingBadge(rating: widget.punto.calificacionPromedio),
```

with:

```dart
                    PoiRatingBadge(rating: _punto.calificacionPromedio),
```

In `_importantCard()` (around line 480), replace:

```dart
                  PoiRatingBadge(
                    rating: widget.punto.calificacionPromedio,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Animated gold border wrapper
```

with:

```dart
                  PoiRatingBadge(
                    rating: _punto.calificacionPromedio,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Animated gold border wrapper
```

In `_legendaryInfoOverlay()` (around line 751), replace:

```dart
              PoiRatingBadge(
                rating: widget.punto.calificacionPromedio,
                textColor: Colors.white,
              ),
```

with:

```dart
              PoiRatingBadge(
                rating: _punto.calificacionPromedio,
                textColor: Colors.white,
              ),
```

- [ ] **Step 5: Wrap the scroll body in a `RefreshIndicator` and add `_onRefresh`**

Replace the `Expanded` block inside `build()` (lines 141-155):

```dart
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, topContentPadding, 20, 80),
                    child: Column(
                      children: [
                        _buildCard(),
                        if (_displayDescription != null &&
                            _displayDescription!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDescriptionBox(_displayDescription!),
                        ],
                      ],
                    ),
                  ),
                ),
```

with:

```dart
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          EdgeInsets.fromLTRB(20, topContentPadding, 20, 80),
                      child: Column(
                        children: [
                          _buildCard(),
                          if (_displayDescription != null &&
                              _displayDescription!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildDescriptionBox(_displayDescription!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
```

Then add the `_onRefresh` method right after `dispose()` (after line 102, before `@override Widget build`):

```dart
  Future<void> _onRefresh() async {
    try {
      final fresh = await _repo.getPuntoById(_punto.id);
      if (!mounted) return;
      setState(() => _punto = fresh);
    } catch (_) {
      // Silently keep showing the previously loaded data; the pull-to-refresh
      // spinner simply stops. No error UI needed for a background refresh.
    }
  }
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/home/presentation/screens/poi_detail_view_test.dart`
Expected: PASS (7 tests — the 5 existing rating-badge tests plus the 2 new pull-to-refresh tests).

- [ ] **Step 7: Run the full test suite and analyzer**

Run: `flutter test`
Expected: all tests pass.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/home/presentation/screens/poi_detail_view.dart test/features/home/presentation/screens/poi_detail_view_test.dart
git commit -m "feat: add pull-to-refresh to POI detail view"
```
