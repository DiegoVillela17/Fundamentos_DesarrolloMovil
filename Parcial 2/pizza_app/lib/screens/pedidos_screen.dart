import 'package:flutter/material.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';

class PedidosScreen extends StatefulWidget {
  final AppStore store;

  const PedidosScreen({
    super.key,
    required this.store,
  });

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  int? _actualizando;

  final Map<int, double> _calificaciones = {};

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final colores = Theme.of(context).colorScheme;

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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pulsa actualizar para consultar el estado más reciente.',
        ),
        const SizedBox(height: 20),
        for (final pedido in store.pedidos)
          Padding(
            key: ValueKey(pedido.id),
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
                      style: TextStyle(
                        color: colores.onSurfaceVariant,
                        fontSize: 12,
                      ),
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
                                '${item.cantidad} × ${item.nombre}\n'
                                '${item.tamano}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              dinero(item.cantidad * item.precio),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dinero(pedido.total),
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: colores.primary,
                          ),
                        ),
                      ],
                    ),
                    if (!store.esAdmin &&
                        pedido.estado == 'entregado') ...[
                      const Divider(height: 32),
                      const Text(
                        '¿Qué te pareció tu pedido?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selecciona de 1 a 5 estrellas.',
                        style: TextStyle(
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RatingBar(
                        key: ValueKey('rating-${pedido.id}'),
                        filledIcon: Icons.star_rounded,
                        emptyIcon: Icons.star_outline_rounded,
                        initialRating:
                            _calificaciones[pedido.id] ?? 0.0,
                        maxRating: 5,
                        onRatingChanged: (valor) {
                          setState(() {
                            _calificaciones[pedido.id] = valor;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _calificaciones.containsKey(pedido.id)
                            ? 'Tu calificación: '
                                '${_calificaciones[pedido.id]!.toStringAsFixed(0)}'
                                ' de 5 estrellas'
                            : 'Todavía no has seleccionado una calificación.',
                        style: TextStyle(
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                        items: [
                          'pendiente',
                          'en_preparacion',
                          'listo',
                          'entregado',
                          'cancelado',
                        ].map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(etiquetaEstado(estado)),
                          );
                        }).toList(),
                        onChanged: _actualizando != null
                            ? null
                            : (estado) {
                                if (estado != null &&
                                    estado != pedido.estado) {
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

  String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  Future<void> _cambiarEstado(
    Pedido pedido,
    String estado,
  ) async {
    setState(() => _actualizando = pedido.id);

    try {
      await widget.store.service.cambiarEstado(pedido.id, estado);
      await widget.store.cargar();

      if (mounted) {
        avisar(context, 'Estado actualizado.');
      }
    } catch (_) {
      if (mounted) {
        avisar(
          context,
          'No se pudo actualizar el estado.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actualizando = null);
      }
    }
  }
}