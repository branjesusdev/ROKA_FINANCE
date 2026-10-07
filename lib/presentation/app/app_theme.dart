import 'package:flutter/material.dart';

/// Estilo sobrio y de alto contraste: fondo gris frío, tarjetas blancas,
/// verde esmeralda como color principal, azul para lo secundario y tinta
/// oscura para navegación y botón +. Sin rosados ni morados: el rojo se
/// reserva para alertas.
abstract final class AppTheme {
  static const _seed = Color(0xFF0F766E);

  /// Acento para la opción activa (p. ej. Gastos / Ingresos) y el micrófono.
  static const accent = Color(0xFF34D399);
  static const onAccent = Color(0xFF0B1F1A);

  /// Barra inferior y botón +.
  static const ink = Color(0xFF111827);

  static const _secondary = Color(0xFF1D4ED8);
  static const _error = Color(0xFFB91C1C);
  static const _lightBackground = Color(0xFFF1F3F6);
  static const _lightMuted = Color(0xFF4B5563);
  static const _cardRadius = 24.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    // El esquema tonal genera terciarios y contenedores de error rosados:
    // se reemplazan por azul y neutros.
    final scheme = isLight
        ? base.copyWith(
            primary: _seed,
            secondary: _secondary,
            tertiary: _secondary,
            tertiaryContainer: const Color(0xFFDBEAFE),
            onTertiaryContainer: const Color(0xFF1E3A8A),
            secondaryContainer: const Color(0xFFD1FAE5),
            onSecondaryContainer: const Color(0xFF064E3B),
            error: _error,
            errorContainer: const Color(0xFFF3F4F6),
            onErrorContainer: const Color(0xFF7F1D1D),
            onSurfaceVariant: _lightMuted,
          )
        : base.copyWith(
            secondary: const Color(0xFF93C5FD),
            tertiary: const Color(0xFF93C5FD),
            tertiaryContainer: const Color(0xFF1E3A8A),
            onTertiaryContainer: const Color(0xFFDBEAFE),
            secondaryContainer: const Color(0xFF064E3B),
            onSecondaryContainer: const Color(0xFFD1FAE5),
            error: const Color(0xFFF87171),
            errorContainer: const Color(0xFF374151),
            onErrorContainer: const Color(0xFFFECACA),
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
        foregroundColor: isLight ? Colors.white : onAccent,
        shape: const CircleBorder(),
      ),
    );
  }
}
