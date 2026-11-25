import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/foto_viaje.dart';

class PaseDigital extends StatelessWidget {
  final Paquete paquete;
  final Apartado apartado;
  final VoidCallback? irHistorial;
  const PaseDigital(this.paquete, this.apartado, {super.key, this.irHistorial});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pase digital')),
    body: Pagina(
      maximo: 690,
      contenido: [
        Encabezado(
          'Mis viajes',
          apartado.cancelado ? 'Reserva cancelada' : '¡Ya tienes escapada!',
          apartado.cancelado
              ? 'El lugar fue liberado. Aquí puedes consultar el folio de la reserva.'
              : 'Tu lugar está guardado. Encuentra este pase cuando quieras en Mis viajes.',
        ),
        if (apartado.motivoCancelacion != null) ...[
          const SizedBox(height: 14),
          Mensaje(apartado.motivoCancelacion!),
        ],
        const SizedBox(height: 23),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: FotoViaje(recurso: paquete.imagen, url: paquete.imagenUrl),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFF0E9D2),
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Etiqueta(apartado.cancelado ? 'Cancelada' : 'Confirmada'),
                    const SizedBox(height: 14),
                    Text(
                      paquete.nombre,
                      style: const TextStyle(
                        fontFamily: 'Editorial',
                        fontSize: 29,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${fecha(paquete.fecha)} · 1 lugar · Salida CDMX',
                      style: const TextStyle(color: gris),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${dinero(apartado.precioReservado ?? paquete.precio)} MXN al reservar',
                      style: const TextStyle(color: gris),
                    ),
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 13),
                    const Text(
                      'FOLIO DE APARTADO',
                      style: TextStyle(
                        letterSpacing: 1.3,
                        fontSize: 11,
                        color: gris,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      apartado.folio,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: verde,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 17),
                      label: const Text('Copiar folio'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: apartado.folio),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Folio copiado.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        FilledButton.icon(
          icon: const Icon(Icons.luggage_outlined),
          label: const Text('Ir a Mis viajes'),
          onPressed: () {
            if (irHistorial != null) {
              Navigator.popUntil(context, (ruta) => ruta.isFirst);
              irHistorial!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    ),
  );
}
