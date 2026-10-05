import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/core/services/campus_selection.dart';
import 'package:minasgo_frontend/features/map/domain/entities/campus.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';

PuntoDeInteres _p(
  int id,
  String campus, {
  String categoria = 'academico',
  bool visitado = false,
  List<String> images = const [],
}) =>
    PuntoDeInteres(
      id: id,
      nombre: 'P$id',
      categoria: categoria,
      campus: campus,
      universidad: 'unal_medellin',
      latitud: 6.2,
      longitud: -75.5,
      visitado: visitado,
      imagesUrls: images,
    );

void main() {
  group('Campus', () {
    test('maps DB keys and groups to the two display campuses', () {
      expect(
        Campus.humanNombre('minas'),
        'Universidad Nacional de Colombia (Medellín)',
      );
      expect(
        Campus.humanNombre('volador'),
        'Universidad Nacional de Colombia (Medellín)',
      );
      expect(
        Campus.humanNombre('rio'),
        'Universidad Nacional de Colombia (Medellín)',
      );
      expect(
        Campus.humanNombre(Campus.unalMedellin),
        'Universidad Nacional de Colombia (Medellín)',
      );
      expect(
        Campus.humanNombre('rio_de_janeiro'),
        'Instituto Benjamin Constant',
      );
    });

    test('title-cases unknown keys instead of showing raw snake_case', () {
      expect(Campus.humanNombre('nuevo_campus'), 'Nuevo Campus');
    });

    test('groupOf maps raw keys into UI campus groups', () {
      expect(Campus.groupOf('minas'), Campus.unalMedellin);
      expect(Campus.groupOf('volador'), Campus.unalMedellin);
      expect(Campus.groupOf('rio'), Campus.unalMedellin);
      expect(Campus.groupOf('rio_de_janeiro'), Campus.benjaminConstant);
    });

    test('distinct returns the two campus groups, UNAL first', () {
      final puntos = [
        _p(1, 'volador'),
        _p(2, 'minas'),
        _p(3, 'volador'),
        _p(4, 'rio_de_janeiro'),
        _p(5, 'rio'),
        _p(6, '  '),
      ];

      expect(
        Campus.distinct(puntos),
        [Campus.unalMedellin, Campus.benjaminConstant],
      );
    });

    test('filter keeps all UNAL Medellín campuses when that group is selected',
        () {
      final puntos = [
        _p(1, 'minas'),
        _p(2, 'volador'),
        _p(3, 'rio'),
        _p(4, 'rio_de_janeiro'),
      ];

      expect(Campus.filter(puntos, null), hasLength(4));
      expect(
        Campus.filter(puntos, Campus.unalMedellin).map((p) => p.id),
        [1, 2, 3],
      );
      expect(
        Campus.filter(puntos, 'minas').map((p) => p.id),
        [1, 2, 3],
      );
      expect(
        Campus.filter(puntos, Campus.benjaminConstant).map((p) => p.id),
        [4],
      );
    });
  });

  group('Categoria.fromPuntos', () {
    test('counts total and visited points per category', () {
      final cats = Categoria.fromPuntos([
        _p(1, 'minas', categoria: 'academico', visitado: true),
        _p(2, 'minas', categoria: 'academico'),
        _p(3, 'minas', categoria: 'servicios'),
      ]);

      final academico = cats.firstWhere((c) => c.key == 'academico');
      expect(academico.totalPuntos, 2);
      expect(academico.visitados, 1);
      expect(cats.firstWhere((c) => c.key == 'servicios').totalPuntos, 1);
    });

    test('changes when the campus filter changes', () {
      final all = [
        _p(1, 'minas', categoria: 'academico'),
        _p(2, 'volador', categoria: 'servicios'),
        _p(3, 'rio_de_janeiro', categoria: 'arte_cultura'),
      ];

      expect(
        Categoria.fromPuntos(Campus.filter(all, Campus.unalMedellin))
            .map((c) => c.key),
        ['academico', 'servicios'],
      );
      expect(Categoria.fromPuntos(all), hasLength(3));
    });

    test('uses the first non-empty image as category image', () {
      final cats = Categoria.fromPuntos([
        _p(1, 'minas', images: const ['', '  ']),
        _p(2, 'minas', images: const ['https://x/y.jpg']),
      ]);
      expect(cats.single.imageUrl, 'https://x/y.jpg');
    });

    test('is empty for no points', () {
      expect(Categoria.fromPuntos(const []), isEmpty);
    });
  });

  group('CampusSelection', () {
    test('notifies only when the selection really changes', () {
      final selection = CampusSelection.test();
      var notified = 0;
      selection.addListener(() => notified++);

      selection.select('minas');
      selection.select(Campus.unalMedellin);
      selection.select(null);
      selection.clear();

      expect(notified, 2);
      expect(selection.selected, isNull);
    });

    test('normalizes raw campus keys to their group', () {
      final selection = CampusSelection.test();
      selection.select('volador');
      expect(selection.selected, Campus.unalMedellin);
    });
  });
}
