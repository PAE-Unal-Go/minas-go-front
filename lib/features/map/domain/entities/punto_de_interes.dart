class PuntoDeInteres {
  final int id;
  final String nombre;
  final String? descripcion;
  final List<String> imagesUrls;
  final String categoria;
  final String campus;
  final String universidad;
  final double latitud;
  final double longitud;
  final bool visitado;
  final String? rarity;

  const PuntoDeInteres({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagesUrls = const [],
    required this.categoria,
    required this.campus,
    required this.universidad,
    required this.latitud,
    required this.longitud,
    this.visitado = false,
    this.rarity,
  });

  String? get mainImageUrl => imagesUrls.isNotEmpty ? imagesUrls.first : null;

  factory PuntoDeInteres.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images_urls'];
    List<String> parsedImages = const [];

    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final legacyMainImage = map['main_image_url'] as String?;
      if (legacyMainImage != null && legacyMainImage.isNotEmpty) {
        parsedImages = [legacyMainImage];
      }
    }

    return PuntoDeInteres(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      imagesUrls: parsedImages,
      categoria: map['categoria'] as String,
      campus: map['campus'] as String,
      universidad: map['universidad'] as String? ?? 'UNAL Medellín',
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      visitado: map['visitado'] as bool? ?? false,
      rarity: map['rarity'] as String?,
    );
  }
}
