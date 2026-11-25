import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/modelos.dart';
import '../modelos/operacion.dart';
import '../servicios/api.dart';
import '../servicios/canal_reservas.dart';
import '../servicios/sonido_reserva.dart';
import 'estado.dart';

class Administracion extends EstadoControlador {
  final Api api;
  PanelDatos? panel;
  List<Cuenta> clientes = [];
  Map<String, dynamic>? modelo;
  bool cargando = true, entrenando = false;
  String? error;
  List<ViajeAdmin> viajes = [];
  List<ReservaAdmin> reservas = [];
  bool cargandoViajes = false, cargandoReservas = false;
  String? errorViajes, errorReservas;
  int _revisionViajes = 0, _revisionReservas = 0, _revisionPanel = 0;
  DateTime? desde, hasta;
  bool enVivo = false, sonidoActivo = !kIsWeb, activandoSonido = false;
  int avisosPendientes = 0;
  final _avisos = StreamController<String>.broadcast();
  final _reservasAvisadas = <String>{};
  final _sonido = SonidoReserva();
  late final CanalReservas _canal;
  Timer? _refresco;
  bool _actualizandoReservas = false;
  bool _refrescoPendiente = false;
  bool _cerrado = false;

  Administracion(this.api) {
    _canal = CanalReservas(
      api,
      alCambiarConexion: (conectado) {
        enVivo = conectado;
        actualizar();
      },
      alRecibir: _recibirAviso,
    );
  }

  Stream<String> get avisos => _avisos.stream;

  void iniciar() {
    unawaited(cargar());
    unawaited(cargarReservas());
    unawaited(_canal.iniciar());
  }

  void _recibirAviso(Map<String, dynamic> datos) {
    final tipo = datos['tipo'];
    const tipos = {'listo', 'sincronizar', 'reserva_nueva', 'reserva_cancelada'};
    if (_cerrado || !tipos.contains(tipo)) {
      return;
    }
    _programarRefresco();
    if (tipo != 'reserva_nueva') return;
    final id = datos['id'];
    final folio = datos['folio'];
    if (id is! String || folio is! String || !_reservasAvisadas.add(id)) return;
    if (_reservasAvisadas.length > 250) {
      _reservasAvisadas.remove(_reservasAvisadas.first);
    }
    avisosPendientes++;
    _avisos.add(folio);
    if (sonidoActivo) unawaited(_reproducirAviso());
    actualizar();
  }

  void _programarRefresco() {
    if (_cerrado) return;
    if (_actualizandoReservas) {
      _refrescoPendiente = true;
      return;
    }
    _refresco ??= Timer(const Duration(milliseconds: 120), _refrescarReservas);
  }

  Future<void> _refrescarReservas() async {
    _refresco = null;
    _actualizandoReservas = true;
    try {
      await Future.wait([
        cargarReservas(silencioso: true),
        cargarViajes(silencioso: true),
        _refrescarPanel(),
      ]);
    } finally {
      _actualizandoReservas = false;
      if (_refrescoPendiente) {
        _refrescoPendiente = false;
        _programarRefresco();
      }
    }
  }

  void leerAvisos() {
    avisosPendientes = 0;
    actualizar();
  }

  Future<void> _reproducirAviso() async {
    final reprodujo = await _sonido.reproducir(habilitado: () => sonidoActivo);
    if (!reprodujo && !_cerrado) {
      sonidoActivo = false;
      actualizar();
    }
  }

  Future<bool> alternarSonido() async {
    if (activandoSonido) return sonidoActivo;
    if (sonidoActivo) {
      sonidoActivo = false;
      actualizar();
      return false;
    }
    activandoSonido = true;
    actualizar();
    sonidoActivo = await _sonido.reproducir();
    activandoSonido = false;
    actualizar();
    return sonidoActivo;
  }

