import 'modelos.dart';

class ViajeAdmin {
  final Paquete paquete;
  final String estado;
  final bool tieneApartados;

  ViajeAdmin.fromJson(Map<String, dynamic> datos)
    : paquete = Paquete.fromJson(datos),
      estado = datos['estado'],
      tieneApartados = datos['tiene_apartados'];

  bool get publicado => estado == 'publicado';
  String get etiquetaEstado => switch (estado) {
    'publicado' => 'Publicado',
    'archivado' => 'Archivado',
    _ => 'Borrador',
  };
}

class ReservaAdmin {
  final Apartado apartado;
  final String viaje, cliente, correo;
  final DateTime fechaSalida;
  final bool sePuedeCancelar;

  ReservaAdmin.fromJson(Map<String, dynamic> datos)
    : apartado = Apartado.fromJson(datos),
      viaje = datos['viaje_nombre'],
      cliente = datos['cliente_nombre'],
      correo = datos['cliente_correo'],
      fechaSalida = DateTime.parse(datos['fecha_salida']),
      sePuedeCancelar = datos['se_puede_cancelar'];
}
