import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controladores/administracion.dart';
import '../modelos/enlace_imagen.dart';
import '../modelos/operacion.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/foto_viaje.dart';

class EditorViaje extends StatefulWidget {
  final Administracion admin;
  final ViajeAdmin? origen;
  final bool duplicar;

  const EditorViaje({
    super.key,
    required this.admin,
    this.origen,
    this.duplicar = false,
  });

  @override
  State<EditorViaje> createState() => _EditorViajeState();
}

class _EditorViajeState extends State<EditorViaje> {
  final _formulario = GlobalKey<FormState>();
  final _campoFoto = GlobalKey<FormFieldState<String>>();
  late final Map<String, TextEditingController> _campos;
  late String _estilo, _imagen;
  late int _dias;
  DateTime? _fecha;
  String? _error;
  String? _fotoPrevia;
  bool _guardando = false;

  bool get _editar => widget.origen != null && !widget.duplicar;
  bool get _conReservas => _editar && widget.origen!.tieneApartados;

  @override
  void initState() {
    super.initState();
    final viaje = widget.origen?.paquete;
    _estilo = viaje?.estilo ?? 'naturaleza';
    _imagen = viaje?.imagen ?? 'naturaleza';
    _dias = viaje?.dias ?? 1;
    _fecha = _editar ? viaje?.fecha : null;
    _campos = {
      'nombre': TextEditingController(text: viaje?.nombre),
      'descripcion': TextEditingController(text: viaje?.descripcion),
      'precio': TextEditingController(text: viaje?.precio.toString()),
      'traslado': TextEditingController(text: viaje?.traslado.toString()),
      'cupo': TextEditingController(text: viaje?.cupoTotal.toString()),
      'itinerario': TextEditingController(text: viaje?.itinerario.join('\n')),
      'incluye': TextEditingController(text: viaje?.incluye.join('\n')),
      'imagenUrl': TextEditingController(text: viaje?.imagenUrl),
    };
  }

  @override
  void dispose() {
    for (final campo in _campos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  String _valor(String campo) => _campos[campo]!.text.trim();

  String? _errorEnlace(String? valor) {
    if ((valor ?? '').trim().isEmpty || enlaceImagen(valor) != null) return null;
    return 'Pega un enlace HTTPS a una imagen o a un archivo de Drive.';
  }

  List<String> _lineas(String campo) => _valor(campo)
      .split('\n')
      .map((linea) => linea.trim())
      .where((linea) => linea.isNotEmpty)
      .toList();

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final primera = DateTime(hoy.year, hoy.month, hoy.day + 1);
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha != null && !_fecha!.isBefore(primera)
          ? _fecha!
          : primera,
      firstDate: primera,
      lastDate: DateTime(9999, 12, 31),
    );
    if (elegida != null && mounted) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (_guardando || !_formulario.currentState!.validate()) return;
    final salida = _fecha;
    if (salida == null) {
      setState(() => _error = 'Elige la fecha de salida.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.admin.guardarViaje({
        'nombre': _valor('nombre'),
        'estilo': _estilo,
        'descripcion': _valor('descripcion'),
        'fecha_salida': salida.toIso8601String().split('T').first,
        'precio_mxn': int.parse(_valor('precio')),
        'dias': _dias,
        'traslado_min': int.parse(_valor('traslado')),
        'cupo_total': int.parse(_valor('cupo')),
        'itinerario': _lineas('itinerario'),
        'incluye': _lineas('incluye'),
        'imagen_recurso': _imagen,
        'imagen_url': _valor('imagenUrl').isEmpty ? null : _valor('imagenUrl'),
      }, id: _editar ? widget.origen!.paquete.id : null);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _texto(
    String campo,
    String etiqueta, {
    int lineas = 1,
    int? maximo,
    String? ayuda,
  }) => TextFormField(
    controller: _campos[campo],
    readOnly: _conReservas,
    enabled: !_guardando,
    maxLines: lineas,
    maxLength: maximo,
    decoration: InputDecoration(labelText: etiqueta, helperText: ayuda),
    validator: (valor) => (valor ?? '').trim().isEmpty
        ? 'Completa este campo.'
        : null,
  );

  Widget _numero(
    String campo,
    String etiqueta, {
    required int minimo,
    required int maximo,
    bool soloLectura = false,
  }) => TextFormField(
    controller: _campos[campo],
    readOnly: soloLectura,
    enabled: !_guardando,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: etiqueta),
    validator: (valor) {
      final numero = int.tryParse((valor ?? '').trim());
      return numero != null && numero >= minimo && numero <= maximo
          ? null
          : 'Escribe un valor entre $minimo y $maximo.';
    },
  );