  String get _rutaPanel => desde == null
      ? '/admin/estadisticas'
      : '/admin/estadisticas?desde=${desde!.toIso8601String().substring(0, 10)}&hasta=${hasta!.toIso8601String().substring(0, 10)}';

  Future<void> _cargarPanel() async {
    final revision = ++_revisionPanel;
    final nuevo = PanelDatos.fromJson(await api.pedir('GET', _rutaPanel));
    if (revision == _revisionPanel) panel = nuevo;
  }

  Future<void> _refrescarPanel() async {
    try {
      await _cargarPanel();
      actualizar();
    } catch (_) {
      // Las métricas se vuelven a pedir al siguiente aviso o al cambiar de periodo.
    }
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    actualizar();
    try {
      final respuestas = await Future.wait<dynamic>([
        api.pedir('GET', '/admin/clientes'),
        api.pedir('GET', '/admin/modelo'),
        _cargarPanel(),
      ]);
      clientes = (respuestas[0] as List)
          .map((c) => Cuenta.fromJson(c))
          .toList();
      modelo = Map<String, dynamic>.from(respuestas[1]);
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      actualizar();
    }
  }

  Future<void> promover(Cuenta cuenta) async {
    await api.pedir('PATCH', '/admin/clientes/${cuenta.id}/promover');
    await cargar();
  }

  Future<void> cargarViajes({bool silencioso = false}) async {
    final revision = ++_revisionViajes;
    if (!silencioso) {
      cargandoViajes = true;
      errorViajes = null;
      actualizar();
    }
    try {
      final datos = await api.pedir('GET', '/admin/viajes') as List;
      if (revision == _revisionViajes) {
        viajes = datos.map((viaje) => ViajeAdmin.fromJson(viaje)).toList();
        errorViajes = null;
      }
    } catch (e) {
      if (revision == _revisionViajes) errorViajes = e.toString();
    } finally {
      if (revision == _revisionViajes) {
        cargandoViajes = false;
        actualizar();
      }
    }
  }

  Future<void> guardarViaje(Map<String, dynamic> datos, {String? id}) async {
    await api.pedir(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/admin/viajes' : '/admin/viajes/$id',
      datos: datos,
    );
    await cargarViajes();
  }

  Future<void> cambiarEstadoViaje(ViajeAdmin viaje, String estado) async {
    await api.pedir(
      'PATCH',
      '/admin/viajes/${viaje.paquete.id}/estado',
      datos: {'estado': estado},
    );
    await cargarViajes();
  }

  Future<void> cargarReservas({bool silencioso = false}) async {
    final revision = ++_revisionReservas;
    if (!silencioso) {
      cargandoReservas = true;
      errorReservas = null;
      actualizar();
    }
    try {
      final datos = await api.pedir('GET', '/admin/apartados') as List;
      if (revision == _revisionReservas) {
        reservas = datos.map((reserva) => ReservaAdmin.fromJson(reserva)).toList();
        errorReservas = null;
      }
    } catch (e) {
      if (revision == _revisionReservas) errorReservas = e.toString();
    } finally {
      if (revision == _revisionReservas) {
        cargandoReservas = false;
        actualizar();
      }
    }
  }

  Future<void> cancelarReserva(ReservaAdmin reserva, String motivo) async {
    await api.pedir(
      'PATCH',
      '/admin/apartados/${reserva.apartado.id}/cancelar',
      datos: {'motivo': motivo},
    );
    await Future.wait([cargarReservas(), cargarViajes(), cargar()]);
  }

  Future<void> entrenar() async {
    entrenando = true;
    error = null;
    actualizar();
    try {
      await api.pedir('POST', '/admin/modelo/entrenar');
      await cargar();
    } catch (e) {
      error = e.toString();
    } finally {
      entrenando = false;
      actualizar();
    }
  }

  @override
  void dispose() {
    _cerrado = true;
    _refresco?.cancel();
    _canal.dispose();
    unawaited(_avisos.close());
    unawaited(_sonido.cerrar());
    super.dispose();
  }
}
