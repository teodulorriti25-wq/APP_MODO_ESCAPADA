import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api.dart';

class CanalReservas {
  final Api api;
  final void Function(bool) alCambiarConexion;
  final void Function(Map<String, dynamic>) alRecibir;
  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _suscripcion;
  Timer? _reintento, _espera;
  int _demora = 1;
  bool _cerrado = false;

  CanalReservas(this.api, {required this.alCambiarConexion, required this.alRecibir});

  Future<void> iniciar() async {
    final token = api.token;
    if (_cerrado || _canal != null || token == null) return;
    final base = Uri.parse(api.base);
    final url = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/admin/avisos',
    );
    final canal = WebSocketChannel.connect(url);
    _canal = canal;
    _suscripcion = canal.stream.listen(
      (mensaje) => _mensaje(canal, mensaje),
      onError: (Object error, StackTrace traza) => _desconectar(canal),
      onDone: () => _desconectar(canal),
      cancelOnError: true,
    );
    try {
      await canal.ready.timeout(const Duration(seconds: 25));
      if (_canal != canal) return;
      _vigilar(canal, const Duration(seconds: 20));
      canal.sink.add(jsonEncode({'tipo': 'autenticar', 'token': token}));
    } catch (_) {
      _desconectar(canal);
    }
  }

  void _mensaje(WebSocketChannel canal, dynamic texto) {
    if (_canal != canal || texto is! String) return;
    final dynamic dato;
    try {
      dato = jsonDecode(texto);
    } on FormatException {
      return;
    }
    if (dato is! Map<String, dynamic>) return;
    _vigilar(canal, const Duration(seconds: 45));
    switch (dato['tipo']) {
      case 'listo':
        _demora = 1;
        alCambiarConexion(true);
        alRecibir(dato);
        break;
      case 'ping':
        canal.sink.add('pong');
        break;
      default:
        alRecibir(dato);
        break;
    }
  }

  void _vigilar(WebSocketChannel canal, Duration plazo) {
    _espera?.cancel();
    _espera = Timer(plazo, () => _desconectar(canal));
  }

  void _desconectar(WebSocketChannel canal) {
    if (_canal != canal) return;
    final codigo = canal.closeCode;
    _retirarCanal();
    alCambiarConexion(false);
    if (_cerrado || api.token == null) return;
    if (codigo == 4401 || codigo == 4403) {
      api.sesionCaducada?.call();
      return;
    }
    _reintento = Timer(Duration(seconds: _demora), iniciar);
    _demora = (_demora * 2).clamp(1, 30).toInt();
  }

  void _retirarCanal() {
    final canal = _canal;
    final suscripcion = _suscripcion;
    _canal = null;
    _suscripcion = null;
    _espera?.cancel();
    if (canal != null) unawaited(_cerrar(canal, suscripcion));
  }

  Future<void> _cerrar(WebSocketChannel canal, StreamSubscription<dynamic>? suscripcion) async {
    try {
      await suscripcion?.cancel();
      await canal.sink.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // La conexión puede haber terminado por su cuenta.
    }
  }

  void dispose() {
    _cerrado = true;
    _reintento?.cancel();
    _retirarCanal();
  }
}
