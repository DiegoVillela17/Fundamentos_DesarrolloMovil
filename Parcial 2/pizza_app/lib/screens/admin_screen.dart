import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  final AppStore store;
  const AdminScreen({super.key, required this.store});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _eliminando = false;
  @override
  Widget build(BuildContext context) {
    if (!widget.store.esAdmin) {
      return const Vacio(
        icono: Icons.lock_outline,
        titulo: 'Acceso de administrador',
        descripcion: 'Tu cuenta no tiene permiso para administrar pizzas.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Administrar pizzas',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              onPressed: _eliminando ? null : () => _formulario(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva pizza'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Agrega, consulta, edita y elimina productos de tu menú.'),
        const SizedBox(height: 20),
        if (widget.store.pizzas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay pizzas. Agrega el primer producto.'),
          ),
        for (final pizza in widget.store.pizzas)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 64,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FotoPizza(url: pizza.imagenUrl, altura: 64),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pizza.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text('${dinero(pizza.precio)} · Mediana'),
                              Text(
                                pizza.disponible
                                    ? 'Disponible'
                                    : 'No disponible',
                                style: TextStyle(
                                  color: pizza.disponible
                                      ? Colors.green.shade800
                                      : rojo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(pizza.descripcion),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _eliminando
                              ? null
                              : () => _formulario(pizza),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: _eliminando
                              ? null
                              : () => _eliminar(pizza),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
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

  Future<void> _formulario([Pizza? pizza]) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PizzaForm(store: widget.store, pizza: pizza),
    );
    if (guardado == true && mounted) {
      await widget.store.cargar();
      if (mounted) avisar(context, 'Pizza guardada.');
    }
  }

  Future<void> _eliminar(Pizza pizza) async {
    final eliminar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar pizza?'),
        content: Text(
          'Se eliminará ${pizza.nombre} del catálogo.\nLos pedidos anteriores conservarán su detalle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (eliminar != true || !mounted) return;
    setState(() => _eliminando = true);
    try {
      await widget.store.service.eliminarPizza(pizza.id);
      await widget.store.cargar();
      if (mounted) avisar(context, 'Pizza eliminada.');
    } catch (_) {
      if (mounted) {
        avisar(context, 'No se pudo eliminar la pizza.', error: true);
      }
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }
}

class _PizzaForm extends StatefulWidget {
  final AppStore store;
  final Pizza? pizza;
  const _PizzaForm({required this.store, this.pizza});
  @override
  State<_PizzaForm> createState() => _PizzaFormState();
}

class _PizzaFormState extends State<_PizzaForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre, _descripcion, _precio, _imagen;
  late bool _disponible;
  bool _guardando = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.pizza?.nombre ?? '');
    _descripcion = TextEditingController(text: widget.pizza?.descripcion ?? '');
    _precio = TextEditingController(
      text: widget.pizza?.precio.toStringAsFixed(2) ?? '',
    );
    _imagen = TextEditingController(text: widget.pizza?.imagenUrl ?? '');
    _disponible = widget.pizza?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _imagen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_guardando,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.pizza == null ? 'Nueva pizza' : 'Editar pizza',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombre,
              enabled: !_guardando,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un nombre.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descripcion,
              enabled: !_guardando,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Describe la pizza.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _precio,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio de la mediana (MXN)',
                prefixText: '\$ ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return n == null || !n.isFinite || n <= 0 || n > 999999
                    ? 'Escribe un precio entre 0.01 y 999999.'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imagen,
              enabled: !_guardando,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL de imagen (opcional)',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                return uri == null || uri.scheme != 'https' || uri.host.isEmpty
                    ? 'Usa una URL que empiece por https://.'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible para ordenar'),
              value: _disponible,
              onChanged: _guardando
                  ? null
                  : (v) => setState(() => _disponible = v),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: rojo)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar pizza'),
            ),
            TextButton(
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.store.service.guardarPizza(
        id: widget.pizza?.id,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        precio: double.parse(_precio.text.replaceAll(',', '.')),
        imagenUrl: _imagen.text.trim(),
        disponible: _disponible,
      );
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == '23505'
              ? 'Ya existe una pizza con ese nombre.'
              : 'No se pudo guardar: ${e.message}',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
