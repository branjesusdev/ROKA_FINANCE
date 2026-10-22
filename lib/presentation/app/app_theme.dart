import 'package:flutter/material.dart';

/// "Roka Neo": base neutra casi negra (como Spotify) con un acento lima
/// eléctrico y apoyos vívidos (cian, azul, naranja, ámbar, menta) que solo
/// van en rellenos, gráficas y brillos — nunca como color de texto sobre
/// fondo claro. Jerarquía y orden al estilo Apple: tipografía Inter con
/// pesos marcados, mucho aire, tarjetas sin sombra. Todo texto ≥ 7:1 (AAA)
/// sobre su fondo; el rojo se reserva para alertas. Sin rosados ni morados.
abstract final class AppTheme {
  static const fontFamily = 'Inter';

  /// Casi negro neutro: texto en claro, barra inferior, botón + y base de
  /// las tarjetas protagonistas.
  static const ink = Color(0xFF0A0B0D);

  /// Lima eléctrico de la marca: lo activo, el número protagonista y el
  /// botón principal en oscuro. Sobre él siempre texto [onAccent].
  static const accent = Color(0xFFC6FF3D);
  static const onAccent = ink;

  /// Apoyos vívidos (rellenos, gráficas, brillos).
  static const cyan = Color(0xFF22D3EE);
  static const blue = Color(0xFF3B82F6);
  static const orange = Color(0xFFFB923C);
  static const sun = Color(0xFFFBBF24);
  static const mint = Color(0xFF34D399);
  static const sky = Color(0xFF7DD3FC);

  /// Barra inferior en oscuro (se distingue del fondo).
  static const inkOnDark = _darkRaised;

  /// Iconos inactivos de la barra inferior (≥ 7:1 sobre la barra).
  static const inkMuted = Color(0xFFA9B1BA);

  /// Base de las tarjetas protagonistas (siempre oscuras).
  static const heroBase = Color(0xFF0E1013);
  static const heroBaseEnd = Color(0xFF16191D);

  /// Texto principal y secundario sobre las tarjetas protagonistas.
  static const onHero = Color(0xFFFFFFFF);
  static const onHeroMuted = Color(0xFFE1E6EA);

  // Oscuro: neutros sin tinte verde.
  static const _darkBackground = Color(0xFF0A0B0D);
  static const _darkCard = Color(0xFF15171A);
  static const _darkRaised = Color(0xFF1C1F23);
  static const _darkHigh = Color(0xFF24282D);
  static const _darkOutline = Color(0xFF2C3036);
  static const _darkText = Color(0xFFF5F7FA);
  static const _darkMuted = Color(0xFFA9B1BA);

  // Claro: gris de lista agrupada (Apple) con tarjetas blancas.
  static const _lightBackground = Color(0xFFF2F3F5);
  static const _lightHigh = Color(0xFFE8EAED);
  static const _lightOutline = Color(0xFFD9DCE1);
  static const _lightMuted = Color(0xFF4B535C);
  static const _error = Color(0xFFB91C1C);

