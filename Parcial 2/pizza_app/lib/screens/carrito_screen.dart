import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_store.dart';
import '../widgets/common.dart';

class CarritoScreen extends StatefulWidget {
  final AppStore store;
  final VoidCallback irAlMenu, irAPedidos;
  const CarritoScreen({
    super.key,
    required this.store,
    required this.irAlMenu,
    required this.irAPedidos,
  });
  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  int? _sucursalId;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store.carrito.isEmpty) {
      return Vacio(
        icono: Icons.shopping_bag_outlined,
        titulo: 'Tu carrito está esperando',
        descripcion: 'Elige una pizza para comenzar tu pedido.',
        accion: FilledButton(
          onPressed: widget.irAlMenu,
          child: const Text('Ver el menú'),
        ),
      );
    }
    final sucursalId = store.sucursales.any((s) => s.id == _sucursalId)
        ? _sucursalId
        : store.sucursales.isNotEmpty
        ? store.sucursales.first.id
        : null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Tu carrito',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Una buena pizza merece una buena compañía.'),
        const SizedBox(height: 20),
        for (final item in store.carrito)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FotoPizza(
                              url: item.pizza.imagenUrl,
                              altura: 72,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.pizza.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                '${item.tamano} · ${dinero(item.precioUnitario)} c/u',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Eliminar del carrito',
                          onPressed: store.confirmando
                              ? null
                              : () => store.quitar(item.clave),
                          icon: const Icon(Icons.delete_outline, color: rojo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SelectorCantidad(
                          cantidad: item.cantidad,
                          habilitado: !store.confirmando,
                          onChanged: (n) =>
                              store.cambiarCantidad(item.clave, n),
                        ),
                        Text(
                          dinero(item.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recoger en sucursal',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (store.sucursales.isEmpty)
                  const Text(
                    'No hay sucursales disponibles.',
                    style: TextStyle(color: rojo),
                  )
                else
                  DropdownButtonFormField<int>(
                    key: ValueKey(sucursalId),
                    initialValue: sucursalId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sucursal'),
                    items: store.sucursales
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: store.confirmando
                        ? null
                        : (id) => setState(() => _sucursalId = id),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Pago en sucursal al recoger. No se cobra desde la app.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'El importe final se calcula con los precios vigentes al confirmar.',
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total estimado',
                      style: TextStyle(fontSize: 17),
                    ),
                    Text(
                      dinero(store.total),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: rojo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: store.confirmando || sucursalId == null
                      ? null
                      : () => _confirmar(sucursalId),
                  icon: store.confirmando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    store.confirmando ? 'Confirmando…' : 'Confirmar pedido',
                  ),
                ),
                TextButton(
                  onPressed: store.confirmando ? null : widget.irAlMenu,
                  child: const Text('Agregar otra pizza'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmar(int sucursalId) async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Confirmar pedido?'),
        content: Text(
          'Total estimado: ${dinero(widget.store.total)}.\n'
          'Tu pizza se preparará para recoger en la sucursal elegida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar carrito'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (aceptar != true || !mounted) return;
    try {
      final id = await widget.store.confirmar(sucursalId);
      if (!mounted) return;
      avisar(
        context,
        '¡Pedido #$id confirmado! Revisa el importe final en Pedidos.',
      );
      widget.irAPedidos();
    } on PostgrestException catch (e) {
      if (mounted) avisar(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        avisar(
          context,
          'No se recibió confirmación. Actualiza Pedidos antes de volver a intentar.',
          error: true,
        );
      }
    }
  }
}
