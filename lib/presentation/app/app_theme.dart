import 'package:flutter/material.dart';

/// Estilo limpio: fondo gris claro, tarjetas blancas redondeadas, acento
/// lima para lo seleccionado y gris oscuro para navegación y botón +.
abstract final class AppTheme {
  static const _seed = Color(0xFF00796B);

  /// Acento para la opción activa (p. ej. Gastos / Ingresos).
  static const accent = Color(0xFFE6F14A);
  static const onAccent = Color(0xFF1C1C1E);

  /// Barra inferior y botón +.
  static const ink = Color(0xFF242426);

  static const _lightBackground = Color(0xFFEEEFF3);
  static const _cardRadius = 24.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final background = isLight ? _lightBackground : scheme.surface;
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isLight ? ink : accent,
        foregroundColor: isLight ? Colors.white : onAccent,
        shape: const CircleBorder(),
      ),
    );
  }
}
