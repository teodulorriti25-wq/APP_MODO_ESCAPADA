import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/sesion.dart';
import '../controladores/viajes.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'paquete.dart';

class Inicio extends StatefulWidget {
  final VoidCallback abrirBrujula;
  const Inicio({super.key, required this.abrirBrujula});
  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  String filtro = '';

  Widget portada(String nombre) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: LayoutBuilder(
      builder: (context, medida) {
        final compacto = medida.maxWidth < 560;
        return SizedBox(
          height: compacto ? 380 : 350,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/imagenes/naturaleza.webp',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: compacto
                        ? Alignment.bottomCenter
                        : Alignment.centerLeft,
                    end: compacto ? Alignment.topCenter : Alignment.centerRight,
                    colors: const [
                      Color(0xF016342B),
                      Color(0xA5153B30),
                      Color(0x1515342B),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compacto ? 24 : 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HOLA, ${nombre.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4F3D9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Cambia de aire.\nEscápate un rato.',
                      style: TextStyle(
                        fontFamily: 'Editorial',
                        fontSize: compacto ? 35 : 52,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Viajes que caben en tu tiempo, tu bolsillo y tus ganas.',
                      style: TextStyle(
                        color: Color(0xFFF5F8F2),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 23),
                    FilledButton.icon(
                      onPressed: widget.abrirBrujula,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF0E8C9),
                        foregroundColor: tinta,
                      ),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Encontrar mi escapada'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final viajes = context.watch<Viajes>();
    final nombre = context.read<Sesion>().cuenta!.primerNombre;
    final visibles = viajes.paquetes
        .where((p) => filtro.isEmpty || p.estilo == filtro)
        .toList();
    return Pagina(
      contenido: [
        portada(nombre),
        const SizedBox(height: 36),
        const Encabezado(
          'Catálogo · Salidas desde CDMX',
          '¿A dónde te quieres escapar?',
          'Elige un estilo y descubre planes para unos días fuera de la rutina.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final valor in ['', 'naturaleza', 'cultura', 'descanso'])
              ChoiceChip(
                label: Text(valor.isEmpty ? 'Todas' : estilo(valor)),
                selected: valor == filtro,
                onSelected: (_) => setState(() => filtro = valor),
                selectedColor: suave,
                showCheckmark: false,
              ),
            OutlinedButton.icon(
              onPressed: viajes.cargando ? null : viajes.cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar catálogo'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (viajes.cargando && visibles.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (viajes.error != null && visibles.isEmpty)
          Vacio(
            'No pudimos cargar el catálogo',
            viajes.error!,
            accion: OutlinedButton(
              onPressed: viajes.cargar,
              child: const Text('Volver a intentar'),
            ),
          )
        else if (visibles.isEmpty)
          const Vacio(
            'Volveremos con más escapadas',
            'No hay salidas para este estilo.',
          )
        else
          RejillaPaquetes(
            visibles,
            onAbrir: (paquete) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetallePaquete(
                    paquete,
                    onPersonalizar: widget.abrirBrujula,
                    viajes: viajes,
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 25),
        const Text(
          'Catálogo académico. Imágenes de referencia y precios de demostración.',
          style: TextStyle(color: gris, fontSize: 11),
        ),
      ],
    );
  }
}
