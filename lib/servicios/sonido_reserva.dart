import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class SonidoReserva {
  final AudioPlayer _audio = AudioPlayer();
  late final Future<bool> _preparado;
  Future<void> _cola = Future.value();
  bool _cerrado = false;

  SonidoReserva() {
    _preparado = _preparar();
  }

  Future<bool> _preparar() async {
    try {
      await _audio.setReleaseMode(ReleaseMode.stop);
      if (_cerrado) return false;
      await _audio.setSource(AssetSource('sonidos/reserva.mp3'));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reproducir({bool Function()? habilitado}) {
    final resultado = _cola.then((_) => _reproducir(habilitado));
    _cola = resultado.then<void>((_) {});
    return resultado;
  }

  Future<bool> _reproducir(bool Function()? habilitado) async {
    if (!await _preparado || _cerrado) return false;
    if (habilitado != null && !habilitado()) return true;
    final completo = Completer<void>();
    final suscripcion = _audio.onPlayerComplete.listen((_) {
      if (!completo.isCompleted) completo.complete();
    });
    try {
      await _audio.resume().timeout(const Duration(seconds: 3));
      await completo.future.timeout(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    } finally {
      await suscripcion.cancel();
    }
  }

  Future<void> cerrar() async {
    _cerrado = true;
    try {
      await _audio.dispose();
    } catch (_) {
      // El reproductor puede haber quedado inaccesible al cerrar la sesión.
    }
  }
}
