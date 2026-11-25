// La navegación adapta las mismas vistas a escritorio y a pantalla móvil.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/administracion.dart';
import '../controladores/sesion.dart';
import '../controladores/viajes.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'administracion.dart';
import 'brujula.dart';
import 'historial.dart';
import 'inicio.dart';
import 'reservas_admin.dart';
import 'viajes_admin.dart';

class AreaPrivada extends StatelessWidget {
  final Cuenta cuenta;
  const AreaPrivada(this.cuenta, {super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Sesion>().api;
    if (cuenta.esAdmin) {
      return ChangeNotifierProvider(
        create: (_) => Administracion(api)..iniciar(),
        child: _Marco(cuenta),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => Viajes(api)..cargar(),
      child: _Marco(cuenta),
    );
  }
}

class _Marco extends StatefulWidget {
  final Cuenta cuenta;
  const _Marco(this.cuenta);
  @override
  State<_Marco> createState() => _MarcoState();
}

class _MarcoState extends State<_Marco> {
  int pagina = 0;
  StreamSubscription<String>? _avisos;

  @override
  void initState() {
    super.initState();
    if (widget.cuenta.esAdmin) {
      _avisos = context.read<Administracion>().avisos.listen(_mostrarAviso);
    }
  }

  void _mostrarAviso(String folio) {
    if (!mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    mensajes.removeCurrentSnackBar();
    mensajes.showSnackBar(
      SnackBar(
        content: Text('Nueva reserva · $folio'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Ver reservas', onPressed: () => ir(2)),
      ),
    );
  }

  Future<void> _alternarSonido(Administracion admin) async {
    final estabaActivo = admin.sonidoActivo;
    final activo = await admin.alternarSonido();
    if (!mounted) return;
    final mensaje = activo
        ? 'Sonido de reservas activado.'
        : estabaActivo
        ? 'Sonido de reservas silenciado.'
        : 'No se pudo reproducir el aviso. Revisa el audio y vuelve a activarlo.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void ir(int destino) {
    if (!mounted) return;
    setState(() => pagina = destino);
    if (widget.cuenta.esAdmin && destino == 1) {
      context.read<Administracion>().cargarViajes();
    }
    if (widget.cuenta.esAdmin && destino == 2) {
      final admin = context.read<Administracion>();
      admin.leerAvisos();
      admin.cargarReservas();
    }
  }

  @override
  void dispose() {
    _avisos?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final admin = widget.cuenta.esAdmin;
    final operacion = admin ? context.watch<Administracion>() : null;
    final destinos = admin
        ? [
            (Icons.bar_chart_outlined, 'Panel'),
            (Icons.luggage_outlined, 'Viajes'),
            (Icons.event_available_outlined, 'Reservas'),
            (Icons.people_outline, 'Clientes'),
            (Icons.auto_awesome_outlined, 'Modelo'),
          ]
        : [
            (Icons.home_outlined, 'Inicio'),
            (Icons.explore_outlined, 'Mi brújula'),
            (Icons.luggage_outlined, 'Mis viajes'),
          ];
    final vistas = admin
        ? const <Widget>[
            PanelAdmin(), ViajesAdmin(), ReservasAdmin(), ClientesAdmin(), ModeloAdmin(),
          ]
        : <Widget>[
            Inicio(abrirBrujula: () => ir(1)),
            Brujula(irHistorial: () => ir(2)),
            Historial(irBrujula: () => ir(1), irHistorial: () => ir(2)),
          ];
    final amplia = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      appBar: AppBar(
        title: const Marca(),
        toolbarHeight: 69,
        actions: [
          if (sesion.demo)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Etiqueta('Demo'),
            ),
          if (amplia)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                widget.cuenta.nombre,
                style: const TextStyle(fontSize: 13, color: gris),
              ),
            ),
          if (operacion != null) ...[
            IconButton(
              tooltip: operacion.enVivo ? 'Reservas en vivo' : 'Conectando los avisos de reservas',
              onPressed: () => ir(2),
              icon: Badge.count(
                count: operacion.avisosPendientes,
                isLabelVisible: operacion.avisosPendientes > 0,
                child: Icon(
                  operacion.enVivo ? Icons.notifications_outlined : Icons.notifications_off_outlined,
                ),
              ),
            ),
            IconButton(
              tooltip: operacion.sonidoActivo ? 'Silenciar sonido de reservas' : 'Activar sonido de reservas',
              onPressed: operacion.activandoSonido ? null : () => _alternarSonido(operacion),
              icon: Icon(operacion.sonidoActivo ? Icons.volume_up_outlined : Icons.volume_off_outlined),
            ),
          ],
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              sesion.salir();
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (amplia)
            Container(
              width: 226,
              color: const Color(0xFFF1F3EB),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 28, 15, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 15),
                      child: Text(
                        admin ? 'ADMINISTRACIÓN' : 'EXPLORA Y VIAJA',
                        style: const TextStyle(
                          letterSpacing: 1.7,
                          color: gris,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (var i = 0; i < destinos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          selected: i == pagina,
                          selectedTileColor: const Color(0xFFDDEBDE),
                          leading: Icon(destinos[i].$1, size: 21),
                          title: Text(
                            destinos[i].$2,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => ir(i),
                        ),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        admin
                            ? 'Gestiona las escapadas desde un mismo lugar.'
                            : 'Salidas desde CDMX.\nPlanes para cambiar de aire.',
                        style: const TextStyle(
                          color: gris,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(index: pagina, children: vistas),
          ),
        ],
      ),
      bottomNavigationBar: amplia
          ? null
          : NavigationBar(
              height: 68,
              selectedIndex: pagina,
              onDestinationSelected: ir,
              backgroundColor: Colors.white,
              destinations: destinos
                  .map(
                    (d) => NavigationDestination(icon: Icon(d.$1), label: d.$2),
                  )
                  .toList(),
            ),
    );
  }
}
