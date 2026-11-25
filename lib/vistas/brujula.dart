import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controladores/viajes.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'resultados.dart';

class Brujula extends StatefulWidget {
  final VoidCallback irHistorial;
  const Brujula({super.key, required this.irHistorial});
  @override
  State<Brujula> createState() => _BrujulaState();
}

class _BrujulaState extends State<Brujula> {
  final _forma = GlobalKey<FormState>();
  final _presupuesto = TextEditingController(text: '3000');
  int _dias = 2, _traslado = 180;
  final Set<String> _actividades = {};
  String? _errorActividad;

  static const opciones = {
    'senderismo': ('Senderismo', Icons.hiking),
    'fotografia': ('Fotografía', Icons.photo_camera_outlined),
    'museos': ('Museos', Icons.museum_outlined),
    'gastronomia': ('Gastronomía', Icons.restaurant),
    'termales': ('Aguas termales', Icons.water_outlined),
    'spa': ('Spa y bienestar', Icons.spa_outlined),
  };

  @override
  void dispose() {
    _presupuesto.dispose();
    super.dispose();
  }

  Future<void> buscar() async {
    final viajes = context.read<Viajes>();
    final formularioValido = _forma.currentState!.validate();
    setState(
      () => _errorActividad = _actividades.isEmpty
          ? 'Elige entre una y tres actividades.'
          : null,
    );
    if (!formularioValido || _actividades.isEmpty || viajes.enviando) return;
    final resultado = await viajes.buscar({
      'presupuesto_mxn': int.parse(_presupuesto.text),
      'dias_max': _dias,
      'traslado_max_min': _traslado,
      'actividades': _actividades.toList(),
    });
    if (resultado == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Resultados(
          resultado,
          viajes: viajes,
          irHistorial: widget.irHistorial,
        ),
      ),
    );
  }

  Widget titulo(String numero, String texto) => Row(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: suave,
        foregroundColor: verde,
        child: Text(
          numero,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final viajes = context.watch<Viajes>();
    return Pagina(
      maximo: 800,
      contenido: [
        const Encabezado(
          'Tu viaje, a tu manera',
          'Mi brújula',
          'Dinos qué tienes en mente y encontraremos escapadas que encajen con tus planes.',
        ),
        const SizedBox(height: 26),
        Form(
          key: _forma,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Caja(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titulo('01', '¿Cuánto quieres gastar?'),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _presupuesto,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(
                        prefixText: r'$ ',
                        suffixText: 'MXN',
                        labelText: 'Presupuesto por persona',
                        helperText: 'Entre 1,000 y 15,000 MXN',
                      ),
                      validator: (v) {
                        final valor = int.tryParse(v ?? '');
                        return valor == null || valor < 1000 || valor > 15000
                            ? 'Escribe un monto entre 1,000 y 15,000.'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Caja(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titulo('02', '¿Cuánto tiempo tienes?'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final dia in [1, 2, 3, 4])
                          ChoiceChip(
                            label: Text('$dia ${dia == 1 ? 'día' : 'días'}'),
                            selected: _dias == dia,
                            onSelected: (_) => setState(() => _dias = dia),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Traslado máximo de ida · ${traslado(_traslado)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      min: 60,
                      max: 360,
                      divisions: 10,
                      value: _traslado.toDouble(),
                      label: traslado(_traslado),
                      onChanged: (v) => setState(() => _traslado = v.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Caja(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titulo('03', '¿Qué te gustaría hacer?'),
                    const SizedBox(height: 12),
                    const Text(
                      'Selecciona de una a tres actividades.',
                      style: TextStyle(color: gris),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opciones.entries
                          .map(
                            (opcion) => FilterChip(
                              label: Text(opcion.value.$1),
                              avatar: Icon(opcion.value.$2, size: 17),
                              selected: _actividades.contains(opcion.key),
                              onSelected: (seleccionada) {
                                setState(() {
                                  if (!seleccionada) {
                                    _actividades.remove(opcion.key);
                                  } else if (_actividades.length < 3) {
                                    _actividades.add(opcion.key);
                                  } else {
                                    _errorActividad =
                                        'Ya elegiste tres actividades. Quita una para cambiarla.';
                                    return;
                                  }
                                  _errorActividad = null;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    if (_errorActividad != null) ...[
                      const SizedBox(height: 14),
                      Mensaje(_errorActividad!),
                    ],
                  ],
                ),
              ),
              if (viajes.error != null) ...[
                const SizedBox(height: 16),
                Mensaje(viajes.error!),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: viajes.enviando ? null : buscar,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  viajes.enviando
                      ? 'Buscando tu escapada…'
                      : 'Ver mis recomendaciones',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
