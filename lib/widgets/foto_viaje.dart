import 'package:flutter/material.dart';

import '../modelos/enlace_imagen.dart';

class FotoViaje extends StatelessWidget {
  final String recurso;
  final String? url;
  final double? ancho, alto;
  final bool vistaPrevia;

  const FotoViaje({
    super.key,
    required this.recurso,
    this.url,
    this.ancho,
    this.alto,
    this.vistaPrevia = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget portadaLocal() => Image.asset(
      'assets/imagenes/$recurso.webp',
      width: ancho,
      height: alto,
      fit: BoxFit.cover,
    );

    final enlace = enlaceImagen(url);
    if (enlace == null) return portadaLocal();
    return IgnorePointer(
      child: Image.network(
        enlace.toString(),
        width: ancho,
        height: alto,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        frameBuilder: (context, imagen, cuadro, sincronica) =>
            cuadro == null ? portadaLocal() : imagen,
        errorBuilder: (context, error, traza) => vistaPrevia
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No se pudo mostrar la foto. Comprueba que el enlace sea público y abra una imagen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : portadaLocal(),
      ),
    );
  }
}
