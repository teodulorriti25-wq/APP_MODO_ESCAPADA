import '../modelos/modelos.dart';
import '../servicios/api.dart';
import 'estado.dart';

class Viajes extends EstadoControlador {
  final Api api;
  List<Paquete> paquetes = [];
  List<Solicitud> historial = [];
  Solicitud? actual;
  bool cargando = true, enviando = false;
  String? error;
  Viajes(this.api);

  Future<void> cargar() async {
    cargando = true;
    error = null;
    actualizar();
    try {
      final datos = await Future.wait([
        api.pedir('GET', '/paquetes'),
        api.pedir('GET', '/solicitudes'),
      ]);
      paquetes = (datos[0] as List).map((p) => Paquete.fromJson(p)).toList();
      historial = (datos[1] as List).map((p) => Solicitud.fromJson(p)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      actualizar();
    }
  }

  Future<Solicitud?> buscar(Map<String, dynamic> preferencias) async {
    enviando = true;
    error = null;
    actualizar();
    try {
      actual = Solicitud.fromJson(
        await api.pedir('POST', '/solicitudes', datos: preferencias),
      );
      await cargar();
      return actual;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      enviando = false;
      actualizar();
    }
  }

  Future<Solicitud> abrir(String id) async {
    final consulta = Solicitud.fromJson(await api.pedir('GET', '/solicitudes/$id'));
    historial = [for (final previa in historial) previa.id == id ? consulta : previa];
    actualizar();
    return consulta;
  }

  Future<Apartado> apartar(String solicitudId, Paquete paquete) async {
    final resultado = await api.pedir(
      'POST',
      '/solicitudes/$solicitudId/apartado',
      datos: {'paquete_id': paquete.id, 'precio_esperado_mxn': paquete.precio},
    );
    final pase = Apartado.fromJson(resultado);
    await cargar();
    return pase;
  }
}
