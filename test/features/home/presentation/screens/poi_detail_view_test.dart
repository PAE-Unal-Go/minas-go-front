import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/home/presentation/screens/poi_detail_view.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';

class FakeMapRepository implements MapRepository {
  final PuntoDeInteres Function(int id) onGetPuntoById;
  final List<int> rated = [];
  Object? rateError;

  FakeMapRepository(this.onGetPuntoById);

  @override
  Future<void> ratePoi(String userId, int puntoId, int calificacion) async {
    if (rateError != null) throw rateError!;
    rated.add(calificacion);
  }

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
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) =>
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

PuntoDeInteres _punto({required String rarity, int? calificacion}) =>
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
      miCalificacion: calificacion,
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
    testWidgets('shows the rating of the user on the basic (singular) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'singular', calificacion: 4)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4.0'), findsOneWidget);
    });

    testWidgets('shows the rating of the user on the important (epic) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'epic', calificacion: 3)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3.0'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows the rating of the user on the legendary card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'legendary', calificacion: 5)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5.0'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
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
        miCalificacion: 5,
      );

      await tester.pumpWidget(_wrap(locked));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5.0'), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      expect(find.text('Sin calificar'), findsNothing);
    });
  });

  group('PoiDetailView pull-to-refresh', () {
    testWidgets('refreshing re-fetches the punto and shows the new rating',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3);
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
        miCalificacion: 5,
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

      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('keeps showing old data when the refresh fails',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3);
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

  group('PoiDetailView rating input', () {
    Widget wrapRate(PuntoDeInteres punto, FakeMapRepository repo,
            {ValueChanged<PuntoDeInteres>? onChanged}) =>
        MaterialApp(
          home: PoiDetailView(
            punto: punto,
            categoryName: 'Histórico',
            pointName: punto.nombre,
            pointDescription: punto.descripcion ?? '',
            repository: repo,
            userId: 'user-1',
            onPuntoChanged: onChanged,
          ),
        );

    testWidgets('an unrated unlocked point can be rated and shows the value',
        (tester) async {
      final repo = FakeMapRepository((_) => throw UnimplementedError());
      PuntoDeInteres? changed;
      await tester.pumpWidget(wrapRate(
          _punto(rarity: 'singular'), repo,
          onChanged: (p) => changed = p));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sin calificar'), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));

      await tester.tap(find.byKey(const ValueKey('rate-star-4')));
      await tester.pump();
      await tester.pump();

      expect(repo.rated, [4]);
      expect(changed?.miCalificacion, 4);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('Sin calificar'), findsNothing);
      expect(find.text('Tu calificación'), findsOneWidget);
    });

    testWidgets('an existing rating can be changed', (tester) async {
      final repo = FakeMapRepository((_) => throw UnimplementedError());
      await tester.pumpWidget(
          wrapRate(_punto(rarity: 'singular', calificacion: 2), repo));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const ValueKey('rate-star-5')));
      await tester.pump();
      await tester.pump();

      expect(repo.rated, [5]);
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('failed save reverts the stars and shows an error',
        (tester) async {
      final repo = FakeMapRepository((_) => throw UnimplementedError())
        ..rateError = Exception('network');
      await tester.pumpWidget(wrapRate(_punto(rarity: 'singular'), repo));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const ValueKey('rate-star-3')));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se pudo guardar tu calificación'), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
      expect(find.text('Sin calificar'), findsOneWidget);
    });

    testWidgets('locked points cannot be rated', (tester) async {
      final repo = FakeMapRepository((_) => throw UnimplementedError());
      const locked = PuntoDeInteres(
        id: 2,
        nombre: 'Zona Oculta',
        categoria: 'historico',
        campus: 'El Volador',
        universidad: 'UNAL Medellín',
        latitud: 6.25,
        longitud: -75.57,
      );
      await tester.pumpWidget(wrapRate(locked, repo));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('rate-star-1')), findsNothing);
    });
  });
}
