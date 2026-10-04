import 'punto_de_interes.dart';

/// Helpers for the `campus` column of `puntos_de_interes`.
abstract final class Campus {
  static const _names = {
    'minas': 'Minas',
    'volador': 'El Volador',
    'rio': 'El Río',
    'rio_de_janeiro': 'Instituto Benjamin Constant',
  };

  /// Human readable name for a campus key; unknown keys are title-cased.
  static String humanNombre(String key) {
    final known = _names[key];
    if (known != null) return known;
    return key
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Distinct campus keys present in [puntos], sorted by display name.
  static List<String> distinct(Iterable<PuntoDeInteres> puntos) {
    final keys = <String>{
      for (final p in puntos)
        if (p.campus.trim().isNotEmpty) p.campus,
    };
    return keys.toList()
      ..sort((a, b) => humanNombre(a).compareTo(humanNombre(b)));
  }

  /// Points of [selected] campus, or all of them when it is null.
  static List<PuntoDeInteres> filter(
    List<PuntoDeInteres> puntos,
    String? selected,
  ) {
    if (selected == null) return puntos;
    return puntos.where((p) => p.campus == selected).toList();
  }
}
