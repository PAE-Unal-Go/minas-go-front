class PuntoDeInteres {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? mainImageUrl;
  final String categoria;
  final String campus;
  final String universidad;
  final double latitud;
  final double longitud;
  final bool visitado;

  const PuntoDeInteres({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.mainImageUrl,
    required this.categoria,
    required this.campus,
    required this.universidad,
    required this.latitud,
    required this.longitud,
    this.visitado = false,
  });

  factory PuntoDeInteres.fromMap(Map<String, dynamic> map) {
    return PuntoDeInteres(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      mainImageUrl: map['main_image_url'] as String?,
      categoria: map['categoria'] as String,
      campus: map['campus'] as String,
      universidad: map['universidad'] as String? ?? 'UNAL Medellín',
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      visitado: map['visitado'] as bool? ?? false,
    );
  }
}
