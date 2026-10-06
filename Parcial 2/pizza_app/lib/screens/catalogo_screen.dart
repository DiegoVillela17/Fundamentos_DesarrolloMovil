import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';

class CatalogoScreen extends StatefulWidget {
  final AppStore store;
  const CatalogoScreen({super.key, required this.store});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _busqueda = '';
  @override
  Widget build(BuildContext context) {
    final pizzas = widget.store.pizzas
        .where(
          (p) =>
              p.disponible &&
              p.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: amarillo,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.store.nombre.isEmpty
                                  ? '¡Hoy se come pizza!'
                                  : '¡Hola, ${widget.store.nombre.split(' ').first}!',
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: rojo,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Elige tu favorita.\nLa preparamos para recoger en sucursal.',
                              style: TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.local_pizza_rounded,
                        size: 64,
                        color: rojo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nuestro menú',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Precios de tamaño mediano · MXN'),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar una pizza',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pizzas.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Vacio(
              icono: Icons.search_off,
              titulo: 'No encontramos pizzas',
              descripcion: 'Prueba otra búsqueda o vuelve más tarde.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columnas = constraints.crossAxisExtent >= 900
                    ? 3
                    : constraints.crossAxisExtent >= 560
                    ? 2
                    : 1;
                return SliverGrid.builder(
                  itemCount: pizzas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    mainAxisExtent: 342,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, i) {
                    final pizza = pizzas[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FotoPizza(url: pizza.imagenUrl),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pizza.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pizza.descripcion,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.brown),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dinero(pizza.precio),
                                          style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900,
                                            color: rojo,
                                          ),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: widget.store.confirmando
                                            ? null
                                            : () => _elegirPizza(pizza),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Elegir'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _elegirPizza(Pizza pizza) async {
    final tamanos = widget.store.tamanos.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (tamanos.isEmpty) {
      avisar(context, 'No hay tamaños configurados.', error: true);
      return;
    }
    String tamano = tamanos.first.key;
    int cantidad = 1;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final unitario =
              (pizza.precio * widget.store.tamanos[tamano]! * 100).round() /
              100;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FotoPizza(url: pizza.imagenUrl, altura: 170),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    pizza.nombre,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(pizza.descripcion),
                  const SizedBox(height: 20),
                  const Text(
                    'Tamaño',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tamanos
                        .map(
                          (t) => ChoiceChip(
                            label: Text(t.key),
                            selected: t.key == tamano,
                            selectedColor: amarillo,
                            onSelected: (_) =>
                                setModalState(() => tamano = t.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectorCantidad(
                        cantidad: cantidad,
                        onChanged: (n) => setModalState(() => cantidad = n),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      try {
                        widget.store.agregar(pizza, tamano, cantidad);
                        Navigator.pop(sheetContext);
                        avisar(
                          this.context,
                          '${pizza.nombre} agregada al carrito.',
                        );
                      } catch (e) {
                        avisar(context, mensajeError(e), error: true);
                      }
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text('Agregar · ${dinero(unitario * cantidad)}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
