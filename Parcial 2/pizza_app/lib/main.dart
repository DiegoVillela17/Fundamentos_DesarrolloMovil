import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    runApp(const PizzApp());
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Vacio(
            icono: Icons.cloud_off,
            titulo: 'No se pudo iniciar PizzApp',
            descripcion:
                'Revisa la conexión y la configuración de Supabase. Reinicia la app.',
          ),
        ),
      ),
    );
  }
}

class PizzApp extends StatelessWidget {
  const PizzApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PizzApp',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: amarillo,
        primary: rojo,
        secondary: amarillo,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: amarillo,
        foregroundColor: texto,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF0E5D0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: amarillo.withValues(alpha: .35),
      ),
    ),
    home: const _AuthGate(),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = auth.currentUser;
        return user == null
            ? const AuthScreen()
            : HomeScreen(key: ValueKey(user.id));
      },
    );
  }
}
