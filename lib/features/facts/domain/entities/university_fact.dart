class UniversityFact {
  final int id;
  final String titulo;
  final String descripcion;
  final String? imageUrl;
  final DateTime? desbloqueadoAt;

  const UniversityFact({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.imageUrl,
    this.desbloqueadoAt,
  });

  factory UniversityFact.fromMap(Map<String, dynamic> map) {
    return UniversityFact(
      id: (map['id'] as num).toInt(),
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      imageUrl: map['image_url'] as String?,
      desbloqueadoAt: map['desbloqueado_at'] != null
          ? DateTime.tryParse(map['desbloqueado_at'].toString())
          : null,
    );
  }
}
