import 'package:flutter/material.dart';
import '../widgets/cancion_card.dart';
import '../services/canciones_service.dart';
import 'agregar_cancion_screen.dart';

class CancionesScreen extends StatefulWidget {
  const CancionesScreen({super.key});

  @override
  State<CancionesScreen> createState() => _CancionesScreenState();
}

class _CancionesScreenState extends State<CancionesScreen> {
  List<Map<String, dynamic>> canciones = [];
  bool cargando = true;
  bool procesando = false;
  String? mensajeError;

  @override
  void initState() {
    super.initState();
    cargarCanciones();
  }

  Future<void> cargarCanciones() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final resultado = await obtenerCanciones();
      if (!mounted) return;

      setState(() {
        canciones = resultado;
        cargando = false;
      });
    } catch (error) {
      debugPrint('Error al consultar: $error');
      if (!mounted) return;

      setState(() {
        mensajeError = 'No se pudieron cargar las canciones.';
        cargando = false;
      });
    }
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> cambiarFavorita(Map<String, dynamic> cancion) async {
    if (procesando) return;
    procesando = true;

    try {
      await actualizarFavorita(cancion['id'], !cancion['favorita']);
      if (!mounted) return;

      mostrarMensaje('Favorita actualizada.');
      await cargarCanciones();
    } catch (error) {
      debugPrint('Error al actualizar: $error');
      if (mounted) mostrarMensaje('No se pudo cambiar la favorita.');
    } finally {
      procesando = false;
    }
  }

  Future<void> borrarCancion(int id) async {
    if (procesando) return;
    procesando = true;

    try {
      await eliminarCancion(id);
      if (!mounted) return;

      mostrarMensaje('Canción eliminada.');
      await cargarCanciones();
    } catch (error) {
      debugPrint('Error al eliminar: $error');
      if (mounted) mostrarMensaje('No se pudo eliminar la canción.');
    } finally {
      procesando = false;
    }
  }

  Future<void> abrirFormulario() async {
    if (procesando) return;

    final guardada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarCancionScreen(),
      ),
    );

    if (!mounted || guardada != true) return;

    mostrarMensaje('Canción agregada.');
    await cargarCanciones();
  }

  void mostrarDetalles(Map<String, dynamic> cancion) {
    final int? segundos = cancion['duracion_seg'];
    String duracion = 'Sin registrar';

    if (segundos != null) {
      final minutos = segundos ~/ 60;
      final resto = (segundos % 60).toString().padLeft(2, '0');
      duracion = '$minutos:$resto';
    }

    final String album = cancion['album'] ?? '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cancion['titulo']),
        content: SingleChildScrollView(
          child: Text(
            'Artista: ${cancion['artista']}\n\n'
            'Álbum: ${album.trim().isEmpty ? 'Sin registrar' : album}\n\n'
            'Año: ${cancion['anio'] ?? 'Sin registrar'}\n\n'
            'Duración: $duracion',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget construirContenido() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mensajeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensajeError!),
            TextButton(
              onPressed: cargarCanciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (canciones.isEmpty) {
      return const Center(
        child: Text('No hay canciones. Pulsa + para agregar una.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: canciones.length,
      itemBuilder: (context, index) {
        final cancion = canciones[index];

        return CancionCard(
          key: ValueKey(cancion['id']),
          titulo: cancion['titulo'],
          artista: cancion['artista'],
          favorita: cancion['favorita'],
          onFavoritaPressed: () => cambiarFavorita(cancion),
          onDetallesPressed: () => mostrarDetalles(cancion),
          onEliminarPressed: () => borrarCancion(cancion['id']),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      appBar: AppBar(
        title: const Text('Mi Biblioteca Musical'),
        backgroundColor: const Color(0xFFF8BBD0),
        foregroundColor: const Color.fromARGB(255, 129, 12, 184),
      ),
      body: construirContenido(),
      floatingActionButton: FloatingActionButton(
        onPressed: cargando || mensajeError != null ? null : abrirFormulario,
        tooltip: 'Agregar canción',
        backgroundColor: const Color(0xFFF8BBD0),
        foregroundColor: const Color(0xFFAD1457),
        child: const Icon(Icons.add),
      ),
    );
  }
}