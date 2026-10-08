import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lugar.dart';
import '../services/lugares_service.dart';

class AgregarLugarScreen extends StatefulWidget {
  final Lugar? lugar;

  const AgregarLugarScreen({super.key, this.lugar});

  @override
  State<AgregarLugarScreen> createState() => _AgregarLugarScreenState();
}

class _AgregarLugarScreenState extends State<AgregarLugarScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _mapa = MapController();
  final _servicio = LugaresService();

  late final String _id;
  Future<String>? _fotoActual;

  static const _categorias = [
    'Comida',
    'Estudio',
    'Deporte',
    'Diversión',
    'Naturaleza',
    'Otros',
  ];

  String? _categoria;
  Uint8List? _foto;
  LatLng? _punto;
  LatLng? _ubicacion;
  String? _rutaSubida;

  bool _guardando = false;
  bool _eligiendoFoto = false;
  bool _localizando = false;
  bool _mapaListo = false;
  bool _pendienteConfirmar = false;

  bool get _editando => widget.lugar != null;
  bool get _ocupado => _guardando || _eligiendoFoto || _localizando;
  bool get _bloqueado =>
      _ocupado || _pendienteConfirmar || _rutaSubida != null;

  @override
  void initState() {
    super.initState();

    final lugar = widget.lugar;
    _id = lugar?.id ?? LugaresService.nuevoId();

    if (lugar != null) {
      _nombre.text = lugar.nombre;
      _categoria = lugar.categoria;
      _punto = LatLng(lugar.latitud, lugar.longitud);
      _fotoActual = _servicio.obtenerUrlFoto(lugar.fotoPath);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _mapa.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _elegirFoto() async {
    if (_bloqueado) return;

    setState(() => _eligiendoFoto = true);

    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (archivo == null) return;

      if (await archivo.length() > LugaresService.maximoFotoBytes) {
        _mensaje('La fotografía debe pesar como máximo 5 MB.');
        return;
      }

      final bytes = await archivo.readAsBytes();
      final imagen = await decodeImageFromList(bytes);
      imagen.dispose();

      if (mounted) {
        setState(() => _foto = bytes);
      }
    } catch (_) {
      _mensaje('No pudimos abrir la imagen. Elige una foto JPG, PNG o WEBP.');
    } finally {
      if (mounted) {
        setState(() => _eligiendoFoto = false);
      }
    }
  }

  Future<void> _miUbicacion() async {
    if (_bloqueado) return;

    setState(() => _localizando = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _mensaje('Activa la ubicación o selecciona un punto en el mapa.');
        return;
      }

      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _mensaje(
          'Permite el acceso a la ubicación o marca el lugar manualmente.',
        );
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final coordenadas = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      setState(() {
        _ubicacion = coordenadas;
        _punto = coordenadas;
      });

      if (_mapaListo) {
        _mapa.move(coordenadas, 16);
      }

      _mensaje('Puedes ajustar el marcador tocando el mapa.');
    } on TimeoutException {
      _mensaje('La ubicación tardó demasiado. Selecciona el punto en el mapa.');
    } catch (_) {
      _mensaje('No pudimos obtener tu ubicación. Revisa los permisos.');
    } finally {
      if (mounted) {
        setState(() => _localizando = false);
      }
    }
  }

  Future<void> _guardar() async {
    if (_ocupado || !_formulario.currentState!.validate()) return;

    if (_punto == null || _categoria == null) {
      _mensaje('Selecciona una categoría y una ubicación.');
      return;
    }

    if (!_editando && _foto == null) {
      _mensaje('Selecciona una fotografía.');
      return;
    }

    setState(() => _guardando = true);

    try {
      // Sólo subimos una foto si se seleccionó una nueva.
      if (_foto != null) {
        _rutaSubida ??= await _servicio.subirFoto(_foto!);
      }

      final ruta = _rutaSubida ?? widget.lugar!.fotoPath;

      // Conservamos los datos al reintentar un guardado incierto.
      _pendienteConfirmar = true;

      if (_editando) {
        await _servicio.editar(
          id: _id,
          nombre: _nombre.text,
          categoria: _categoria!,
          latitud: _punto!.latitude,
          longitud: _punto!.longitude,
          fotoPath: ruta,
        );
      } else {
        await _servicio.crear(
          id: _id,
          nombre: _nombre.text,
          categoria: _categoria!,
          latitud: _punto!.latitude,
          longitud: _punto!.longitude,
          fotoPath: ruta,
        );
      }

      // La foto anterior se borra únicamente después de confirmar
      // que el registro ya utiliza la nueva.
      var limpiezaPendiente = false;
      final anterior = widget.lugar;

      if (anterior != null && anterior.fotoPath != ruta) {
        try {
          await _servicio.eliminarFoto(anterior.fotoPath);
        } catch (error) {
          limpiezaPendiente = true;
          debugPrint('No se pudo eliminar la foto anterior: $error');
        }
      }

      if (!mounted) return;

      if (_editando) {
        _mensaje(
          limpiezaPendiente
              ? 'Cambios guardados. No se pudo eliminar la foto anterior.'
              : 'Cambios guardados.',
        );
      }

      setState(() => _guardando = false);
      Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      _pendienteConfirmar = false;
      _mensaje(error.message.toString());
    } on PostgrestException catch (error) {
      debugPrint('Error al guardar el lugar: $error');

      if (error.code == '42501' || error.code == '23514') {
        _pendienteConfirmar = false;
        _mensaje('Supabase rechazó el guardado. Revisa la sesión y los datos.');
      } else {
        _mensaje('No pudimos confirmar el guardado. Intenta nuevamente.');
      }
    } on StorageException catch (error) {
      debugPrint('Error al subir la fotografía: $error');
      _mensaje('No se pudo subir la fotografía. Revisa tu conexión.');
    } catch (error) {
      debugPrint('Error al guardar: $error');
      _mensaje(
        _pendienteConfirmar
            ? 'No pudimos confirmar el guardado. Reintenta sin cambiar los datos.'
            : 'No pudimos guardar el lugar. Intenta nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
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

  InputDecoration _decoracion(String texto) {
    return InputDecoration(
      labelText: texto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _vistaFoto() {
    if (_foto != null) {
      return Image.memory(
        _foto!,
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (_fotoActual != null) {
      return SizedBox(
        height: 210,
        child: FutureBuilder<String>(
          future: _fotoActual,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'No se pudo mostrar la foto actual.\n'
                  'Se conservará si no eliges otra.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Image.network(
              snapshot.data!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const Center(
                child: Text('No se pudo mostrar la foto actual.'),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = {
      ..._categorias,
      if (_categoria != null) _categoria!,
    }.toList();

    return PopScope(
      canPop: !_ocupado,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editando ? 'Editar lugar' : 'Añadir lugar'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formulario,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _nombre,
                    enabled: !_bloqueado,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoracion('Nombre del lugar'),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Escribe el nombre del lugar.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: _decoracion('Categoría'),
                    items: categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: _bloqueado
                        ? null
                        : (valor) => setState(() => _categoria = valor),
                    validator: (valor) =>
                        valor == null ? 'Elige una categoría.' : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fotografía',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _vistaFoto(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _bloqueado ? null : _elegirFoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _eligiendoFoto
                          ? 'Abriendo foto…'
                          : _foto != null || _editando
                              ? 'Cambiar fotografía'
                              : 'Elegir fotografía',
                    ),
                  ),
                  const Text('JPG, PNG o WEBP. Máximo 5 MB.'),
                  const SizedBox(height: 24),
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toca el mapa para marcar el lugar '
                    'o utiliza tu ubicación actual.',
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _bloqueado ? null : _miUbicacion,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _localizando ? 'Obteniendo ubicación…' : 'Mi ubicación',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 340,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapa,
                        options: MapOptions(
                          initialCenter:
                              _punto ?? const LatLng(22.1565, -100.9855),
                          initialZoom: _editando ? 15 : 13,
                          minZoom: 3,
                          maxZoom: 18,
                          onMapReady: () => _mapaListo = true,
                          onTap: (_, punto) {
                            if (_bloqueado) return;

                            setState(() {
                              _punto = LatLng(
                                punto.latitude,
                                (punto.longitude + 180) % 360 - 180,
                              );
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'mx.edu.examenp2.mislugares',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_ubicacion != null)
                                Marker(
                                  point: _ubicacion!,
                                  width: 24,
                                  height: 24,
                                  child: const Tooltip(
                                    message: 'Tu ubicación',
                                    child: Icon(
                                      Icons.circle,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              if (_punto != null)
                                Marker(
                                  point: _punto!,
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 44,
                                    color: Color(0xFF26735C),
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _punto == null
                        ? 'Aún no seleccionas una ubicación.'
                        : 'Ubicación seleccionada: '
                            '${_punto!.latitude.toStringAsFixed(5)}, '
                            '${_punto!.longitude.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 24),
                  if (_pendienteConfirmar && !_guardando)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Conservamos los datos del intento anterior. '
                        'Reintenta para confirmar el guardado.',
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _ocupado ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _guardando
                          ? 'Guardando…'
                          : _pendienteConfirmar
                              ? 'Reintentar guardado'
                              : _editando
                                  ? 'Guardar cambios'
                                  : 'Guardar lugar',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}