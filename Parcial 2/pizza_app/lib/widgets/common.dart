import 'package:flutter/material.dart';

import '../models/models.dart';

const amarillo = Color(0xFFFFC51B);
const rojo = Color(0xFFD93636);
const fondo = Color(0xFFFFFBF2);
const texto = Color(0xFF332A20);
String dinero(num valor) => '\$${valor.toStringAsFixed(2)}';
String mensajeError(Object e) => e.toString().replaceFirst('Bad state: ', '');
void avisar(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: error ? rojo : texto,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class FotoPizza extends StatelessWidget {
  final String url;
  final double altura;
  const FotoPizza({super.key, required this.url, this.altura = 160});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: altura,
    width: double.infinity,
    child: url.isEmpty
        ? _placeholder()
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => _placeholder(),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _placeholder(),
          ),
  );
  Widget _placeholder() => ColoredBox(
    color: amarillo.withValues(alpha: .16),
    child: const Center(child: Icon(Icons.local_pizza, color: rojo, size: 58)),
  );
}

class Vacio extends StatelessWidget {
  final IconData icono;
  final String titulo, descripcion;
  final Widget? accion;
  const Vacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.accion,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: amarillo.withValues(alpha: .2),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 46, color: rojo),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(descripcion, textAlign: TextAlign.center),
          if (accion != null) ...[const SizedBox(height: 20), accion!],
        ],
      ),
    ),
  );
}

class SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final bool habilitado;
  final ValueChanged<int> onChanged;
  const SelectorCantidad({
    super.key,
    required this.cantidad,
    required this.onChanged,
    this.habilitado = true,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        tooltip: 'Disminuir cantidad',
        onPressed: habilitado && cantidad > 1
            ? () => onChanged(cantidad - 1)
            : null,
        icon: const Icon(Icons.remove, size: 18),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '$cantidad',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Aumentar cantidad',
        onPressed: habilitado && cantidad < 99
            ? () => onChanged(cantidad + 1)
            : null,
        icon: const Icon(Icons.add, size: 18),
      ),
    ],
  );
}

String etiquetaEstado(String estado) => switch (estado) {
  'pendiente' => 'Pendiente',
  'en_preparacion' => 'En preparación',
  'listo' => 'Listo para recoger',
  'entregado' => 'Entregado',
  'cancelado' => 'Cancelado',
  _ => estado,
};

class EstadoPedido extends StatelessWidget {
  final Pedido pedido;
  const EstadoPedido({super.key, required this.pedido});
  @override
  Widget build(BuildContext context) {
    final color = switch (pedido.estado) {
      'entregado' || 'listo' => Colors.green.shade800,
      'cancelado' => rojo,
      _ => Colors.brown.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        etiquetaEstado(pedido.estado),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
