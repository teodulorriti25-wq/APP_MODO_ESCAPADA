// Entrada de Flutter. La sesión decide qué conjunto de vistas se muestra.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'controladores/sesion.dart';
import 'servicios/api.dart';
import 'tema.dart';
import 'vistas/entrada.dart';
import 'vistas/navegacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  // La interfaz web también se puede recorrer con lector de pantalla.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(
    ChangeNotifierProvider(
      create: (_) => Sesion(Api())..iniciar(),
      child: const ModoEscapada(),
    ),
  );
}

class ModoEscapada extends StatelessWidget {
  const ModoEscapada({super.key});
  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final cuenta = sesion.cuenta;
    return MaterialApp(
      key: ValueKey(cuenta == null ? 'entrada' : '${cuenta.id}-${cuenta.rol}'),
      title: 'Modo Escapada',
      debugShowCheckedModeBanner: false,
      theme: tema(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: sesion.iniciando
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : cuenta == null
          ? const Entrada()
          : AreaPrivada(cuenta),
    );
  }
}
