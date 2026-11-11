import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final temaGuardado = await AdaptiveTheme.getThemeMode();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );

    runApp(PizzApp(temaGuardado: temaGuardado));
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
  final AdaptiveThemeMode? temaGuardado;

  const PizzApp({super.key, this.temaGuardado});

  ThemeData _crearTema(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;

    final colores = ColorScheme.fromSeed(
      seedColor: amarillo,
      brightness: brillo,
      primary: oscuro ? const Color(0xFFFF8A80) : rojo,
      secondary: amarillo,
      surface: oscuro ? const Color(0xFF242424) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: colores,
      scaffoldBackgroundColor:
          oscuro ? const Color(0xFF151515) : fondo,
      appBarTheme: AppBarTheme(
        backgroundColor: oscuro ? colores.surface : amarillo,
        foregroundColor: oscuro ? colores.onSurface : texto,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colores.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: oscuro
                ? colores.outlineVariant
                : const Color(0xFFF0E5D0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oscuro ? colores.surfaceContainerHighest : fondo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
        backgroundColor: colores.surface,
        indicatorColor: amarillo.withValues(alpha: .35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: _crearTema(Brightness.light),
      dark: _crearTema(Brightness.dark),
      initial: temaGuardado ?? AdaptiveThemeMode.light,
      builder: (temaClaro, temaOscuro) => MaterialApp(
        title: 'PizzApp',
        debugShowCheckedModeBanner: false,
        theme: temaClaro,
        darkTheme: temaOscuro,
        home: const _AuthGate(),
      ),
    );
  }
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