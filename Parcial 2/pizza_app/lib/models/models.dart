class Pizza {
  final int id;
  final String nombre, descripcion, imagenUrl;
  final double precio;
  final bool disponible;
  const Pizza({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.precio,
    required this.disponible,
  });
  factory Pizza.fromJson(Map<String, dynamic> j) => Pizza(
    id: (j['id'] as num).toInt(),
    nombre: j['nombre'] as String,
    descripcion: j['descripcion'] as String? ?? '',
    imagenUrl: j['imagen_url'] as String? ?? '',
    precio: (j['precio'] as num).toDouble(),
    disponible: j['disponible'] as bool? ?? true,
  );
}

class Sucursal {
  final int id;
  final String nombre, direccion;
  final double latitud, longitud;
  const Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });
  factory Sucursal.fromJson(Map<String, dynamic> j) => Sucursal(
    id: (j['id'] as num).toInt(),
    nombre: j['nombre'] as String,
    direccion: j['direccion'] as String,
    latitud: (j['latitud'] as num).toDouble(),
    longitud: (j['longitud'] as num).toDouble(),
  );
}

class ItemCarrito {
  final Pizza pizza;
  final String tamano;
  final int cantidad;
  final double multiplicador;
  const ItemCarrito({
    required this.pizza,
    required this.tamano,
    required this.cantidad,
    required this.multiplicador,
  });
  String get clave => '${pizza.id}:$tamano';
  // Mismo redondeo a centavos que el cálculo de PostgreSQL.
  double get precioUnitario =>
      (pizza.precio * multiplicador * 100).round() / 100;
  double get total => precioUnitario * cantidad;
  ItemCarrito conCantidad(int n) => ItemCarrito(
    pizza: pizza,
    tamano: tamano,
    cantidad: n,
    multiplicador: multiplicador,
  );
  Map<String, dynamic> toPedidoJson() => {
    'pizza_id': pizza.id,
    'tamano': tamano,
    'cantidad': cantidad,
  };
}

class DetallePedido {
  final String nombre, tamano;
  final int cantidad;
  final double precio;
  const DetallePedido({
    required this.nombre,
    required this.tamano,
    required this.cantidad,
    required this.precio,
  });
  factory DetallePedido.fromJson(Map<String, dynamic> j) => DetallePedido(
    nombre: j['nombre_pizza'] as String,
    tamano: j['tamano'] as String,
    cantidad: (j['cantidad'] as num).toInt(),
    precio: (j['precio_unitario'] as num).toDouble(),
  );
}

class Pedido {
  final int id;
  final String sucursal, estado;
  final DateTime fecha;
  final double total;
  final List<DetallePedido> detalles;
  const Pedido({
    required this.id,
    required this.sucursal,
    required this.estado,
    required this.fecha,
    required this.total,
    required this.detalles,
  });
  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
    id: (j['id'] as num).toInt(),
    sucursal:
        (j['sucursales'] as Map<String, dynamic>?)?['nombre'] as String? ??
        'Sucursal',
    estado: j['estado'] as String,
    fecha: DateTime.parse(j['creado_en'] as String).toLocal(),
    total: (j['total'] as num).toDouble(),
    detalles: (j['detalle_pedidos'] as List? ?? [])
        .map((d) => DetallePedido.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList(),
  );
}
