import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/viajes.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'pase.dart';
import 'resultados.dart';

class Historial extends StatelessWidget {
  final VoidCallback irBrujula, irHistorial;
  const Historial({
    super.key,
    required this.irBrujula,
    required this.irHistorial,
  });

  Future<void> abrir(
    BuildContext context,
    Viajes viajes,
    Solicitud solicitud,
  ) async {
    try {
      final actualizada = await viajes.abrir(solicitud.id);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => actualizada.apartado != null && actualizada.paqueteApartado != null
                ? PaseDigital(actualizada.paqueteApartado!, actualizada.apartado!)
                : Resultados(actualizada, viajes: viajes, irHistorial: irHistorial),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viajes = context.watch<Viajes>();
    return Pagina(
      maximo: 920,
      contenido: [
        const Encabezado(
          'Tu bitácora',
          'Mis viajes',
          'Consulta tus búsquedas y recupera los pases de las escapadas que apartaste.',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: viajes.cargando ? null : viajes.cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ),
        const SizedBox(height: 12),
        if (viajes.cargando && viajes.historial.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (viajes.error != null && viajes.historial.isEmpty)
          Vacio(
            'No pudimos cargar tus viajes',
            viajes.error!,
            accion: OutlinedButton(
              onPressed: viajes.cargar,
              child: const Text('Volver a intentar'),
            ),
          )
        else if (viajes.historial.isEmpty)
          Vacio(
            'Tu primera escapada está por venir',
            'Responde Mi brújula para comenzar tu historia.',
            accion: FilledButton(
              onPressed: irBrujula,
              child: const Text('Abrir Mi brújula'),
            ),
          )
        else
          for (final solicitud in viajes.historial)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Caja(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Etiqueta(
                          solicitud.apartado == null
                              ? estilo(solicitud.estilo)
                              : solicitud.apartado!.cancelado
                              ? 'Reserva cancelada'
                              : 'Apartado confirmado',
                        ),
                        Etiqueta(fecha(solicitud.creada.toLocal())),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      solicitud.paqueteApartado?.nombre ?? 'Búsqueda guardada',
                      style: const TextStyle(
                        fontFamily: 'Editorial',
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      solicitud.apartado?.folio ??
                          '${dinero(solicitud.presupuesto)} MXN · ${solicitud.dias} días',
                      style: const TextStyle(color: gris),
                    ),
                    const SizedBox(height: 11),
                    OutlinedButton.icon(
                      onPressed: () => abrir(context, viajes, solicitud),
                      icon: Icon(
                        solicitud.apartado == null
                            ? Icons.explore_outlined
                            : Icons.airplane_ticket_outlined,
                      ),
                      label: Text(
                        solicitud.apartado == null
                            ? 'Ver opciones'
                            : solicitud.apartado!.cancelado
                            ? 'Ver cancelación'
                            : 'Ver pase',
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
