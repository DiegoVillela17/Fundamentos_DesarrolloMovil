import 'package:flutter/material.dart';

import '../models/lugar.dart';
import '../services/auth_service.dart';
import '../services/lugares_service.dart';
import '../widgets/lugar_card.dart';
import 'agregar_lugar.dart';
import 'mapa_lugares_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _authService = AuthService();
  final _lugaresService = LugaresService();
  final _busquedaController = TextEditingController();

  late Future<List<Lugar>> _lugares;

  String _busqueda = '';
  String _categoriaFiltro = '';
  bool _cerrandoSesion = false;

  static const _verde = Color(0xFF26735C);

  @override
  void initState() {
    super.initState();
    _lugares = _consultarLugares();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<List<Lugar>> _consultarLugares() async {
    debugPrint('Consultando lugares en Supabase...');

    try {
      final resultado = await _lugaresService.listar();

      debugPrint('Lugares recibidos: ${resultado.length}');

      return resultado;
    } catch (error) {
      debugPrint('Error al consultar lugares: $error');
      rethrow;
    }
  }

  Future<void> _actualizar() async {
    if (!mounted) return;

    final consulta = _consultarLugares();

    setState(() {
      _lugares = consulta;
    });

    try {
      await consulta;
    } catch (error) {
      debugPrint('No se pudo actualizar la lista: $error');
    }
  }

  Future<void> _agregarLugar() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AgregarLugarScreen(),
      ),
    );

    if (!mounted) return;

    if (guardado == true) {
      _limpiarFiltros();
    }

    await _actualizar();

    if (!mounted) return;

    if (guardado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lugar guardado.')),
      );
    }
  }

  void _verMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapaLugaresScreen(),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    setState(() => _cerrandoSesion = true);

    try {
      await _authService.cerrarSesion();
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión. Intenta nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cerrandoSesion = false);
      }
    }
  }

  String _normalizar(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  void _limpiarFiltros() {
    _busquedaController.clear();

    setState(() {
      _busqueda = '';
      _categoriaFiltro = '';
    });
  }

  Widget _mensajeVacio({
    required IconData icono,
    required String titulo,
    required String descripcion,
    bool mostrarLimpiar = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDEAE2),
        ),
      ),
      child: Column(
        children: [
          Icon(icono, size: 52, color: _verde),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descripcion,
            textAlign: TextAlign.center,
          ),
          if (mostrarLimpiar) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final correo = _authService.sesionActual?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis lugares'),
        actions: [
          IconButton(
            tooltip: 'Ver mapa',
            onPressed: _cerrandoSesion ? null : _verMapa,
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Actualizar lugares',
            onPressed: _cerrandoSesion ? null : _actualizar,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Mi cuenta',
            enabled: !_cerrandoSesion,
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (opcion) {
              if (opcion == 'salir') {
                _cerrarSesion();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  correo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'salir',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cerrandoSesion ? null : _agregarLugar,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Añadir lugar'),
      ),
      body: Column(
        children: [
          if (_cerrandoSesion) const LinearProgressIndicator(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: FutureBuilder<List<Lugar>>(
                  future: _lugares,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: _verde,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'No pudimos cargar tus lugares.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Revisa tu conexión e intenta nuevamente.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _actualizar,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final lugares = snapshot.data ?? <Lugar>[];
                    final textoBuscado = _normalizar(_busqueda);

                    final visibles = lugares.where((lugar) {
                      final coincideNombre =
                          _normalizar(lugar.nombre).contains(textoBuscado);

                      final coincideCategoria =
                          _categoriaFiltro.isEmpty ||
                          lugar.categoria == _categoriaFiltro;

                      return coincideNombre && coincideCategoria;
                    }).toList();

                    final categorias = <String>{
                      ...lugares.map((lugar) => lugar.categoria),
                      if (_categoriaFiltro.isNotEmpty) _categoriaFiltro,
                    }.toList()
                      ..sort();

                    final hayFiltros =
                        textoBuscado.isNotEmpty ||
                        _categoriaFiltro.isNotEmpty;

                    return RefreshIndicator(
                      onRefresh: _actualizar,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          100,
                        ),
                        children: [
                          const Text(
                            'Tus lugares favoritos',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: _verde,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${lugares.length} '
                            '${lugares.length == 1 ? 'lugar guardado' : 'lugares guardados'}',
                            style: const TextStyle(
                              color: Color(0xFF53685D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _busquedaController,
                            onChanged: (valor) {
                              setState(() => _busqueda = valor);
                            },
                            decoration: InputDecoration(
                              labelText: 'Buscar por nombre',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _busqueda.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Borrar búsqueda',
                                      onPressed: () {
                                        _busquedaController.clear();
                                        setState(() => _busqueda = '');
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_categoriaFiltro),
                            initialValue: _categoriaFiltro,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Todas las categorías'),
                              ),
                              ...categorias.map(
                                (categoria) => DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Text(categoria),
                                ),
                              ),
                            ],
                            onChanged: (valor) {
                              setState(() {
                                _categoriaFiltro = valor ?? '';
                              });
                            },
                          ),
                          if (hayFiltros) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _limpiarFiltros,
                                icon: const Icon(
                                  Icons.filter_alt_off_outlined,
                                ),
                                label: const Text('Limpiar filtros'),
                              ),
                            ),
                            Text(
                              '${visibles.length} '
                              '${visibles.length == 1 ? 'resultado' : 'resultados'}',
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (lugares.isEmpty)
                            _mensajeVacio(
                              icono: Icons.bookmark_border_rounded,
                              titulo: 'Aún no tienes lugares favoritos',
                              descripcion:
                                  'Pulsa Añadir lugar para guardar el primero.',
                              mostrarLimpiar: hayFiltros,
                            )
                          else if (visibles.isEmpty)
                            _mensajeVacio(
                              icono: Icons.search_off,
                              titulo: 'No encontramos coincidencias',
                              descripcion:
                                  'Prueba otro nombre o cambia la categoría.',
                              mostrarLimpiar: true,
                            )
                          else
                            for (final lugar in visibles)
                              LugarCard(
                                key: ValueKey(lugar.id),
                                lugar: lugar,
                                onActualizar: _actualizar,
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}