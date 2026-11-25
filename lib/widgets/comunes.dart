// Componentes visuales reutilizables. Aquí solo hay presentación.
import 'package:flutter/material.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import 'foto_viaje.dart';

class Marca extends StatelessWidget {
  final bool clara;
  const Marca({super.key, this.clara = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          'assets/imagenes/logo_modo_escapada.png',
          width: 44,
          height: 44,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 11),
      Text(
        'modo escapada',
        style: TextStyle(
          fontFamily: 'Editorial',
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: clara ? Colors.white : tinta,
        ),
      ),
    ],
  );
}

class Encabezado extends StatelessWidget {
  final String ceja, titulo, detalle;
  const Encabezado(this.ceja, this.titulo, this.detalle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        ceja.toUpperCase(),
        style: const TextStyle(
          color: verde,
          letterSpacing: 2,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        titulo,
        style: const TextStyle(
          fontFamily: 'Editorial',
          fontSize: 34,
          height: 1.18,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        detalle,
        style: const TextStyle(color: gris, fontSize: 14, height: 1.6),
      ),
    ],
  );
}

class Caja extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const Caja({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE1E8DD)),
    ),
    child: child,
  );
}

class Mensaje extends StatelessWidget {
  final String texto;
  final bool esError;
  const Mensaje(this.texto, {super.key, this.esError = true});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: esError ? const Color(0xFFFAEBE4) : suave,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          esError ? Icons.info_outline : Icons.auto_awesome_outlined,
          size: 19,
          color: esError ? const Color(0xFF903921) : verde,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              height: 1.5,
              fontSize: 12,
              color: esError ? const Color(0xFF903921) : verde,
            ),
          ),
        ),
      ],
    ),
  );
}

class Etiqueta extends StatelessWidget {
  final String texto;
  const Etiqueta(this.texto, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: suave,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      texto,
      style: const TextStyle(
        color: verde,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

class Vacio extends StatelessWidget {
  final String titulo, descripcion;
  final Widget? accion;
  const Vacio(this.titulo, this.descripcion, {super.key, this.accion});
  @override
  Widget build(BuildContext context) => Caja(
    child: SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.explore_outlined, size: 48, color: verde),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: gris, height: 1.6),
          ),
          if (accion != null) ...[const SizedBox(height: 20), accion!],
        ],
      ),
    ),
  );
}

class TarjetaPaquete extends StatelessWidget {
  final Paquete paquete;
  final VoidCallback onAbrir;
  final int? presupuesto;
  const TarjetaPaquete(
    this.paquete, {
    super.key,
    required this.onAbrir,
    this.presupuesto,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onAbrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: FotoViaje(recurso: paquete.imagen, url: paquete.imagenUrl),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Etiqueta(estilo(paquete.estilo)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 52,
                  child: Text(
                    paquete.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Editorial',
                      fontSize: 21,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${paquete.dias} ${paquete.dias == 1 ? 'día' : 'días'}  ·  ${traslado(paquete.traslado)} desde CDMX',
                  style: const TextStyle(color: gris, fontSize: 11),
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dinero(paquete.precio),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: verde,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'MXN / persona',
                        style: TextStyle(fontSize: 10, color: gris),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: verde,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  presupuesto != null
                      ? 'Te quedan ${dinero(presupuesto! - paquete.precio)} de presupuesto'
                      : paquete.cupo > 0
                      ? 'Salida ${fecha(paquete.fecha)}'
                      : 'Cupo agotado',
                  style: const TextStyle(fontSize: 11, color: gris),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RejillaPaquetes extends StatelessWidget {
  final List<Paquete> paquetes;
  final void Function(Paquete) onAbrir;
  final int? presupuesto;
  const RejillaPaquetes(
    this.paquetes, {
    super.key,
    required this.onAbrir,
    this.presupuesto,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, medida) {
      final columnas = medida.maxWidth > 920
          ? 3
          : medida.maxWidth > 570
          ? 2
          : 1;
      final ancho = (medida.maxWidth - (columnas - 1) * 20) / columnas;
      return Wrap(
        spacing: 20,
        runSpacing: 24,
        children: paquetes
            .map(
              (p) => SizedBox(
                width: ancho,
                child: TarjetaPaquete(
                  p,
                  presupuesto: presupuesto,
                  onAbrir: () => onAbrir(p),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class Pagina extends StatelessWidget {
  final List<Widget> contenido;
  final double maximo;
  const Pagina({super.key, required this.contenido, this.maximo = 1190});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maximo),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 30,
            24,
            MediaQuery.sizeOf(context).width < 600 ? 18 : 30,
            42,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: contenido,
          ),
        ),
      ),
    ),
  );
}
