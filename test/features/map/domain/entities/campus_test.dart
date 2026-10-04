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
    test('maps the known campus keys of the database to readable names', () {
      expect(Campus.humanNombre('minas'), 'Minas');
      expect(Campus.humanNombre('volador'), 'El Volador');
      expect(Campus.humanNombre('rio'), 'El Río');
      expect(Campus.humanNombre('rio_de_janeiro'), 'Instituto Benjamin Constant');
    });

    test('title-cases unknown keys instead of showing raw snake_case', () {
      expect(Campus.humanNombre('nuevo_campus'), 'Nuevo Campus');
    });

    test('distinct returns each campus once, sorted by display name', () {
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
        ['rio', 'volador', 'rio_de_janeiro', 'minas'],
      );
    });

    test('filter keeps only the selected campus, or everything when null', () {
      final puntos = [_p(1, 'minas'), _p(2, 'volador'), _p(3, 'minas')];

      expect(Campus.filter(puntos, null), hasLength(3));
      expect(Campus.filter(puntos, 'minas').map((p) => p.id), [1, 3]);
      expect(Campus.filter(puntos, 'rio'), isEmpty);
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
      ];

      expect(Categoria.fromPuntos(Campus.filter(all, 'minas')).map((c) => c.key),
          ['academico']);
      expect(Categoria.fromPuntos(all), hasLength(2));
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
      selection.select('minas');
      selection.select(null);
      selection.clear();

      expect(notified, 2);
      expect(selection.selected, isNull);
    });
  });
}
