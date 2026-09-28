import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> obtenerDatosEspn({int semana = 3}) async {
  final url = Uri.parse(
    'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard',
  );

  final respuesta = await http.get(url);

  if (respuesta.statusCode == 200) {
    return jsonDecode(respuesta.body) as Map<String, dynamic>;
  } else {
    throw Exception('No se pudieron obtener los partidos');
  }
}



