import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/administracion.dart';
import '../controladores/sesion.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  Future<void> cambiarPeriodo(
    BuildContext context,
    Administracion admin,
  ) async {
    final hoy = DateTime.now();
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: hoy,
      initialDateRange: DateTimeRange(
        start: admin.desde ?? DateTime(hoy.year, hoy.month),
        end: admin.hasta ?? hoy,
      ),
    );
    if (periodo == null || !context.mounted) return;
    if (periodo.duration.inDays > 89) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Elige hasta 90 días.')));
      return;
    }
    admin.desde = periodo.start;
    admin.hasta = periodo.end;
    await admin.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Administracion>();
    final panel = admin.panel;
    return Pagina(
      contenido: [
        const Encabezado(
          'Control de la agencia',
          'Panel de actividad',
          'Revisa qué buscan los viajeros y qué escapadas terminan apartando.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => cambiarPeriodo(context, admin),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                admin.desde == null
                    ? 'Este mes · Cambiar periodo'
                    : '${fecha(admin.desde!)} a ${fecha(admin.hasta!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: admin.cargando ? null : admin.cargar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (admin.error != null) ...[
          Mensaje(admin.error!),
          const SizedBox(height: 16),
        ],
        if (admin.cargando) const LinearProgressIndicator(),
        if (panel != null) ...[
          LayoutBuilder(
            builder: (context, ancho) {
              final columnas = ancho.maxWidth > 680
                  ? 3
                  : ancho.maxWidth > 420
                  ? 2
                  : 1;
              final width = (ancho.maxWidth - 14 * (columnas - 1)) / columnas;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: _Indicador(
                      'Solicitudes',
                      panel.solicitudes,
                      Icons.explore_outlined,
                      suave,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _Indicador(
                      'Apartados',
                      panel.apartados,
                      Icons.airplane_ticket_outlined,
                      const Color(0xFFF6E7DC),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _Indicador(
                      'Clientes registrados',
                      admin.clientes.length,
                      Icons.people_outline,
                      const Color(0xFFF1ECD5),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _Grafica(panel),
          const SizedBox(height: 18),
          Caja(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividad por cliente',
                  style: TextStyle(fontFamily: 'Editorial', fontSize: 23),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Conteos del periodo seleccionado.',
                  style: TextStyle(color: gris, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (panel.clientes.isEmpty)
                  const Text('Todavía no hay registros en el periodo.')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Cliente')),
                        DataColumn(label: Text('Solicitudes'), numeric: true),
                        DataColumn(label: Text('Apartados'), numeric: true),
                      ],
                      rows: panel.clientes
                          .map(
                            (c) => DataRow(
                              cells: [
                                DataCell(Text(c.cuenta.nombre)),
                                DataCell(Text('${c.solicitudes}')),
                                DataCell(Text('${c.apartados}')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Indicador extends StatelessWidget {
  final String nombre;
  final int valor;
  final IconData icono;
  final Color fondo;
  const _Indicador(this.nombre, this.valor, this.icono, this.fondo);
  @override
  Widget build(BuildContext context) => Caja(
    color: fondo,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: verde, size: 23),
        const SizedBox(height: 14),
        Text(
          '$valor',
          style: const TextStyle(fontFamily: 'Editorial', fontSize: 37),
        ),
        Text(nombre, style: const TextStyle(color: gris, fontSize: 12)),
      ],
    ),
  );
}

class _Grafica extends StatelessWidget {
  final PanelDatos panel;
  const _Grafica(this.panel);
  @override
  Widget build(BuildContext context) {
    final maximo = panel.estilos.values.fold(1, math.max);
    const colores = {
      'naturaleza': verde,
      'cultura': coral,
      'descanso': Color(0xFFAB812C),
    };
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué estilos se apartan más?',
            style: TextStyle(fontFamily: 'Editorial', fontSize: 23),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apartados válidos en el periodo, agrupados por estilo.',
            style: TextStyle(color: gris, fontSize: 12),
          ),
          for (final barra in panel.estilos.entries)
            Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(estilo(barra.key)),
                      const Spacer(),
                      Text(
                        '${barra.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: barra.value / maximo,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    color: colores[barra.key],
                    backgroundColor: suave,
                    semanticsLabel: estilo(barra.key),
                    semanticsValue: '${barra.value} apartados',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ClientesAdmin extends StatelessWidget {
  const ClientesAdmin({super.key});

  Future<void> promover(
    BuildContext context,
    Administracion admin,
    Cuenta cuenta,
  ) async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar permisos de administrador'),
        content: Text(
          '${cuenta.nombre} podrá consultar el panel y cambiar permisos de otras cuentas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cambio'),
          ),
        ],
      ),
    );
    if (aceptar != true || !context.mounted) return;
    try {
      await admin.promover(cuenta);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cuenta.nombre} ahora es administrador.')),
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
    final admin = context.watch<Administracion>();
    return Pagina(
      maximo: 920,
      contenido: [
        const Encabezado(
          'Accesos de la agencia',
          'Clientes',
          'Consulta las cuentas de cliente y asigna permisos de administrador cuando corresponda.',
        ),
        const SizedBox(height: 24),
        if (admin.error != null) ...[
          Mensaje(admin.error!),
          const SizedBox(height: 12),
        ],
        if (admin.cargando)
          const LinearProgressIndicator()
        else if (admin.clientes.isEmpty)
          const Vacio(
            'Sin clientes pendientes',
            'Las nuevas cuentas aparecerán aquí.',
          )
        else
          for (final cuenta in admin.clientes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Caja(
                child: LayoutBuilder(
                  builder: (context, m) {
                    final datos = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cuenta.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cuenta.correo,
                          style: const TextStyle(color: gris, fontSize: 12),
                        ),
                      ],
                    );
                    final boton = OutlinedButton.icon(
                      onPressed: () => promover(context, admin, cuenta),
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 17,
                      ),
                      label: const Text('Hacer administrador'),
                    );
                    if (m.maxWidth < 520) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [datos, const SizedBox(height: 13), boton],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: datos),
                        boton,
                      ],
                    );
                  },
                ),
              ),
            ),
      ],
    );
  }
}

