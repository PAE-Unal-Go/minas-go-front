import 'punto_de_interes.dart';

class Categoria {
  final String key;
  final String nombre;
  final String? imageUrl;
  final int totalPuntos;
  final int visitados;

  const Categoria({
    required this.key,
    required this.nombre,
    this.imageUrl,
    required this.totalPuntos,
    required this.visitados,
  });

  /// Groups [puntos] by category, sorted by name.
  static List<Categoria> fromPuntos(Iterable<PuntoDeInteres> puntos) {
    final grouped = <String, List<PuntoDeInteres>>{};
    for (final p in puntos) {
      grouped.putIfAbsent(p.categoria, () => []).add(p);
    }

    return grouped.entries.map((entry) {
      final list = entry.value;
      final imageUrl = list
          .expand((p) => p.imagesUrls)
          .map((url) => url.trim())
          .firstWhere((url) => url.isNotEmpty, orElse: () => '');

      return Categoria(
        key: entry.key,
        nombre: humanNombre(entry.key),
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        totalPuntos: list.length,
        visitados: list.where((p) => p.visitado).length,
      );
    }).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  static String humanNombre(String key) {
    const map = {
      'arte_cultura': 'Arte y Cultura',
      'deporte_salud': 'Deporte y Salud',
      'museos_laboratorios': 'Museos y Laboratorios',
      'academico': 'Académico',
      'medio_ambiente': 'Medio Ambiente',
      'servicios': 'Servicios',
    };
    return map[key] ?? key;
  }
}
