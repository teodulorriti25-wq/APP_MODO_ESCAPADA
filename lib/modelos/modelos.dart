// Modelo. Objetos que representan el JSON validado de la API.
class Cuenta {
  final String id, nombre, correo, rol;
  Cuenta.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      nombre = j['nombre'],
      correo = j['correo'],
      rol = j['rol'];
  bool get esAdmin => rol == 'admin';
  String get primerNombre => nombre.split(' ').first;
}

class Paquete {
  final String id, nombre, estilo, descripcion, imagen;
  final String? imagenUrl;
  final DateTime fecha;
  final int precio, dias, traslado, cupo, cupoTotal;
  final List<String> itinerario, incluye;
  Paquete.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      nombre = j['nombre'],
      estilo = j['estilo'],
      descripcion = j['descripcion'],
      imagen = j['imagen_recurso'],
      imagenUrl = j['imagen_url'] as String?,
      fecha = DateTime.parse(j['fecha_salida']),
      precio = j['precio_mxn'],
      dias = j['dias'],
      traslado = j['traslado_min'],
      cupo = j['cupo_disponible'],
      cupoTotal = j['cupo_total'],
      itinerario = List<String>.from(j['itinerario']),
      incluye = List<String>.from(j['incluye']);
}

class Apartado {
  final String id, folio, estado;
  final DateTime creado;
  final int? precioReservado;
  final DateTime? canceladoEn;
  final String? motivoCancelacion;
  Apartado.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      folio = j['folio'],
      creado = DateTime.parse(j['creado_en']),
      precioReservado = j['precio_reservado_mxn'],
      estado = j['estado'] ?? 'confirmado',
      canceladoEn = j['cancelado_en'] == null
          ? null
          : DateTime.parse(j['cancelado_en']),
      motivoCancelacion = j['motivo_cancelacion'];
  bool get cancelado => estado == 'cancelado';
}

class Solicitud {
  final String id, fase;
  final String? estilo, version;
  final int presupuesto, dias, traslado;
  final List<String> actividades;
  final List<Paquete> opciones;
  final DateTime creada;
  final Apartado? apartado;
  final Paquete? paqueteApartado;
  Solicitud.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      fase = j['fase'],
      estilo = j['estilo_predicho'],
      version = j['version_modelo'],
      presupuesto = j['presupuesto_mxn'],
      dias = j['dias_max'],
      traslado = j['traslado_max_min'],
      actividades = List<String>.from(j['actividades']),
      opciones = (j['opciones'] as List)
          .map((e) => Paquete.fromJson(e))
          .toList(),
      creada = DateTime.parse(j['creado_en']),
      apartado = j['apartado'] == null
          ? null
          : Apartado.fromJson(j['apartado']),
      paqueteApartado = j['paquete_apartado'] == null
          ? null
          : Paquete.fromJson(j['paquete_apartado']);
}

class ClientePanel {
  final Cuenta cuenta;
  final int solicitudes, apartados;
  ClientePanel.fromJson(Map<String, dynamic> j)
    : cuenta = Cuenta.fromJson(j),
      solicitudes = j['solicitudes'],
      apartados = j['apartados'];
}

class PanelDatos {
  final int solicitudes, apartados;
  final List<ClientePanel> clientes;
  final Map<String, int> estilos;
  PanelDatos.fromJson(Map<String, dynamic> j)
    : solicitudes = j['solicitudes'],
      apartados = j['apartados'],
      clientes = (j['clientes'] as List)
          .map((e) => ClientePanel.fromJson(e))
          .toList(),
      estilos = {
        for (final b in j['por_estilo'])
          b['estilo'] as String: b['cantidad'] as int,
      };
}
