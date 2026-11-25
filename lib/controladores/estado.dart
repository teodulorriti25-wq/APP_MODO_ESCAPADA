import 'package:flutter/foundation.dart';

/// Una petición puede terminar después de cerrar una pantalla o la sesión.
class EstadoControlador extends ChangeNotifier {
  bool _cerrado = false;

  void actualizar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
