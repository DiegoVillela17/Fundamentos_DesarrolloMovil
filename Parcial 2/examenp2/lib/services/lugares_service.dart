import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lugar.dart';

class LugaresService {
  SupabaseClient get _cliente => Supabase.instance.client;
  static const _bucket = 'lugares-fotos';

  static String nuevoId() {
    final azar = Random.secure();
    final bytes = List.generate(16, (_) => azar.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static const maximoFotoBytes = 5 * 1024 * 1024;

  String get _usuarioId {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) {
      throw StateError('Inicia sesión para consultar o guardar lugares.');
    }
    return usuario.id;
  }

  Future<List<Lugar>> listar() async {
    final datos = await _cliente
        .from('lugares')
        .select()
        .eq('usuario_id', _usuarioId)
        .order('nombre');
    return datos.map((dato) => Lugar.fromMap(dato)).toList();
  }

  Future<Lugar> crear({
    String? id,
    required String nombre,
    required String categoria,
    required double latitud,
    required double longitud,
    required String fotoPath,
  }) async {
    final datos = _datos(nombre, categoria, latitud, longitud, fotoPath);
    if (id != null) datos['id'] = id;
    try {
      final resultado = await _cliente
          .from('lugares')
          .insert(datos)
          .select()
          .single();
      return Lugar.fromMap(resultado);
    } on PostgrestException catch (error) {
      // Un reintento reutiliza el mismo UUID: no crea dos registros si
      // el servidor guardó el primero pero se perdió la respuesta.
      if (id == null || error.code != '23505') rethrow;
      final existente = await _cliente
          .from('lugares')
          .select()
          .eq('id', id)
          .eq('usuario_id', _usuarioId)
          .single();
      return Lugar.fromMap(existente);
    }
  }

  // Si se cambia la foto, subir una nueva y conservar la anterior hasta
  // confirmar esta actualización. Después eliminarFoto con la ruta anterior.
  Future<Lugar> editar({
    required String id,
    required String nombre,
    required String categoria,
    required double latitud,
    required double longitud,
    required String fotoPath,
  }) async {
    final datos = _datos(nombre, categoria, latitud, longitud, fotoPath);
    final resultado = await _cliente
        .from('lugares')
        .update(datos)
        .eq('id', id)
        .eq('usuario_id', _usuarioId)
        .select()
        .single();
    return Lugar.fromMap(resultado);
  }

  Future<Lugar> eliminar(String id) async {
    final resultado = await _cliente
        .from('lugares')
        .delete()
        .eq('id', id)
        .eq('usuario_id', _usuarioId)
        .select()
        .single();
    return Lugar.fromMap(resultado);
  }

  Future<String> subirFoto(Uint8List bytes) async {
    final usuarioId = _usuarioId;
    if (bytes.isEmpty || bytes.length > maximoFotoBytes) {
      throw ArgumentError('Elige una fotografía de hasta 5 MB.');
    }
    final extension = _extensionImagen(bytes);
    final mime = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
    final azar = Random.secure();
    final identificador = List.generate(
      16,
      (_) => azar.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final ruta = '$usuarioId/$identificador.$extension';
    await _cliente.storage
        .from(_bucket)
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return ruta;
  }

  Future<String> obtenerUrlFoto(String ruta) async {
    _validarRuta(ruta);
    return _cliente.storage.from(_bucket).createSignedUrl(ruta, 3600);
  }

  Future<void> eliminarFoto(String ruta) async {
    _validarRuta(ruta);
    // Evitar borrar una imagen que todavía utiliza algún lugar del usuario.
    final referencias = await _cliente
        .from('lugares')
        .select('id')
        .eq('usuario_id', _usuarioId)
        .eq('foto_path', ruta)
        .limit(1);
    if (referencias.isNotEmpty) {
      throw StateError('Esta fotografía todavía está asociada a un lugar.');
    }
    await _cliente.storage.from(_bucket).remove([ruta]);
  }

  Map<String, dynamic> _datos(
    String nombre,
    String categoria,
    double latitud,
    double longitud,
    String fotoPath,
  ) {
    nombre = nombre.trim();
    categoria = categoria.trim();
    if (nombre.isEmpty || nombre.runes.length > 120) {
      throw ArgumentError('Escribe un nombre de 1 a 120 caracteres.');
    }
    if (categoria.isEmpty || categoria.runes.length > 50) {
      throw ArgumentError('Elige una categoría de 1 a 50 caracteres.');
    }
    if (!latitud.isFinite ||
        !longitud.isFinite ||
        latitud < -90 ||
        latitud > 90 ||
        longitud < -180 ||
        longitud > 180) {
      throw ArgumentError('Selecciona una ubicación válida en el mapa.');
    }
    _validarRuta(fotoPath);
    return {
      'nombre': nombre,
      'categoria': categoria,
      'latitud': latitud,
      'longitud': longitud,
      'foto_path': fotoPath,
    };
  }

  void _validarRuta(String ruta) {
    final partes = ruta.split('/');
    if (partes.length != 2 ||
        partes.first != _usuarioId ||
        partes.last.isEmpty ||
        partes.last == '.' ||
        partes.last == '..') {
      throw ArgumentError('La fotografía debe pertenecer a tu cuenta.');
    }
  }

  String _extensionImagen(Uint8List bytes) {
    bool coincide(List<int> firma, [int inicio = 0]) {
      if (bytes.length < inicio + firma.length) return false;
      for (var i = 0; i < firma.length; i++) {
        if (bytes[inicio + i] != firma[i]) return false;
      }
      return true;
    }

    if (coincide([0xff, 0xd8, 0xff])) return 'jpg';
    if (coincide([137, 80, 78, 71, 13, 10, 26, 10])) return 'png';
    if (coincide([82, 73, 70, 70]) && coincide([87, 69, 66, 80], 8)) {
      return 'webp';
    }
    throw ArgumentError('Selecciona una imagen JPG, PNG o WEBP.');
  }
}
