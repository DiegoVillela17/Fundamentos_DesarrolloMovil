import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  String? _error;

  static const _verde = Color(0xFF26735C);

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _authService.iniciarSesion(
        correo: _correoController.text,
        contrasena: _contrasenaController.text,
      );
     
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'invalid_credentials' => 'El correo o la contraseña son incorrectos.',
          'email_not_confirmed' =>
            'Esta cuenta tiene pendiente la confirmación de correo.',
          'over_request_rate_limit' =>
            'Espera un momento antes de volver a intentarlo.',
          _ => 'No se pudo iniciar sesión: ${error.message}',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos conectar. Revisa tu conexión e intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFE2F1E9),
                      child: Icon(Icons.place_rounded, size: 48, color: _verde),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mis Lugares Favoritos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _verde,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 32),
                  const Text(
                    'Inicia sesión',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _correoController,
                            enabled: !_cargando,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            decoration: _decoracion(
                              'Correo electrónico',
                              Icons.mail_outline,
                            ),
                            validator: (value) {
                              final correo = (value ?? '').trim();
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(correo)) {
                                return 'Escribe un correo válido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _contrasenaController,
                            enabled: !_cargando,
                            obscureText: _ocultarContrasena,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _iniciarSesion(),
                            decoration:
                                _decoracion(
                                  'Contraseña',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _ocultarContrasena
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () => setState(() {
                                      _ocultarContrasena = !_ocultarContrasena;
                                    }),
                                    icon: Icon(
                                      _ocultarContrasena
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Escribe tu contraseña.';
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFB3261E)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: FilledButton.styleFrom(
                              backgroundColor: _verde,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _cargando
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _error = null);
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const RegistroScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: _verde,
                            ),
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: _verde),
      filled: true,
      fillColor: Colors.white,
      errorMaxLines: 3,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _verde, width: 2),
      ),
    );
  }
}