  Widget _seccion(String titulo, List<Widget> contenido) => Caja(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        for (final campo in contenido) ...[
          const SizedBox(height: 15),
          campo,
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    const estilos = ['naturaleza', 'cultura', 'descanso'];
    final paquete = widget.origen?.paquete;
    final ocupados = _editar && paquete != null ? paquete.cupoTotal - paquete.cupo : 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editar ? 'Editar viaje' : 'Nueva salida'),
      ),
      body: Form(
        key: _formulario,
        child: Pagina(
          maximo: 750,
          contenido: [
            if (_conReservas) ...[
              const Mensaje(
                'Esta salida tiene reservas. Puedes ajustar el cupo total, '
                'el precio de nuevas reservas y el enlace de la foto. Para otra fecha, duplica la salida.',
                esError: false,
              ),
              const SizedBox(height: 15),
            ],
            _seccion('Datos de la salida', [
              _texto('nombre', 'Nombre del viaje y destino', maximo: 120),
              _texto('descripcion', 'Descripción', lineas: 3, maximo: 1600),
              DropdownButtonFormField<String>(
                initialValue: _estilo,
                decoration: const InputDecoration(labelText: 'Estilo de viaje'),
                items: [
                  for (final opcion in estilos)
                    DropdownMenuItem(value: opcion, child: Text(estilo(opcion))),
                ],
                onChanged: _guardando || _conReservas
                    ? null
                    : (valor) => setState(() => _estilo = valor!),
              ),
              OutlinedButton.icon(
                onPressed: _guardando || _conReservas ? null : _elegirFecha,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _fecha == null ? 'Elegir fecha de salida' : fecha(_fecha!),
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: _dias,
                decoration: const InputDecoration(labelText: 'Duración'),
                items: [
                  for (var dia = 1; dia <= 4; dia++)
                    DropdownMenuItem(
                      value: dia,
                      child: Text(dia == 1 ? '1 día' : '$dia días'),
                    ),
                ],
                onChanged: _guardando || _conReservas
                    ? null
                    : (valor) => setState(() => _dias = valor!),
              ),
              _numero(
                'traslado', 'Traslado desde CDMX (minutos)',
                minimo: 1, maximo: 720, soloLectura: _conReservas,
              ),
            ]),
            const SizedBox(height: 16),
            _seccion('Foto del viaje', [
              TextFormField(
                key: _campoFoto,
                controller: _campos['imagenUrl'],
                enabled: !_guardando,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) {
                  if (_fotoPrevia != null) setState(() => _fotoPrevia = null);
                },
                decoration: const InputDecoration(
                  labelText: 'Enlace de la foto (opcional)',
                  hintText: 'https://…',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _errorEnlace,
              ),
              const Text(
                'Usa una imagen pública de internet o un archivo de Drive compartido con cualquier persona.',
              ),
              OutlinedButton.icon(
                onPressed: _guardando
                    ? null
                    : () {
                        if (_campoFoto.currentState!.validate()) {
                          setState(() => _fotoPrevia = _valor('imagenUrl'));
                        }
                      },
                icon: const Icon(Icons.image_search_outlined),
                label: const Text('Probar enlace'),
              ),
              if (_fotoPrevia != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 175,
                    child: FotoViaje(recurso: _imagen, url: _fotoPrevia, vistaPrevia: true),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _imagen,
                decoration: const InputDecoration(labelText: 'Portada de respaldo'),
                items: [
                  for (final opcion in estilos)
                    DropdownMenuItem(value: opcion, child: Text(estilo(opcion))),
                ],
                onChanged: _guardando || _conReservas
                    ? null
                    : (valor) => setState(() => _imagen = valor!),
              ),
            ]),
            const SizedBox(height: 16),
            _seccion('Precio y cupo', [
              _numero('precio', 'Precio por persona (MXN)', minimo: 1, maximo: 2147483647),
              _numero(
                'cupo', 'Cupo total',
                minimo: ocupados > 0 ? ocupados : 1, maximo: 2147483647,
              ),
              if (_editar)
                Text('$ocupados lugares ocupados', style: const TextStyle(color: gris)),
            ]),
            const SizedBox(height: 16),
            _seccion('Itinerario y servicios', [
              _texto('itinerario', 'Itinerario', lineas: 4, ayuda: 'Una actividad o etapa por línea'),
              _texto('incluye', 'Qué incluye', lineas: 3, ayuda: 'Un servicio por línea'),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Mensaje(_error!),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _guardando ? 'Guardando…' : _editar ? 'Guardar cambios' : 'Guardar borrador',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
