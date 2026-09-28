-->import 'package:http/http.dart' as http; 

Nos permite usar el paquete que hace las solicitudes.
as http le asigna un nombre corto. Por eso después escribimos 
http.get(...): estamos usando la función get de ese paquete.

-->Creación de la función
-->Future<String> obtenerDatosEspn() async {

    Future<String>: Ese texto llegará cuando termine una operación 
    asíncrona, o la operación podría fallar.

    async: Permite usar await dentro de la función.

-->final url = Uri.parse(
  'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard',
);

    -url es nuestra variable.
    -final indica que no le asignaremos otro valor después.
    -Uri.parse(...) convierte el texto del enlace en un objeto Uri, 
que es el formato de dirección que espera http.get.

-->Consultar ESPN
-->final respuesta = await http.get(url);

    