  static const _cardRadius = 22.0;
  static const _controlRadius = 14.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    // El esquema tonal genera terciarios y contenedores rosados: se
    // reemplazan por neutros y el lima.
    final scheme = isLight
        ? base.copyWith(
            primary: ink,
            onPrimary: Colors.white,
            primaryContainer: accent,
            onPrimaryContainer: ink,
            secondary: const Color(0xFF1D4ED8),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFEAF7C9),
            onSecondaryContainer: ink,
            tertiary: const Color(0xFF0E7490),
            tertiaryContainer: const Color(0xFFDDF4F8),
            onTertiaryContainer: ink,
            error: _error,
            errorContainer: const Color(0xFFFDECEC),
            onErrorContainer: const Color(0xFF7F1D1D),
            surface: Colors.white,
            onSurface: ink,
            onSurfaceVariant: _lightMuted,
            outline: const Color(0xFF8A929B),
            outlineVariant: _lightOutline,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: const Color(0xFFF7F8FA),
            surfaceContainer: const Color(0xFFF2F3F5),
            surfaceContainerHigh: const Color(0xFFECEEF0),
            surfaceContainerHighest: _lightHigh,
          )
        : base.copyWith(
            primary: accent,
            onPrimary: ink,
            primaryContainer: _darkHigh,
            onPrimaryContainer: accent,
            secondary: sky,
            onSecondary: ink,
            secondaryContainer: const Color(0xFF26330F),
            onSecondaryContainer: const Color(0xFFE9FFC2),
            tertiary: cyan,
            tertiaryContainer: _darkHigh,
            onTertiaryContainer: const Color(0xFFCFF7FD),
            error: const Color(0xFFFCA5A5),
            errorContainer: const Color(0xFF3A1F1F),
            onErrorContainer: const Color(0xFFFECACA),
            surface: _darkBackground,
            onSurface: _darkText,
            onSurfaceVariant: _darkMuted,
            outline: const Color(0xFF6B737C),
            outlineVariant: _darkOutline,
            surfaceContainerLowest: _darkBackground,
            surfaceContainerLow: _darkCard,
            surfaceContainer: _darkCard,
            surfaceContainerHigh: _darkRaised,
            surfaceContainerHighest: _darkHigh,
          );
    final background = isLight ? _lightBackground : scheme.surface;
    final text = _textTheme(
      isLight
          ? Typography.material2021().black
          : Typography.material2021().white,
      scheme,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_controlRadius),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_controlRadius),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      // Pantallas que entran deslizando con fundido (Android moderno) y el
      // gesto de atrás predictivo.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          // En oscuro un borde sutil separa la tarjeta del fondo.
          side: isLight
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          foregroundColor: isLight ? ink : accent,
          textStyle: text.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isLight ? ink : accent)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isLight ? Colors.white : ink)
                : scheme.onSurface,
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? const Color(0xFFF5F6F8)
            : scheme.surfaceContainerHigh,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: isLight ? accent : scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? ink : _darkHigh,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: accent,
        shape: controlShape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight ? ink : accent,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        shape: CircleBorder(),
      ),
    );
  }

  /// Jerarquía tipo Apple: números y títulos pesados con interletrado
  /// cerrado; cuerpo regular con buena altura de línea; cifras tabulares
  /// para que los montos se alineen.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? tune(
      TextStyle? style, {
      FontWeight? weight,
      double? spacing,
      double? height,
      Color? color,
    }) => style?.copyWith(
      fontFamily: fontFamily,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color ?? scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    const heavy = FontWeight.w800;
    const bold = FontWeight.w700;
    const semi = FontWeight.w600;
    return base.copyWith(
      displayLarge: tune(base.displayLarge, weight: heavy, spacing: -1.5),
      displayMedium: tune(base.displayMedium, weight: heavy, spacing: -1.2),
      displaySmall: tune(base.displaySmall, weight: heavy, spacing: -1),
      headlineLarge: tune(base.headlineLarge, weight: heavy, spacing: -0.8),
      headlineMedium: tune(base.headlineMedium, weight: heavy, spacing: -0.6),
      headlineSmall: tune(base.headlineSmall, weight: bold, spacing: -0.4),
      titleLarge: tune(base.titleLarge, weight: bold, spacing: -0.3),
      titleMedium: tune(base.titleMedium, weight: bold, spacing: -0.2),
      titleSmall: tune(base.titleSmall, weight: semi, spacing: -0.1),
      bodyLarge: tune(base.bodyLarge, height: 1.4, spacing: -0.1),
      bodyMedium: tune(base.bodyMedium, height: 1.4),
      bodySmall: tune(
        base.bodySmall,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: tune(base.labelLarge, weight: semi),
      labelMedium: tune(base.labelMedium, weight: semi),
      labelSmall: tune(
        base.labelSmall,
        weight: semi,
        spacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
