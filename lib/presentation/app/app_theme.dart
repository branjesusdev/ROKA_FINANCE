import 'package:flutter/material.dart';

/// Paleta "verde bosque + lima": fondo gris verdoso, tarjetas blancas,
/// verde muy oscuro (#102521) para navegación, botón + y texto principal, y
/// lima (#B3DD62) como acento de lo activo. En oscuro, el fondo es el mismo
/// verde y el lima pasa a ser el color principal. El rojo se reserva para
/// alertas.
abstract final class AppTheme {
  /// Verde bosque (referencia del usuario, medido en la imagen).
  static const forest = Color(0xFF102521);

  /// Fondo del modo oscuro: un tono más profundo del mismo verde.
  static const _forestDeep = Color(0xFF0B201C);
  static const _forestRaised = Color(0xFF173430);
  static const _forestHigh = Color(0xFF21423C);

  /// Acento para la opción activa (p. ej. Gastos / Ingresos) y el micrófono.
  static const accent = Color(0xFFB3DD62);
  static const onAccent = forest;

  /// Barra inferior y botón +.
  static const ink = forest;

  /// Barra inferior en modo oscuro (se distingue del fondo).
  static const inkOnDark = _forestRaised;

  /// Iconos inactivos de la barra inferior.
  static const inkMuted = Color(0xFF8FA39D);

  static const _secondary = Color(0xFF2F6B5E);
  static const _error = Color(0xFFB91C1C);
  static const _lightBackground = Color(0xFFEAEEED);
  static const _lightMuted = Color(0xFF4A5A55);
  static const _cardRadius = 24.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    // El esquema tonal genera terciarios y contenedores de error rosados:
    // se reemplazan por verdes y neutros.
    final scheme = isLight
        ? base.copyWith(
            primary: forest,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE6F4C8),
            onPrimaryContainer: forest,
            secondary: _secondary,
            tertiary: _secondary,
            tertiaryContainer: const Color(0xFFD7EBE4),
            onTertiaryContainer: forest,
            secondaryContainer: const Color(0xFFE6F4C8),
            onSecondaryContainer: forest,
            error: _error,
            errorContainer: const Color(0xFFF3F4F6),
            onErrorContainer: const Color(0xFF7F1D1D),
            onSurface: forest,
            onSurfaceVariant: _lightMuted,
            surfaceContainerHighest: const Color(0xFFDDE5E2),
          )
        : base.copyWith(
            primary: accent,
            onPrimary: forest,
            primaryContainer: _forestHigh,
            onPrimaryContainer: const Color(0xFFE6F4C8),
            secondary: const Color(0xFF9FD4C4),
            tertiary: const Color(0xFF9FD4C4),
            tertiaryContainer: _forestHigh,
            onTertiaryContainer: const Color(0xFFD7EBE4),
            secondaryContainer: const Color(0xFF3A5A1E),
            onSecondaryContainer: const Color(0xFFE6F4C8),
            error: const Color(0xFFF87171),
            errorContainer: const Color(0xFF3B2A2A),
            onErrorContainer: const Color(0xFFFECACA),
            surface: _forestDeep,
            surfaceContainerLow: forest,
            surfaceContainer: forest,
            surfaceContainerHigh: _forestRaised,
            surfaceContainerHighest: _forestHigh,
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
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerLow,
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isLight ? ink : accent,
        foregroundColor: isLight ? accent : onAccent,
        shape: const CircleBorder(),
      ),
    );
  }
}
