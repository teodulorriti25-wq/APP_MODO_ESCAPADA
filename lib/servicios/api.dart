// Servicio HTTP. Las vistas nunca construyen peticiones ni manejan credenciales SQL.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ErrorApi implements Exception {
  final String mensaje;
  final int estado;
  ErrorApi(this.mensaje, [this.estado = 0]);
  @override
  String toString() => mensaje;
}

class Api {
  final String base = 'https://modoescapada.onrender.com/api/v1';
  String? token;
  VoidCallback? sesionCaducada;
  final http.Client _http = http.Client();

  Future<dynamic> pedir(
    String metodo,
    String ruta, {
    Map<String, dynamic>? datos,
  }) async {
    final peticion = http.Request(metodo, Uri.parse('$base$ruta'));
    peticion.headers['Content-Type'] = 'application/json';
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
    if (datos != null) peticion.body = jsonEncode(datos);
    try {
      final flujo = await _http
          .send(peticion)
          .timeout(const Duration(seconds: 20));
      final respuesta = await http.Response.fromStream(
        flujo,
      ).timeout(const Duration(seconds: 20));
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (respuesta.statusCode >= 400) {
        if (respuesta.statusCode == 401 && token != null) {
          sesionCaducada?.call();
        }
        throw ErrorApi(
          contenido['error']?['mensaje'] ??
              'No pudimos completar esta operación.',
          respuesta.statusCode,
        );
      }
      return contenido;
    } on TimeoutException {
      throw ErrorApi(
        'La conexión tardó demasiado. Comprueba el servidor y vuelve a intentar.',
      );
    } on http.ClientException {
      throw ErrorApi(
        'No pudimos conectar. Revisa la dirección del servidor y tu red.',
      );
    } on FormatException {
      throw ErrorApi(
        'La dirección respondió con datos inesperados. Comprueba que sea la API.',
      );
    }
  }
}
