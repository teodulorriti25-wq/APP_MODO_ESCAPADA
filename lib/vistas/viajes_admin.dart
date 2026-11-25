import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controladores/administracion.dart';
import '../modelos/operacion.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/foto_viaje.dart';
import 'editor_viaje.dart';

class ViajesAdmin extends StatefulWidget {
  const ViajesAdmin({super.key});

  @override
  State<ViajesAdmin> createState() => _ViajesAdminState();
}

class _ViajesAdminState extends State<ViajesAdmin> {
  final _busqueda = TextEditingController();
  String _filtro = 'todos';
  bool _actualizando = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _editor({ViajeAdmin? viaje, bool duplicar = false}) async {
    final admin = context.read<Administracion>();
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditorViaje(admin: admin, origen: viaje, duplicar: duplicar),
      ),
    );
    if (guardado != true || !mounted) return;
    if (viaje == null || duplicar) {
      setState(() {
        _filtro = 'todos';
        _busqueda.clear();
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        viaje == null || duplicar ? 'Borrador guardado. Publícalo desde Viajes.' : 'Cambios guardados.',
      )),
    );
  }

  Future<void> _estado(ViajeAdmin viaje, String estado) async {
    final admin = context.read<Administracion>();
    final archivar = estado == 'archivado';
    if (archivar) {
      final aceptar = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('¿Archivar esta salida?'),
          content: Text(viaje.publicado
              ? 'Se retirará ${viaje.paquete.nombre} del catálogo.'
              : 'El borrador quedará en Archivados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogo, true),
              child: const Text('Archivar'),
            ),
          ],
        ),
      );
      if (aceptar != true || !mounted) return;
    }
    setState(() => _actualizando = true);
    try {
      await admin.cambiarEstadoViaje(viaje, estado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(archivar ? 'Salida archivada.' : 'Salida publicada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Administracion>();
    final consulta = _busqueda.text.trim().toLowerCase();
    final viajes = admin.viajes.where((viaje) =>
      (_filtro == 'todos' || viaje.estado == _filtro) &&
      viaje.paquete.nombre.toLowerCase().contains(consulta),
    ).toList();
    final ocupado = _actualizando || admin.cargandoViajes;
    const filtros = {
      'todos': 'Todos',
      'borrador': 'Borradores',
      'publicado': 'Publicados',
      'archivado': 'Archivados',
    };
    return Pagina(
      maximo: 1000,
      contenido: [
        Text('Viajes', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('Crea salidas y publícalas en el catálogo.'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: ocupado ? null : () => _editor(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo viaje'),
            ),
            OutlinedButton.icon(
              onPressed: ocupado ? null : admin.cargarViajes,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o destino',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final filtro in filtros.entries)
              ChoiceChip(
                label: Text(filtro.value),
                selected: _filtro == filtro.key,
                onSelected: (_) => setState(() => _filtro = filtro.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (ocupado) const LinearProgressIndicator(),
        if (admin.errorViajes != null) Mensaje(admin.errorViajes!),
        if (!ocupado && admin.errorViajes == null && viajes.isEmpty)
          const Vacio('Sin salidas para mostrar', 'Crea un viaje o ajusta los filtros.'),
        for (final viaje in viajes)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _TarjetaViaje(
              viaje,
              editar: ocupado ? null : () => _editor(viaje: viaje),
              duplicar: ocupado ? null : () => _editor(viaje: viaje, duplicar: true),
              archivar: ocupado ? null : () => _estado(viaje, 'archivado'),
              publicar: ocupado ? null : () => _estado(viaje, 'publicado'),
            ),
          ),
      ],
    );
  }
}

class _TarjetaViaje extends StatelessWidget {
  final ViajeAdmin viaje;
  final VoidCallback? editar, duplicar, archivar, publicar;

  const _TarjetaViaje(this.viaje, {this.editar, this.duplicar, this.archivar, this.publicar});

  @override
  Widget build(BuildContext context) {
    final paquete = viaje.paquete;
    final lugares = paquete.cupoTotal - paquete.cupo;
    final pasada = !paquete.fecha.isAfter(DateTime.now());
    return Caja(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FotoViaje(
                  recurso: paquete.imagen, url: paquete.imagenUrl, ancho: 75, alto: 75,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Etiqueta(viaje.etiquetaEstado),
                        if (pasada) const Etiqueta('Fecha vencida'),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(paquete.nombre, style: Theme.of(context).textTheme.titleLarge),
                    Text('${fecha(paquete.fecha)} · ${estilo(paquete.estilo)}',
                        style: const TextStyle(color: gris)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${dinero(paquete.precio)} MXN por persona · ${paquete.cupo} de ${paquete.cupoTotal} lugares disponibles'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: lugares / paquete.cupoTotal),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: editar, child: const Text('Editar')),
              TextButton(onPressed: duplicar, child: const Text('Duplicar')),
              if (viaje.estado != 'archivado')
                OutlinedButton(onPressed: archivar, child: const Text('Archivar')),
              if (!viaje.publicado)
                FilledButton(
                  onPressed: pasada ? null : publicar,
                  child: const Text('Publicar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
