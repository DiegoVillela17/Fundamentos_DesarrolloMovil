import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<Map<String, dynamic>>> obtenerCanciones() async {
  return await Supabase.instance.client
      .from('canciones')
      .select()
      .order('favorita', ascending: false)
      .order('anio', ascending: false, nullsFirst: false)
      .order('id');
}

Future<void> actualizarFavorita(int id, bool favorita) async {
  final resultado = await Supabase.instance.client
      .from('canciones')
      .update({'favorita': favorita})
      .eq('id', id)
      .select('id');

  if (resultado.isEmpty) {
    throw Exception('No se actualizó la canción.');
  }
}

Future<void> agregarCancion(Map<String, dynamic> datos) async {
  await Supabase.instance.client
      .from('canciones')
      .insert(datos)
      .select()
      .single();
}

Future<void> eliminarCancion(int id) async {
  final resultado = await Supabase.instance.client
      .from('canciones')
      .delete()
      .eq('id', id)
      .select('id');

  if (resultado.isEmpty) {
    throw Exception('No se eliminó la canción.');
  }
}