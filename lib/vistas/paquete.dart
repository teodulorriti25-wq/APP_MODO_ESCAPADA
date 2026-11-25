import 'package:flutter/material.dart';
import '../controladores/viajes.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/foto_viaje.dart';
import 'pase.dart';

class DetallePaquete extends StatefulWidget {
  final Paquete paquete;
  final Viajes viajes;
  final String? solicitudId;
  final VoidCallback? onPersonalizar, irHistorial;
  const DetallePaquete(
    this.paquete, {
    super.key,
    required this.viajes,
    this.solicitudId,
    this.onPersonalizar,
    this.irHistorial,
  });
  @override
  State<DetallePaquete> createState() => _DetallePaqueteState();
}

class _DetallePaqueteState extends State<DetallePaquete> {
  bool _guardando = false;
  String? _error;

  Future<void> confirmar() async {
    final paquete = widget.paquete;
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Apartar un lugar?'),
        content: Text(
          '${paquete.nombre}\n${fecha(paquete.fecha)} · ${dinero(paquete.precio)} MXN por persona',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar apartado'),
          ),
        ],
      ),
    );
    if (si != true || !mounted) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final apartado = await widget.viajes.apartar(
        widget.solicitudId!,
        paquete,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PaseDigital(paquete, apartado, irHistorial: widget.irHistorial),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paquete;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la escapada')),
      body: Pagina(
        maximo: 930,
        contenido: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: FotoViaje(recurso: p.imagen, url: p.imagenUrl),
            ),
          ),
          const SizedBox(height: 23),
          Encabezado(
            '${estilo(p.estilo)} · Desde CDMX',
            p.nombre,
            p.descripcion,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Etiqueta(fecha(p.fecha)),
              Etiqueta('${p.dias} ${p.dias == 1 ? 'día' : 'días'}'),
              Etiqueta('${traslado(p.traslado)} de ida'),
              Etiqueta('${p.cupo} lugares disponibles'),
            ],
          ),
          const SizedBox(height: 22),
          Caja(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu itinerario',
                  style: TextStyle(fontFamily: 'Editorial', fontSize: 24),
                ),
                const SizedBox(height: 12),
                for (final dia in p.itinerario)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.route_outlined, color: verde),
                    title: Text(dia),
                  ),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Qué incluye',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final item in p.incluye)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: verde,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: gris),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Caja(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dinero(p.precio)} MXN',
                  style: const TextStyle(
                    fontSize: 29,
                    color: verde,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'por persona · precio de demostración',
                  style: TextStyle(color: gris, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Mensaje(_error!),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _guardando || p.cupo == 0
                        ? null
                        : widget.solicitudId != null
                        ? confirmar
                        : () {
                            Navigator.pop(context);
                            widget.onPersonalizar?.call();
                          },
                    icon: const Icon(Icons.airplane_ticket_outlined),
                    label: Text(
                      _guardando
                          ? 'Guardando el lugar…'
                          : p.cupo == 0
                          ? 'Cupo agotado'
                          : widget.solicitudId == null
                          ? 'Personalizar mi escapada'
                          : 'Apartar un lugar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
