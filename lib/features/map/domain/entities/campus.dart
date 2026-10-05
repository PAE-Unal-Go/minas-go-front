import 'punto_de_interes.dart';

/// Helpers for the `campus` column of `puntos_de_interes`.
///
/// DB keys are grouped into the two campuses shown in the UI:
/// - [unalMedellin] → minas, volador, rio
/// - [benjaminConstant] → rio_de_janeiro
abstract final class Campus {
  static const unalMedellin = 'unal_medellin';
  static const benjaminConstant = 'rio_de_janeiro';

  static const _groupKeys = {
    unalMedellin: ['minas', 'volador', 'rio'],
    benjaminConstant: ['rio_de_janeiro'],
  };

  static const _names = {
    unalMedellin: 'Universidad Nacional de Colombia (Medellín)',
    benjaminConstant: 'Instituto Benjamin Constant',
  };

  /// Group id for a raw DB campus key (or the key itself if unknown).
  static String groupOf(String campusKey) {
    final key = campusKey.trim();
    if (_groupKeys.containsKey(key)) return key;
    for (final entry in _groupKeys.entries) {
      if (entry.value.contains(key)) return entry.key;
    }
    return key;
  }

  /// Human readable name for a campus / group key.
  static String humanNombre(String key) {
    final group = groupOf(key);
    final known = _names[group];
    if (known != null) return known;
    return key
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Distinct campus groups present in [puntos] (UNAL first).
  static List<String> distinct(Iterable<PuntoDeInteres> puntos) {
    final groups = <String>{
      for (final p in puntos)
        if (p.campus.trim().isNotEmpty) groupOf(p.campus),
    };
    const preferred = [unalMedellin, benjaminConstant];
    final ordered = [
      for (final g in preferred)
        if (groups.contains(g)) g,
    ];
    final extras = groups.where((g) => !preferred.contains(g)).toList()
      ..sort((a, b) => humanNombre(a).compareTo(humanNombre(b)));
    return [...ordered, ...extras];
  }

  /// Points of [selected] campus group, or all of them when it is null.
  static List<PuntoDeInteres> filter(
    List<PuntoDeInteres> puntos,
    String? selected,
  ) {
    if (selected == null) return puntos;
    final group = groupOf(selected);
    final keys = _groupKeys[group] ?? [selected];
    return puntos.where((p) => keys.contains(p.campus)).toList();
  }
}
