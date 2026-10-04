import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';
import 'package:minasgo_frontend/features/map/presentation/widgets/poi_unlock_card.dart';

class _Repo implements MapRepository {
  final List<(int, int)> rated = [];

  @override
  Future<void> ratePoi(String userId, int puntoId, int calificacion) async {
    rated.add((puntoId, calificacion));
  }

  @override
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) =>
      throw UnimplementedError();
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

const _punto = PuntoDeInteres(
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
);

Future<void> _pumpCard(
  WidgetTester tester,
  _Repo repo, {
  VoidCallback? onRated,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: PoiUnlockCard(
        punto: _punto,
        onClose: () {},
        repository: repo,
        userId: 'user-1',
        onRated: onRated,
      ),
    ),
  );

  // Let the unlock flip animation build the card.
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 900));
  // Flush the trailing 200ms delay in _runAnimation before the test ends.
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('PoiUnlockCard invites the user to rate right after unlocking',
      (tester) async {
    await _pumpCard(tester, _Repo());

    expect(find.text('¿Qué tal este lugar? Califícalo'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
  });

  testWidgets('tapping a star saves the rating and notifies the parent',
      (tester) async {
    final repo = _Repo();
    var notified = 0;
    await _pumpCard(tester, repo, onRated: () => notified++);

    await tester.tap(find.byKey(const ValueKey('rate-star-5')));
    await tester.pump();
    await tester.pump();

    expect(repo.rated, [(1, 5)]);
    expect(notified, 1);
    expect(find.text('Tu calificación'), findsOneWidget);
  });
}
