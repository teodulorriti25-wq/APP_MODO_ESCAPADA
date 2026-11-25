import 'package:flutter/material.dart';
import '../controladores/viajes.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'paquete.dart';

class Resultados extends StatelessWidget {
  final Solicitud solicitud;
  final Viajes viajes;
  final VoidCallback irHistorial;
  const Resultados(
    this.solicitud, {
    super.key,
    required this.viajes,
    required this.irHistorial,
  });

  @override
  Widget build(BuildContext context) {
    final piloto = solicitud.fase == 'piloto';
    return Scaffold(
      appBar: AppBar(title: const Text('Tu próxima escapada')),
      body: Pagina(
        contenido: [
          Encabezado(
            piloto ? 'Piloto · Elección libre' : 'Resultado de Mi brújula',
            piloto
                ? 'Elige cómo escaparte'
                : 'Tu estilo es ${estilo(solicitud.estilo)}',
            piloto
                ? 'Todas las salidas compatibles tienen la misma oportunidad de ser elegidas.'
                : 'Tu estilo sugerido aparece primero. Cada opción respeta el presupuesto, la duración y el traslado que elegiste.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Etiqueta('${dinero(solicitud.presupuesto)} MXN'),
              Etiqueta('${solicitud.dias} días máx.'),
              Etiqueta('${traslado(solicitud.traslado)} de traslado'),
              Etiqueta('${solicitud.opciones.length} opciones'),
            ],
          ),
          if (solicitud.version != null) ...[
            const SizedBox(height: 17),
            Mensaje(
              solicitud.version!.startsWith('demo')
                  ? 'Resultado del modelo de demostración, entrenado con datos sintéticos.'
                  : 'Modelo entrenado con elecciones del piloto · ${solicitud.version}',
              esError: false,
            ),
          ],
          const SizedBox(height: 25),
          if (solicitud.opciones.isEmpty)
            Vacio(
              'Todavía no hay una escapada compatible',
              'Puedes ampliar tu presupuesto o el tiempo de traslado y volver a buscar.',
              accion: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ajustar preferencias'),
              ),
            )
          else
            RejillaPaquetes(
              solicitud.opciones,
              presupuesto: solicitud.presupuesto,
              onAbrir: (p) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetallePaquete(
                      p,
                      viajes: viajes,
                      solicitudId: solicitud.id,
                      irHistorial: irHistorial,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
