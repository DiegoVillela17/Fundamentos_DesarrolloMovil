import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lugar.dart';
import '../services/lugares_service.dart';

class MapaLugaresScreen extends StatefulWidget {
  const MapaLugaresScreen({super.key});

  @override
  State<MapaLugaresScreen> createState() => _MapaLugaresScreenState();
}

class _MapaLugaresScreenState extends State<MapaLugaresScreen> {
  final _servicio = LugaresService();
  final _mapa = MapController();

  List<Lugar> _lugares = [];
  Lugar? _seleccionado;
  LatLng? _ubicacion;

  bool _cargando = true;
  bool _error = false;
  bool _localizando = false;
  bool _mapaListo = false;

  static const _verde = Color(0xFF26735C);

  @override
  void initState() {
    super.initState();
    _cargarLugares();
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _cargarLugares() async {
    setState(() {
      _cargando = true;
      _error = false;
      _mapaListo = false;
    });

    try {
      final lugares = await _servicio.listar();

      if (!mounted) return;

      setState(() {
        _lugares = lugares;
        _cargando = false;
      });
    } catch (error) {
      debugPrint('Error al cargar el mapa: $error');

      if (!mounted) return;

      setState(() {
        _error = true;
        _cargando = false;
      });
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  List<LatLng> get _puntos => _lugares
      .map((lugar) => LatLng(lugar.latitud, lugar.longitud))
      .toList();

  CameraFit? _ajusteMapa() {
    final puntos = _puntos;

    if (puntos.length < 2) return null;

    final todosIguales = puntos.every(
      (punto) =>
          punto.latitude == puntos.first.latitude &&
          punto.longitude == puntos.first.longitude,
    );

    if (todosIguales) return null;

    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(puntos),
      padding: const EdgeInsets.all(55),
      maxZoom: 16,
    );
  }

  void _verTodos() {
    if (!_mapaListo || _lugares.isEmpty) return;

    final ajuste = _ajusteMapa();

    if (ajuste != null) {
      _mapa.fitCamera(ajuste);
    } else {
      _mapa.move(_puntos.first, 15);
    }

    setState(() => _seleccionado = null);
  }

  void _seleccionar(Lugar lugar) {
    setState(() => _seleccionado = lugar);

    if (_mapaListo) {
      _mapa.move(
        LatLng(lugar.latitud, lugar.longitud),
        16,
      );
    }
  }

  Future<void> _miUbicacion() async {
    if (_localizando || !_mapaListo) return;

    setState(() => _localizando = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _mensaje('Activa la ubicación de tu dispositivo.');
        return;
      }

      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _mensaje('Permite el acceso a tu ubicación en el navegador.');
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final punto = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      setState(() {
        _ubicacion = punto;
        _seleccionado = null;
      });

      if (_mapaListo) {
        _mapa.move(punto, 16);
      }

      _mensaje('El punto azul indica tu ubicación aproximada.');
    } on TimeoutException {
      _mensaje('No se obtuvo la ubicación a tiempo. Intenta nuevamente.');
    } catch (error) {
      debugPrint('Error al obtener ubicación: $error');
      _mensaje('No pudimos obtener tu ubicación. Revisa los permisos.');
    } finally {
      if (mounted) {
        setState(() => _localizando = false);
      }
    }
  }

  Future<void> _verCreditos() async {
    try {
      final abierto = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      );

      if (!abierto) {
        _mensaje('Consulta openstreetmap.org/copyright.');
      }
    } catch (_) {
      _mensaje('Consulta openstreetmap.org/copyright.');
    }
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: _verde,
              ),
              const SizedBox(height: 16),
              const Text(
                'No pudimos cargar tus lugares.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _cargarLugares,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final seleccionado = _seleccionado;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _lugares.isEmpty
                    ? 'Aún no tienes lugares guardados.'
                    : '${_lugares.length} '
                        '${_lugares.length == 1 ? 'lugar guardado' : 'lugares guardados'}. '
                        'Toca un marcador para ver su nombre.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _lugares.isEmpty ? null : _verTodos,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver todos'),
                  ),
                  FilledButton.icon(
                    onPressed: _localizando ? null : _miUbicacion,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _localizando ? 'Localizando…' : 'Mi ubicación',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: _lugares.isEmpty
                  ? const LatLng(22.1565, -100.9855)
                  : _puntos.first,
              initialZoom: _lugares.isEmpty ? 12 : 15,
              initialCameraFit: _ajusteMapa(),
              minZoom: 1,
              maxZoom: 18,
              onMapReady: () => _mapaListo = true,
              onTap: (_, punto) {
                setState(() => _seleccionado = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mx.edu.examenp2.mislugares',
              ),
              MarkerLayer(
                markers: [
                  for (final lugar in _lugares)
                    Marker(
                      point: LatLng(lugar.latitud, lugar.longitud),
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        tooltip: lugar.nombre,
                        padding: EdgeInsets.zero,
                        onPressed: () => _seleccionar(lugar),
                        icon: Icon(
                          Icons.location_on,
                          size: 44,
                          color: seleccionado?.id == lugar.id
                              ? Colors.orange.shade800
                              : _verde,
                        ),
                      ),
                    ),
                  if (_ubicacion != null)
                    Marker(
                      point: _ubicacion!,
                      width: 24,
                      height: 24,
                      child: const Tooltip(
                        message: 'Mi ubicación',
                        child: Icon(
                          Icons.circle,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: _verCreditos,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (seleccionado != null)
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.place, color: _verde),
              title: Text(
                seleccionado.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(seleccionado.categoria),
              trailing: IconButton(
                tooltip: 'Cerrar información',
                onPressed: () {
                  setState(() => _seleccionado = null);
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de mis lugares'),
      ),
      body: _contenido(),
    );
  }
}