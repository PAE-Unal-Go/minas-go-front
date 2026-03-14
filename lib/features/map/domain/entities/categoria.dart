class Categoria {
  final String key;       // e.g. "arte_cultura"
  final String nombre;    // e.g. "Arte y Cultura"
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

  /// Maps DB enum-style keys like "arte_cultura" to human-readable names.
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
