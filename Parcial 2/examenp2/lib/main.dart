import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/inicio_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MisLugaresApp());
}

class MisLugaresApp extends StatelessWidget {
  const MisLugaresApp({super.key});

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF26735C);

    return MaterialApp(
      title: 'Mis Lugares Favoritos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: verde, primary: verde),
        scaffoldBackgroundColor: const Color(0xFFF6FBF8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6FBF8),
          foregroundColor: verde,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const ControlSesion(),
    );
  }
}

class ControlSesion extends StatefulWidget {
  const ControlSesion({super.key});

  @override
  State<ControlSesion> createState() => _ControlSesionState();
}

class _ControlSesionState extends State<ControlSesion> {
  final _authService = AuthService();
  late final Stream<AuthState> _cambiosSesion;

  @override
  void initState() {
    super.initState();
    _cambiosSesion = _authService.cambiosSesion;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _cambiosSesion,
      builder: (context, snapshot) {
        final sesion = _authService.sesionActual;
        final pantalla = sesion == null
            ? const LoginScreen()
            : InicioScreen(key: ValueKey(sesion.user.id));

       
        return Column(
          children: [
            if (snapshot.hasError)
              Material(
                color: const Color(0xFFFFF0CB),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No pudimos actualizar tu sesión. Revisa tu conexión.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: pantalla),
          ],
        );
      },
    );
  }
}
