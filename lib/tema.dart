import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const verde = Color(0xFF155D4E);
const tinta = Color(0xFF16362F);
const crema = Color(0xFFF8F7F1);
const suave = Color(0xFFE8EFE8);
const coral = Color(0xFFD66A4D);
const gris = Color(0xFF5E7068);

String dinero(int valor) => NumberFormat.currency(
  locale: 'es_MX',
  symbol: r'$',
  decimalDigits: 0,
).format(valor);
String fecha(DateTime valor) => DateFormat('d MMM yyyy', 'es_MX').format(valor);
String estilo(String? valor) => switch (valor) {
  'naturaleza' => 'Naturaleza',
  'cultura' => 'Cultura',
  'descanso' => 'Descanso',
  _ => 'Exploración libre',
};
String traslado(int min) =>
    min % 60 == 0 ? '${min ~/ 60} h' : '${min ~/ 60} h ${min % 60} min';

ThemeData tema() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Noto',
    scaffoldBackgroundColor: crema,
    colorScheme: ColorScheme.fromSeed(
      seedColor: verde,
      primary: verde,
      surface: Colors.white,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: tinta, displayColor: tinta),
    appBarTheme: const AppBarTheme(
      backgroundColor: crema,
      foregroundColor: tinta,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF6F8F4),
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDDE5DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: verde, width: 1.5),
      ),
    ),
    dividerColor: const Color(0xFFDCE3DA),
  );
}
