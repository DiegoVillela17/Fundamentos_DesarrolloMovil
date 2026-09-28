import 'package:flutter/material.dart';
import 'services/espn_service.dart';
import 'screens/partidos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<dynamic> partidos = [];

  try {
    final contenido = await obtenerDatosEspn();

    partidos = contenido['events'];
  } catch (error) {
    debugPrint(error.toString());
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PartidosScreen(
        partidos: partidos,
      ),
    ),
  );
}