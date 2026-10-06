import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/pizzapp_service.dart';

// ChangeNotifier es suficiente para esta app; no requiere Riverpod ni Provider.
class AppStore extends ChangeNotifier {
  final PizzappService service;
  AppStore(this.service);
  List<Pizza> pizzas = [];
  List<Sucursal> sucursales = [];
  List<Pedido> pedidos = [];
  Map<String, double> tamanos = {};
  final List<ItemCarrito> _carrito = [];
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);
  String nombre = '';
  bool esAdmin = false, cargando = true, confirmando = false;
  String? error;
  bool _disposed = false;
  int _revision = 0;
  int get cantidad => _carrito.fold(0, (n, i) => n + i.cantidad);
  double get total => _carrito.fold(0, (n, i) => n + i.total);
  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> cargar() async {
    final revision = ++_revision;
    cargando = true;
    error = null;
    _avisar();
    try {
      final datos = await Future.wait<dynamic>([
        service.obtenerPizzas(),
        service.obtenerSucursales(),
        service.obtenerTamanos(),
        service.obtenerPerfil(),
        service.obtenerPedidos(),
      ]);
      if (_disposed || revision != _revision) return;
      pizzas = datos[0] as List<Pizza>;
      sucursales = datos[1] as List<Sucursal>;
      tamanos = datos[2] as Map<String, double>;
      final perfil = datos[3] as Map<String, dynamic>;
      nombre = perfil['nombre'] as String? ?? '';
      esAdmin = perfil['rol'] == 'admin';
      pedidos = datos[4] as List<Pedido>;
    } catch (e) {
      if (_disposed || revision != _revision) return;
      error =
          'No se pudieron cargar los datos. Revisa tu conexión y vuelve a intentar.';
      debugPrint('Carga de PizzApp: $e');
    } finally {
      if (!_disposed && revision == _revision) {
        cargando = false;
        _avisar();
      }
    }
  }

  void agregar(Pizza pizza, String tamano, int cantidad) {
    if (confirmando) throw StateError('Espera a que termine el pedido.');
    final factor = tamanos[tamano];
    if (!pizza.disponible || factor == null) {
      throw StateError('Producto no disponible.');
    }
    if (cantidad < 1 || cantidad > 99) throw StateError('Cantidad inválida.');
    final index = _carrito.indexWhere(
      (i) => i.pizza.id == pizza.id && i.tamano == tamano,
    );
    if (index < 0 && _carrito.length >= 50) {
      throw StateError('Máximo 50 productos diferentes.');
    }
    if (index >= 0) {
      final nueva = _carrito[index].cantidad + cantidad;
      if (nueva > 99) throw StateError('Máximo 99 pizzas por tamaño.');
      _carrito[index] = _carrito[index].conCantidad(nueva);
    } else {
      _carrito.add(
        ItemCarrito(
          pizza: pizza,
          tamano: tamano,
          cantidad: cantidad,
          multiplicador: factor,
        ),
      );
    }
    _avisar();
  }

  void cambiarCantidad(String clave, int nueva) {
    if (confirmando || nueva > 99) return;
    final index = _carrito.indexWhere((i) => i.clave == clave);
    if (index < 0) return;
    if (nueva <= 0) {
      _carrito.removeAt(index);
    } else {
      _carrito[index] = _carrito[index].conCantidad(nueva);
    }
    _avisar();
  }

  void quitar(String clave) {
    if (confirmando) return;
    _carrito.removeWhere((i) => i.clave == clave);
    _avisar();
  }

  Future<int> confirmar(int sucursalId) async {
    if (confirmando) throw StateError('El pedido ya se está procesando.');
    if (_carrito.isEmpty) throw StateError('El carrito está vacío.');
    confirmando = true;
    _avisar();
    try {
      // El servidor valida disponibilidad y calcula precios, no confía en el total del cliente.
      final id = await service.crearPedido(sucursalId, List.of(_carrito));
      _carrito.clear();
      _avisar();
      await cargar(); // Un fallo de recarga no convierte un pedido exitoso en fallido.
      return id;
    } finally {
      confirmando = false;
      _avisar();
    }
  }
}
