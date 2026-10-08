class Lugar {
  final String id;
  final String usuarioId;
  final String nombre;
  final String categoria;
  final double latitud;
  final double longitud;
  final String fotoPath;

  const Lugar({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    required this.fotoPath,
  });

  factory Lugar.fromMap(Map<String, dynamic> mapa) {
    return Lugar(
      id: mapa['id'] as String,
      usuarioId: mapa['usuario_id'] as String,
      nombre: mapa['nombre'] as String,
      categoria: mapa['categoria'] as String,
      latitud: (mapa['latitud'] as num).toDouble(),
      longitud: (mapa['longitud'] as num).toDouble(),
      fotoPath: mapa['foto_path'] as String,
    );
  }
}
