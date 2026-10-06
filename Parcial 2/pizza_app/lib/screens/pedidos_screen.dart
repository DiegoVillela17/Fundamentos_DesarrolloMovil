import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';

class PedidosScreen extends StatefulWidget {
  final AppStore store;
  const PedidosScreen({super.key, required this.store});
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  int? _actualizando;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store.pedidos.isEmpty) {
      return Vacio(
        icono: Icons.receipt_long_outlined,
        titulo: 'Todavía no hay pedidos',
        descripcion: 'Aquí aparecerán los pedidos confirmados.',
        accion: OutlinedButton.icon(
          onPressed: store.cargando ? null : store.cargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          store.esAdmin ? 'Pedidos de la pizzería' : 'Mis pedidos',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Pulsa actualizar para consultar el estado más reciente.'),
        const SizedBox(height: 20),
        for (final pedido in store.pedidos)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Pedido #${pedido.id}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        EstadoPedido(pedido: pedido),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(pedido.sucursal),
                    Text(
                      _fecha(pedido.fecha),
                      style: const TextStyle(color: Colors.brown, fontSize: 12),
                    ),
                    const Divider(height: 28),
                    for (final item in pedido.detalles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.cantidad} × ${item.nombre}\n${item.tamano}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(dinero(item.cantidad * item.precio)),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          dinero(pedido.total),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: rojo,
                          ),
                        ),
                      ],
                    ),
                    if (store.esAdmin) ...[
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          '${pedido.id}:${pedido.estado}:$_actualizando',
                        ),
                        initialValue: pedido.estado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cambiar estado',
                        ),
                        items:
                            [
                                  'pendiente',
                                  'en_preparacion',
                                  'listo',
                                  'entregado',
                                  'cancelado',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(etiquetaEstado(e)),
                                  ),
                                )
                                .toList(),
                        onChanged: _actualizando != null
                            ? null
                            : (estado) {
                                if (estado != null && estado != pedido.estado) {
                                  _cambiarEstado(pedido, estado);
                                }
                              },
                      ),
                      if (_actualizando == pedido.id)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  Future<void> _cambiarEstado(Pedido pedido, String estado) async {
    setState(() => _actualizando = pedido.id);
    try {
      await widget.store.service.cambiarEstado(pedido.id, estado);
      await widget.store.cargar();
      if (mounted) avisar(context, 'Estado actualizado.');
    } catch (_) {
      if (mounted) {
        avisar(context, 'No se pudo actualizar el estado.', error: true);
      }
    } finally {
      if (mounted) setState(() => _actualizando = null);
    }
  }
}
