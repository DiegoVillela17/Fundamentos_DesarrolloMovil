import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:showcaseview/showcaseview.dart';
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
  late final ShowcaseView _tutorial;

  final _menuKey = GlobalKey();
  final _carritoKey = GlobalKey();
  final _pedidosKey = GlobalKey();
  final _sucursalesKey = GlobalKey();

  int _index = 0;
  bool _saliendo = false;

  @override
  void initState() {
    super.initState();
    _tutorial = ShowcaseView.register();
    store = AppStore(PizzappService(Supabase.instance.client));
    store.cargar();
  }

  @override
  void dispose() {
    _tutorial.unregister();
    store.dispose();
    super.dispose();
  }

  void _mostrarTutorial() {
    if (_tutorial.isShowcaseRunning) return;

    _tutorial.startShowCase([
      _menuKey,
      _carritoKey,
      _pedidosKey,
      _sucursalesKey,
    ]);
  }

  void _cambiarTema() {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    if (oscuro) {
      AdaptiveTheme.of(context).setLight();
    } else {
      AdaptiveTheme.of(context).setDark();
    }
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
      if (mounted) {
        setState(() => _saliendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final oscuro = Theme.of(context).brightness == Brightness.dark;
        final colores = Theme.of(context).colorScheme;

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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_pizza_rounded,
                  color: colores.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PizzApp',
                  style: TextStyle(
                    color: colores.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Ver tutorial',
                onPressed: _mostrarTutorial,
                icon: const Icon(Icons.help_outline),
              ),
              IconButton(
                tooltip: oscuro
                    ? 'Activar modo claro'
                    : 'Activar modo oscuro',
                onPressed: _cambiarTema,
                icon: Icon(
                  oscuro ? Icons.light_mode : Icons.dark_mode,
                ),
              ),
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
                  if (store.cargando)
                    const LinearProgressIndicator(minHeight: 3),
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
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
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
              Showcase(
                key: _menuKey,
                title: '1. Menú de pizzas',
                description:
                    'Aquí puedes elegir tus pizzas y agregarlas al carrito. '
                    'Pulsa este mensaje para continuar.',
                tooltipBackgroundColor: colores.surface,
                textColor: colores.onSurface,
                onToolTipClick: () => _tutorial.next(),
                child: const NavigationDestination(
                  icon: Icon(Icons.local_pizza_outlined),
                  selectedIcon: Icon(Icons.local_pizza),
                  label: 'Menú',
                ),
              ),
              Showcase(
                key: _carritoKey,
                title: '2. Tu carrito',
                description:
                    'Revisa las pizzas, ajusta las cantidades y confirma tu pedido. '
                    'Pulsa este mensaje para continuar.',
                tooltipBackgroundColor: colores.surface,
                textColor: colores.onSurface,
                onToolTipClick: () => _tutorial.next(),
                child: NavigationDestination(
                  icon: Badge(
                    isLabelVisible: store.cantidad > 0,
                    label: Text('${store.cantidad}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  label: 'Carrito',
                ),
              ),
              Showcase(
                key: _pedidosKey,
                title: '3. Tus pedidos',
                description:
                    'Consulta tus pedidos y revisa si están en preparación, '
                    'listos o entregados. Pulsa este mensaje para continuar.',
                tooltipBackgroundColor: colores.surface,
                textColor: colores.onSurface,
                onToolTipClick: () => _tutorial.next(),
                child: const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Pedidos',
                ),
              ),
              Showcase(
                key: _sucursalesKey,
                title: '4. Nuestras sucursales',
                description:
                    'Consulta las ubicaciones y cómo llegar a cada sucursal. '
                    'Pulsa este mensaje para finalizar.',
                tooltipBackgroundColor: colores.surface,
                textColor: colores.onSurface,
                onToolTipClick: () => _tutorial.next(),
                child: const NavigationDestination(
                  icon: Icon(Icons.place_outlined),
                  label: 'Sucursales',
                ),
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
}