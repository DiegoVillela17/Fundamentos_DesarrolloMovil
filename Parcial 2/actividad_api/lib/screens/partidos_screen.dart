import 'package:flutter/material.dart';
import '../widgets/partido_card.dart';

class PartidosScreen extends StatelessWidget {
  final List<dynamic> partidos;

  const PartidosScreen({
    super.key,
    required this.partidos,
  });

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.red, 
      title: const Text(
        'NFL MatchTracker',
        style: TextStyle(
          color: Colors.white, 
          fontSize: 22,
          fontWeight: FontWeight.bold, 
          // fontFamily: 'NombreDeTuFuente', 
        ),
      ),
    ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: partidos.length,

        itemBuilder: (context, index) {
          final partido = partidos[index];

          final competencia = partido['competitions'][0];
          final equipos = competencia['competitors'];

          String visitante = 'Visitante';
          String local = 'Local';
          String puntosVisitante = '0';
          String puntosLocal = '0';

          String logoVisitante = '';
          String logoLocal = '';

          final estado =
              competencia['status']['type']['description'].toString();

          final fechaEspn =
              DateTime.parse(partido['date']).toLocal();

          final fecha =
              '${fechaEspn.day}/${fechaEspn.month}/${fechaEspn.year} '
              '${fechaEspn.hour.toString().padLeft(2, '0')}:'
              '${fechaEspn.minute.toString().padLeft(2, '0')}';

          for (int i = 0; i < equipos.length; i++) {
            final equipo = equipos[i];

            if (equipo['homeAway'] == 'home') {
              local = equipo['team']['displayName'];
              puntosLocal = equipo['score'].toString();
              logoLocal = (equipo['team']['logo'] ?? '').toString();
            }

            if (equipo['homeAway'] == 'away') {
              visitante = equipo['team']['displayName'];
              puntosVisitante = equipo['score'].toString();
              logoVisitante = (equipo['team']['logo'] ?? '').toString();
            }
          }

          return PartidoCard(
            visitante: visitante,
            local: local,
            puntosVisitante: puntosVisitante,
            puntosLocal: puntosLocal,
            fecha: fecha,
            estado: estado,
            logoVisitante: logoVisitante,
            logoLocal: logoLocal,
          );
        },
      ),
    );
  }
}