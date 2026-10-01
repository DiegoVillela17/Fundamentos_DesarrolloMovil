import 'package:flutter/material.dart';

class CancionCard extends StatelessWidget {
  final String titulo;
  final String artista;
  final bool favorita;
  final VoidCallback onFavoritaPressed;
  final VoidCallback onDetallesPressed;
  final VoidCallback onEliminarPressed;

  const CancionCard({
    super.key,
    required this.titulo,
    required this.artista,
    required this.favorita,
    required this.onFavoritaPressed,
    required this.onDetallesPressed,
    required this.onEliminarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BBD0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 42,
                      color: Color(0xFFAD1457),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: onFavoritaPressed,
                      tooltip: favorita
                          ? 'Quitar de favoritas'
                          : 'Marcar como favorita',
                      icon: Icon(
                        favorita ? Icons.star : Icons.star_border,
                        color: favorita
                            ? const Color(0xFFAD1457)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1930),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artista,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              icon: const Icon(Icons.more_vert),
              onSelected: (opcion) {
                if (opcion == 'detalles') {
                  onDetallesPressed();
                } else if (opcion == 'eliminar') {
                  onEliminarPressed();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'detalles',
                  child: Text('Ver detalles'),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}