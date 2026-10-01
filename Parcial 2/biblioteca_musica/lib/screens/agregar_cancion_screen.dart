import 'package:flutter/material.dart';
import '../services/canciones_service.dart';

class AgregarCancionScreen extends StatefulWidget {
  const AgregarCancionScreen({super.key});

  @override
  State<AgregarCancionScreen> createState() =>
      _AgregarCancionScreenState();
}

class _AgregarCancionScreenState extends State<AgregarCancionScreen> {
  final formulario = GlobalKey<FormState>();

  String titulo = '';
  String artista = '';
  String album = '';
  int? anio;
  int? duracion;
  bool favorita = false;
  bool guardando = false;

  String? validarTexto(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Campo obligatorio.';
    if (texto.length > 120) return 'Máximo 120 caracteres.';
    return null;
  }

  Future<void> guardar() async {
    if (guardando || !formulario.currentState!.validate()) return;

    formulario.currentState!.save();
    setState(() => guardando = true);

    try {
      await agregarCancion({
        'titulo': titulo,
        'artista': artista,
        'album': album.isEmpty ? null : album,
        'anio': anio,
        'duracion_seg': duracion,
        'favorita': favorita,
      });

      if (!mounted) return;
      setState(() => guardando = false);
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Error al guardar: $error');
      if (!mounted) return;

      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la canción.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !guardando,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF1F6),
        appBar: AppBar(
          title: const Text('Agregar canción'),
          backgroundColor: const Color(0xFFF8BBD0),
          foregroundColor: const Color(0xFF4A1930),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  enabled: !guardando,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: validarTexto,
                  onSaved: (valor) => titulo = valor!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !guardando,
                  decoration: const InputDecoration(labelText: 'Artista *'),
                  validator: validarTexto,
                  onSaved: (valor) => artista = valor!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !guardando,
                  decoration: const InputDecoration(
                    labelText: 'Álbum (opcional)',
                  ),
                  onSaved: (valor) => album = valor?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !guardando,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Año (opcional)',
                  ),
                  validator: (valor) {
                    final texto = valor?.trim() ?? '';
                    if (texto.isEmpty) return null;

                    final numero = int.tryParse(texto);
                    if (numero == null || numero < 1900 || numero > 2100) {
                      return 'Escribe un año entre 1900 y 2100.';
                    }
                    return null;
                  },
                  onSaved: (valor) {
                    anio = int.tryParse(valor?.trim() ?? '');
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !guardando,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duración en segundos (opcional)',
                  ),
                  validator: (valor) {
                    final texto = valor?.trim() ?? '';
                    if (texto.isEmpty) return null;

                    final numero = int.tryParse(texto);
                    if (numero == null ||
                        numero <= 0 ||
                        numero > 2147483647) {
                      return 'Escribe una cantidad entera positiva válida.';
                    }
                    return null;
                  },
                  onSaved: (valor) {
                    duracion = int.tryParse(valor?.trim() ?? '');
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favorita'),
                  value: favorita,
                  onChanged: guardando
                      ? null
                      : (valor) => setState(() => favorita = valor),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: guardando ? null : guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFAD1457),
                  ),
                  child: Text(guardando ? 'Guardando...' : 'Guardar canción'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}