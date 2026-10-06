import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/pizzapp_service.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';
import 'catalogo_screen.dart';
import 'carrito_screen.dart';
import 'pedidos_screen.dart';
import 'sucursales_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppStore store;
  int _index = 0;
  bool _saliendo = false;
  @override
  void initState() {
    super.initState();
    store = AppStore(PizzappService(Supabase.instance.client));
    store.cargar();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  Future<void> _salir() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'El carrito se guarda sólo durante esta sesión. Al salir se vaciará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (salir != true || !mounted) return;
    setState(() => _saliendo = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (mounted) {
        avisar(
          context,
          'No se pudo cerrar la sesión. Intenta de nuevo.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saliendo = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final pantallas = [
        CatalogoScreen(store: store),
        CarritoScreen(
          store: store,
          irAlMenu: () => setState(() => _index = 0),
          irAPedidos: () => setState(() => _index = 2),
        ),
        PedidosScreen(store: store),
        SucursalesScreen(store: store),
        if (store.esAdmin) AdminScreen(store: store),
      ];
      final index = _index < pantallas.length ? _index : 0;
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_pizza_rounded, color: rojo),
              SizedBox(width: 8),
              Text(
                'PizzApp',
                style: TextStyle(color: rojo, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar datos',
              onPressed: store.cargando || store.confirmando
                  ? null
                  : store.cargar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Mi cuenta',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    store.nombre.isEmpty ? 'Mi cuenta' : store.nombre,
                  ),
                  content: Text(
                    '${Supabase.instance.client.auth.currentUser?.email ?? ''}\n\n'
                    '${store.esAdmin ? 'Administrador' : 'Cliente'}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.account_circle_outlined),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _saliendo || store.confirmando ? null : _salir,
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                if (store.cargando) const LinearProgressIndicator(minHeight: 3),
                if (store.error != null && store.pizzas.isNotEmpty)
                  MaterialBanner(
                    content: Text(store.error!),
                    actions: [
                      TextButton(
                        onPressed: store.cargando ? null : store.cargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                Expanded(
                  child: store.cargando && store.pizzas.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : store.error != null && store.pizzas.isEmpty
                      ? Vacio(
                          icono: Icons.cloud_off,
                          titulo: 'No pudimos cargar tu pizzería',
                          descripcion: store.error!,
                          accion: FilledButton(
                            onPressed: store.cargar,
                            child: const Text('Reintentar'),
                          ),
                        )
                      : pantallas[index],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.local_pizza_outlined),
              selectedIcon: Icon(Icons.local_pizza),
              label: 'Menú',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: store.cantidad > 0,
                label: Text('${store.cantidad}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              label: 'Carrito',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Pedidos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.place_outlined),
              label: 'Sucursales',
            ),
            if (store.esAdmin)
              const NavigationDestination(
                icon: Icon(Icons.edit_note),
                label: 'Administrar',
              ),
          ],
        ),
      );
    },
  );
}
