import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  // Consultar la sesión actual.
  Session? get sesionActual => _client.auth.currentSession;

  // Detectar cuando el usuario entra o sale.
  Stream<AuthState> get cambiosSesion =>
      _client.auth.onAuthStateChange;

  Future<AuthResponse> registrarse({
    required String correo,
    required String contrasena,
  }) async {
    return await _client.auth.signUp(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<AuthResponse> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    return await _client.auth.signInWithPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }
}