import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';

class SucursalesScreen extends StatefulWidget {
  final AppStore store;
  const SucursalesScreen({super.key, required this.store});
  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  final _mapa = MapController();
  int? _seleccionada;
  bool _listo = false;
  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sucursales = widget.store.sucursales;
    if (sucursales.isEmpty) {
      return const Vacio(
        icono: Icons.place_outlined,
        titulo: 'No hay sucursales disponibles',
        descripcion: 'Vuelve a consultar más tarde.',
      );
    }
    final seleccionada = sucursales.firstWhere(
      (s) => s.id == _seleccionada,
      orElse: () => sucursales.first,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Encuentra tu sucursal',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Elige dónde recoger tu próxima pizza.'),
        const SizedBox(height: 20),
        SizedBox(
          height: 340,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: LatLng(
                  seleccionada.latitud,
                  seleccionada.longitud,
                ),
                initialZoom: 13,
                minZoom: 3,
                maxZoom: 18,
                onMapReady: () => _listo = true,
              ),
              children: [
                // Servicio HTTP de mapas de OpenStreetMap; las coordenadas vienen de Supabase.
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'mx.edu.pizzapp.escolar',
                ),
                MarkerLayer(
                  markers: sucursales
                      .map(
                        (s) => Marker(
                          point: LatLng(s.latitud, s.longitud),
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: s.nombre,
                            onPressed: () => _seleccionar(s),
                            icon: Icon(
                              Icons.location_on,
                              size: 40,
                              color: s.id == seleccionada.id
                                  ? rojo
                                  : Colors.brown,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final s in sucursales)
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
                        const Icon(Icons.storefront, color: rojo),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(s.direccion),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _seleccionar(s),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ver en el mapa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _seleccionar(Sucursal s) {
    setState(() => _seleccionada = s.id);
    if (_listo) _mapa.move(LatLng(s.latitud, s.longitud), 15);
  }
}
