// Controlador de pantalla (ViewModel). Mantiene la sesión y avisa a las vistas.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../modelos/modelos.dart';
import '../servicios/api.dart';
import 'estado.dart';

class Sesion extends EstadoControlador {
  final Api api;
  final _almacen = const FlutterSecureStorage();
  Cuenta? cuenta;
  bool iniciando = true, trabajando = false, demo = false;
  String fase = 'recomendacion';
  String? error;
  Map<String, dynamic>? cuentasDemo;
  Sesion(this.api) {
    api.sesionCaducada = () {
      salir();
    };
  }

  Future<void> iniciar() async {
    try {
      try {
        api.token = await _almacen.read(key: 'token');
      } catch (_) {
        // Un navegador sin almacenamiento seguro puede usar la sesión en memoria.
      }
      await configuracion();
      if (api.token != null) {
        cuenta = Cuenta.fromJson(await api.pedir('GET', '/me'));
      }
    } catch (e) {
      error = e.toString();
      api.token = null;
    } finally {
      iniciando = false;
      actualizar();
    }
  }

  Future<void> configuracion() async {
    final datos = await api.pedir('GET', '/config');
    demo = datos['demo'];
    fase = datos['fase'];
    cuentasDemo = datos['cuentas_demo'];
  }

  Future<String> solicitarRecuperacion(String correo) async {
    final datos = await api.pedir(
      'POST',
      '/auth/recuperacion/solicitar',
      datos: {'correo': correo.trim()},
    );
    return datos['solicitud_id'] as String;
  }

  Future<void> confirmarRecuperacion({
    required String correo,
    required String solicitudId,
    required String codigo,
    required String password,
  }) async {
    await api.pedir(
      'POST',
      '/auth/recuperacion/confirmar',
      datos: {
        'correo': correo.trim(),
        'solicitud_id': solicitudId,
        'codigo': codigo,
        'password': password,
      },
    );
    await salir();
  }

  Future<void> guardar(String llave, String? valor) async {
    try {
      await _almacen.write(key: llave, value: valor);
    } catch (_) {
      // No se guarda en texto plano cuando falta almacenamiento seguro.
    }
  }

  Future<bool> entrar(String correo, String password, {String? nombre}) async {
    trabajando = true;
    error = null;
    actualizar();
    try {
      if (nombre != null) {
        await api.pedir(
          'POST',
          '/auth/registro',
          datos: {
            'nombre': nombre.trim(),
            'correo': correo.trim(),
            'password': password,
          },
        );
      }
      final datos = await api.pedir(
        'POST',
        '/auth/login',
        datos: {'correo': correo.trim(), 'password': password},
      );
      api.token = datos['access_token'];
      await guardar('token', api.token);
      cuenta = Cuenta.fromJson(datos['usuario']);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      trabajando = false;
      actualizar();
    }
  }

  Future<void> salir() async {
    cuenta = null;
    api.token = null;
    actualizar();
    await guardar('token', null);
  }
}