class ModeloAdmin extends StatelessWidget {
  const ModeloAdmin({super.key});
  String porcentaje(num? n) =>
      n == null ? 'Pendiente' : '${(n * 100).toStringAsFixed(1)} %';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Administracion>();
    final fase = context.watch<Sesion>().fase;
    final modelo = admin.modelo;
    final real = modelo?['origen'] == 'elecciones_piloto';
    final disponible = modelo?['disponible'] == true;
    return Pagina(
      maximo: 920,
      contenido: [
        const Encabezado(
          'Aprendizaje automático',
          'El motor de Mi brújula',
          'Entrena el recomendador con las elecciones de clientes que registraron un apartado durante el piloto.',
        ),
        const SizedBox(height: 18),
        Mensaje(
          fase == 'piloto'
              ? 'Fase activa: piloto. Los clientes eligen entre paquetes compatibles.'
              : 'Fase activa: recomendación. FastAPI aplica el modelo y prioriza los paquetes compatibles.',
          esError: false,
        ),
        const SizedBox(height: 17),
        Caja(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Etiqueta(
                real
                    ? 'Elecciones del piloto'
                    : disponible
                    ? 'Datos sintéticos de demostración'
                    : 'Modelo pendiente',
              ),
              const SizedBox(height: 13),
              Text(
                modelo?['version'] ?? 'Aún sin entrenar',
                style: const TextStyle(fontFamily: 'Editorial', fontSize: 26),
              ),
              const SizedBox(height: 10),
              Text(
                real
                    ? '${modelo!['registros']} elecciones · ${modelo['participantes']} participantes'
                    : disponible
                    ? 'El modelo de demostración sirve para probar el recorrido completo.'
                    : 'Activa el piloto y reúne elecciones antes de usar la recomendación.',
                style: const TextStyle(color: gris, height: 1.6),
              ),
              if (real) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Etiqueta('F1 macro ${porcentaje(modelo!['f1_macro'])}'),
                    Etiqueta('Línea base ${porcentaje(modelo['f1_base'])}'),
                  ],
                ),
                const SizedBox(height: 17),
                const Text(
                  'Matriz de confusión · real por fila y predicción por columna',
                  style: TextStyle(fontSize: 12, color: gris),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Estilo real')),
                      for (final clase in modelo['clases'])
                        DataColumn(label: Text(estilo(clase)), numeric: true),
                    ],
                    rows: [
                      for (var i = 0; i < modelo['clases'].length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text(estilo(modelo['clases'][i]))),
                            for (final cantidad in modelo['matriz'][i])
                              DataCell(Text('$cantidad')),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Para entrenar, reúne al menos 12 elecciones de 6 clientes distintos y ejemplos de los tres estilos.',
                style: TextStyle(color: gris, height: 1.6, fontSize: 12),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: admin.entrenando || admin.cargando
                    ? null
                    : admin.entrenar,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  admin.entrenando ? 'Entrenando…' : 'Entrenar con el piloto',
                ),
              ),
              if (admin.error != null) ...[
                const SizedBox(height: 14),
                Mensaje(admin.error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
