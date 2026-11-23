import 'package:flutter/material.dart';

/// Paleta tomada de `assets/css/styles.css` del sitio web.
class JudyColors {
  JudyColors._();

  static const naranja = Color(0xFFF37021); // --letras-especiales
  static const naranjaOscuro = Color(0xFFE06C00); // hover de botones
  static const azulMarino = Color(0xFF0B132B); // --azul-acento (claro) / fondo oscuro
  static const tarjetaOscura = Color(0xFF1C2541); // --fondo-tarjeta (oscuro)
  static const bordeOscuro = Color(0xFF2E3A59);
  static const azulCielo = Color(0xFF4EA8DE); // --azul-acento (oscuro)
  static const tarjetaClara = Color(0xFFF8FAFC);
  static const bordeClaro = Color(0xFFE2E8F0);
  static const textoClaro = Color(0xFF0F172A);
  static const textoSecundario = Color(0xFF475569);
  static const exito = Color(0xFF22C55E);
  static const aviso = Color(0xFFF59E0B);
}

ThemeData judyTheme(Brightness brillo) {
  final oscuro = brillo == Brightness.dark;
  final esquema = ColorScheme.fromSeed(
    seedColor: JudyColors.naranja,
    brightness: brillo,
  ).copyWith(
    primary: JudyColors.naranja,
    onPrimary: Colors.white,
    secondary: oscuro ? JudyColors.azulCielo : JudyColors.azulMarino,
    onSecondary: Colors.white,
    surface: oscuro ? JudyColors.azulMarino : Colors.white,
    surfaceContainerHighest:
        oscuro ? JudyColors.tarjetaOscura : JudyColors.tarjetaClara,
    outlineVariant: oscuro ? JudyColors.bordeOscuro : JudyColors.bordeClaro,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: esquema.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: oscuro ? JudyColors.azulMarino : Colors.white,
      foregroundColor: oscuro ? Colors.white : JudyColors.textoClaro,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      color: esquema.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: esquema.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: esquema.surfaceContainerHighest,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: JudyColors.naranja),
  );
}
