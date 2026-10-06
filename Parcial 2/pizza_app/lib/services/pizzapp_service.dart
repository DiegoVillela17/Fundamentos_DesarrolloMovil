import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

// Todas las consultas están aquí; las pantallas se encargan de la interfaz.
class PizzappService {
  final SupabaseClient client;
  PizzappService(this.client);

  Future<List<Pizza>> obtenerPizzas() async {
    final datos = await client.from('pizzas').select().order('id');
    return datos.map(Pizza.fromJson).toList();
  }

  Future<List<Sucursal>> obtenerSucursales() async {
    final datos = await client.from('sucursales').select().order('id');
    return datos.map(Sucursal.fromJson).toList();
  }

  Future<Map<String, double>> obtenerTamanos() async {
    final datos = await client.from('tamanos').select();
    return {
      for (final t in datos)
        t['nombre'] as String: (t['multiplicador'] as num).toDouble(),
    };
  }

  Future<Map<String, dynamic>> obtenerPerfil() async => await client
      .from('perfiles')
      .select()
      .eq('id', client.auth.currentUser!.id)
      .single();

  Future<List<Pedido>> obtenerPedidos() async {
    // RLS entrega sólo los pedidos del usuario; el administrador puede ver todos.
    final datos = await client
        .from('pedidos')
        .select('*, sucursales(nombre), detalle_pedidos(*)')
        .order('creado_en', ascending: false);
    return datos.map(Pedido.fromJson).toList();
  }

  Future<int> crearPedido(int sucursalId, List<ItemCarrito> items) async {
    final id = await client.rpc(
      'crear_pedido',
      params: {
        'p_sucursal_id': sucursalId,
        'p_items': items.map((i) => i.toPedidoJson()).toList(),
      },
    );
    return (id as num).toInt();
  }

  Future<void> guardarPizza({
    int? id,
    required String nombre,
    required String descripcion,
    required double precio,
    required String imagenUrl,
    required bool disponible,
  }) async {
    final datos = {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen_url': imagenUrl,
      'disponible': disponible,
    };
    if (id == null) {
      await client.from('pizzas').insert(datos);
    } else {
      await client.from('pizzas').update(datos).eq('id', id);
    }
  }

  Future<void> eliminarPizza(int id) async =>
      await client.from('pizzas').delete().eq('id', id);
  Future<void> cambiarEstado(int id, String estado) async =>
      await client.from('pedidos').update({'estado': estado}).eq('id', id);
}
