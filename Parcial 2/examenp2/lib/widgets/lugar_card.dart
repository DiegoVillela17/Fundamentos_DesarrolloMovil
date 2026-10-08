import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../screens/agregar_lugar.dart';
import '../services/lugares_service.dart';

class LugarCard extends StatefulWidget {
  final Lugar lugar;
  final Future<void> Function() onActualizar;

  const LugarCard({
    super.key,
    required this.lugar,
    required this.onActualizar,
  });

  @override
  State<LugarCard> createState() => _LugarCardState();
}

class _LugarCardState extends State<LugarCard> {
  final _servicio = LugaresService();

  late Future<String> _url;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargarFoto();
  }

  @override
  void didUpdateWidget(covariant LugarCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lugar != widget.lugar) {
      _cargarFoto();
    }
  }

  void _cargarFoto() {
    _url = _servicio.obtenerUrlFoto(widget.lugar.fotoPath);
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _editar() async {
    if (_ocupado) return;

    final actualizar = widget.onActualizar;
    setState(() => _ocupado = true);

    try {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AgregarLugarScreen(lugar: widget.lugar),
        ),
      );

      // Consultamos también si se volvió sin confirmar el guardado.
      // El servidor pudo completar una operación cuya respuesta se perdió.
      if (mounted) {
        await actualizar();
      }
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  Future<void> _eliminar() async {
    if (_ocupado) return;

    final lugar = widget.lugar;
    final actualizar = widget.onActualizar;

    setState(() => _ocupado = true);

    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar lugar'),
          content: Text(
            '¿Quieres eliminar "${lugar.nombre}" y su fotografía? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmado != true || !mounted) return;

      Lugar eliminado;

      try {
        // Primero borramos el registro. Si esto falla, no tocamos la foto.
        eliminado = await _servicio.eliminar(lugar.id);
      } catch (error) {
        debugPrint('No se pudo confirmar el borrado: $error');
        _mensaje(
          'No pudimos confirmar el borrado. Vamos a actualizar la lista.',
        );

        await actualizar();
        return;
      }

      var limpiezaPendiente = false;

      try {
        await _servicio.eliminarFoto(eliminado.fotoPath);
      } catch (error) {
        limpiezaPendiente = true;
        debugPrint('El lugar se borró, pero falló eliminar su foto: $error');
      }

      _mensaje(
        limpiezaPendiente
            ? 'Lugar eliminado. No se pudo borrar su fotografía de Storage.'
            : 'Lugar eliminado.',
      );

      await actualizar();
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  Widget _errorFoto() {
    return Center(
      child: TextButton.icon(
        onPressed: () => setState(_cargarFoto),
        icon: const Icon(Icons.refresh),
        label: const Text('Cargar foto'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: ColoredBox(
              color: const Color(0xFFE2F1E9),
              child: FutureBuilder<String>(
                future: _url,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData) {
                    return _errorFoto();
                  }

                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => _errorFoto(),
                  );
                },
              ),
            ),
          ),
          if (_ocupado) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lugar.nombre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.lugar.categoria),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _ocupado ? null : _editar,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: _ocupado ? null : _eliminar,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}