import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmacionController = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  String? _error;

  static const _verde = Color(0xFF26735C);

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await _authService.registrarse(
        correo: _correoController.text,
        contrasena: _contrasenaController.text,
      );

      if (!mounted) return;

      final mensaje = respuesta.session != null
          ? '¡Tu cuenta está lista!'
          : 'Revisa tu correo para confirmar la cuenta y después inicia sesión.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

      // Esta pantalla se abrirá desde Login con Navigator.push.
      // Al regresar, la pantalla principal resolverá la sesión de Supabase.
      setState(() => _cargando = false);
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = switch (error.code) {
          'user_already_exists' || 'email_exists' =>
            'Este correo ya está registrado. Intenta iniciar sesión.',
          'email_address_invalid' || 'validation_failed' =>
            'Revisa que el correo tenga un formato válido.',
          'weak_password' =>
            'La contraseña no cumple los requisitos. Prueba una más segura.',
          'over_email_send_rate_limit' || 'over_request_rate_limit' =>
            'Espera un momento antes de volver a intentarlo.',
          'signup_disabled' => 'El registro de cuentas está deshabilitado.',
          _ => 'No se pudo crear la cuenta: ${error.message}',
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
    return PopScope(
      canPop: !_cargando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF8),
        appBar: AppBar(
          title: const Text('Crear cuenta'),
          backgroundColor: const Color(0xFFF6FBF8),
          foregroundColor: _verde,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: _cargando ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
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
                        radius: 36,
                        backgroundColor: Color(0xFFE2F1E9),
                        child: Icon(
                          Icons.place_rounded,
                          size: 42,
                          color: _verde,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tus lugares, contigo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _verde,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta y comienza a guardar tus lugares favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF53685D), height: 1.5),
                    ),
                    const SizedBox(height: 28),
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
                              autofillHints: const [AutofillHints.email],
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
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration:
                                  _decoracion(
                                    'Contraseña',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    helperText: 'Al menos 8 caracteres',
                                    suffixIcon: IconButton(
                                      tooltip: _ocultarContrasena
                                          ? 'Mostrar contraseñas'
                                          : 'Ocultar contraseñas',
                                      onPressed: () => setState(() {
                                        _ocultarContrasena =
                                            !_ocultarContrasena;
                                      }),
                                      icon: Icon(
                                        _ocultarContrasena
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                if (value == null || value.length < 8) {
                                  return 'Usa al menos 8 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _confirmacionController,
                              enabled: !_cargando,
                              obscureText: _ocultarContrasena,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              decoration: _decoracion(
                                'Confirmar contraseña',
                                Icons.lock_outline,
                              ),
                              onFieldSubmitted: (_) => _registrarse(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Repite la contraseña.';
                                }
                                if (value != _contrasenaController.text) {
                                  return 'Las contraseñas no coinciden.';
                                }
                                return null;
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _cargando ? null : _registrarse,
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
                                  : const Text('Registrarme'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _cargando
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: _verde,
                              ),
                              child: const Text(
                                'Ya tengo cuenta. Iniciar sesión',
                              ),
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
