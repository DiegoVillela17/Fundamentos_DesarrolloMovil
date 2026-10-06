import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _registro = false, _cargando = false, _ocultar = true;
  String? _error, _mensaje;
  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_cargando || !_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _mensaje = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_registro) {
        final respuesta = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'nombre': _nombre.text.trim()},
        );
        if (!mounted) return;
        if (respuesta.session == null) {
          setState(() {
            _registro = false;
            _password.clear();
            _confirmacion.clear();
            _mensaje =
                'Revisa tu correo para confirmar la cuenta. Después inicia sesión aquí.';
          });
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = switch (e.code) {
          'invalid_credentials' =>
            'El correo o la contraseña no son correctos.',
          'email_not_confirmed' =>
            'Confirma tu correo antes de iniciar sesión.',
          'user_already_exists' => 'Ese correo ya está registrado.',
          'over_email_send_rate_limit' || 'over_request_rate_limit' =>
            'Se hicieron varios intentos. Espera un momento y vuelve a intentar.',
          'weak_password' =>
            'La contraseña no cumple los requisitos de Supabase.',
          _ => 'No se pudo completar el acceso: ${e.message}',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo conectar. Revisa tu conexión a internet.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: amarillo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pizza_rounded,
                      size: 58,
                      color: rojo,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'PizzApp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    color: rojo,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Tu próxima pizza empieza aquí',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _registro ? 'Crea tu cuenta' : '¡Bienvenido!',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _registro
                                ? 'Regístrate para hacer tu primer pedido.'
                                : 'Inicia sesión para ordenar.',
                          ),
                          const SizedBox(height: 24),
                          if (_registro) ...[
                            TextFormField(
                              controller: _nombre,
                              enabled: !_cargando,
                              maxLength: 120,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.trim().length < 2
                                  ? 'Escribe tu nombre.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _email,
                            enabled: !_cargando,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (v) =>
                                v == null ||
                                    !RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(v.trim())
                                ? 'Escribe un correo válido.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !_cargando,
                            obscureText: _ocultar,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _ocultar
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () =>
                                    setState(() => _ocultar = !_ocultar),
                                icon: Icon(
                                  _ocultar
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) {
                              if (!_registro) _enviar();
                            },
                            validator: (v) => v == null || v.isEmpty
                                ? 'Escribe tu contraseña.'
                                : _registro && v.length < 8
                                ? 'Usa al menos 8 caracteres.'
                                : null,
                          ),
                          if (_registro) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmacion,
                              enabled: !_cargando,
                              obscureText: _ocultar,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              onFieldSubmitted: (_) => _enviar(),
                              validator: (v) => v != _password.text
                                  ? 'Las contraseñas no coinciden.'
                                  : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: rojo)),
                          ],
                          if (_mensaje != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _mensaje!,
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _cargando ? null : _enviar,
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _registro
                                        ? 'Registrarme'
                                        : 'Iniciar sesión',
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _cargando
                                ? null
                                : () => setState(() {
                                    _registro = !_registro;
                                    _error = null;
                                    _mensaje = null;
                                    _form.currentState?.reset();
                                  }),
                            child: Text(
                              _registro
                                  ? 'Ya tengo cuenta'
                                  : '¿No tienes cuenta? Regístrate',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pizzas recién hechas, listas para recoger.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
