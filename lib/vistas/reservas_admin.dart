import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controladores/administracion.dart';
import '../modelos/operacion.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

class ReservasAdmin extends StatefulWidget {
  const ReservasAdmin({super.key});

  @override
  State<ReservasAdmin> createState() => _ReservasAdminState();
}

class _ReservasAdminState extends State<ReservasAdmin> {
  String _busqueda = '', _filtro = 'todas';
  bool _cancelando = false;

  Future<void> _cancelar(ReservaAdmin reserva) async {
    final admin = context.read<Administracion>();
    final formulario = GlobalKey<FormState>();
    var motivo = '';
    final respuesta = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Cancelar reserva'),
        content: Form(
          key: formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Se liberará el lugar del folio ${reserva.apartado.folio}.'),
              const SizedBox(height: 14),
              TextFormField(
                maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Motivo de cancelación'),
                onChanged: (valor) => motivo = valor.trim(),
                validator: (valor) => (valor ?? '').trim().isEmpty
                    ? 'Escribe el motivo.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo), child: const Text('Volver')),
          FilledButton(
            onPressed: () {
              if (formulario.currentState!.validate()) Navigator.pop(dialogo, motivo);
            },
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (respuesta == null || !mounted) return;
    setState(() => _cancelando = true);
    try {
      await admin.cancelarReserva(reserva, respuesta);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada. El lugar volvió al cupo.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Administracion>();
    final consulta = _busqueda.trim().toLowerCase();
    final reservas = admin.reservas.where((reserva) =>
      (_filtro == 'todas' || reserva.apartado.estado == _filtro) &&
      [reserva.apartado.folio, reserva.cliente, reserva.correo, reserva.viaje]
        .any((valor) => valor.toLowerCase().contains(consulta)),
    ).toList();
    final ocupado = _cancelando || admin.cargandoReservas;
    const filtros = {
      'todas': 'Todas',
      'confirmado': 'Confirmadas',
      'cancelado': 'Canceladas',
    };
    return Pagina(
      maximo: 1000,
      contenido: [
        Text('Reservas', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('Consulta folios, viajeros y estados de cada apartado.'),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: ocupado ? null : admin.cargarReservas,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            Etiqueta(admin.enVivo ? 'En vivo' : 'Conectando los avisos…'),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (valor) => setState(() => _busqueda = valor),
          decoration: const InputDecoration(
            labelText: 'Buscar por folio, cliente o viaje',
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
        if (admin.errorReservas != null) Mensaje(admin.errorReservas!),
        if (!ocupado && admin.errorReservas == null && reservas.isEmpty)
          const Vacio('Sin reservas para mostrar', 'Los apartados de los clientes aparecerán aquí.'),
        for (final reserva in reservas)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _TarjetaReserva(
              reserva,
              cancelar: ocupado || !reserva.sePuedeCancelar ? null : () => _cancelar(reserva),
            ),
          ),
      ],
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  final ReservaAdmin reserva;
  final VoidCallback? cancelar;

  const _TarjetaReserva(this.reserva, {this.cancelar});

  @override
  Widget build(BuildContext context) {
    final apartado = reserva.apartado;
    final precio = apartado.precioReservado;
    return Caja(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Etiqueta(apartado.cancelado ? 'Cancelada' : 'Confirmada'),
              SelectableText(apartado.folio, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reserva.viaje, style: Theme.of(context).textTheme.titleLarge),
          Text('Salida ${fecha(reserva.fechaSalida)} · 1 lugar', style: const TextStyle(color: gris)),
          const SizedBox(height: 10),
          Text(reserva.cliente),
          SelectableText(reserva.correo, style: const TextStyle(color: gris)),
          if (precio != null) ...[
            const SizedBox(height: 8),
            Text('${dinero(precio)} MXN al reservar'),
          ],
          if (apartado.canceladoEn != null) ...[
            const SizedBox(height: 10),
            Text('Cancelada el ${fecha(apartado.canceladoEn!.toLocal())}', style: const TextStyle(color: gris)),
          ],
          if (apartado.motivoCancelacion != null) Text(apartado.motivoCancelacion!),
          if (reserva.sePuedeCancelar) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cancelar,
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Cancelar reserva'),
            ),
          ],
        ],
      ),
    );
  }
}
