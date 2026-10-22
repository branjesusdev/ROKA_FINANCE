import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/shared/decor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('el texto se lee (≥ 7:1) aun donde el brillo del día es más fuerte', () {
    // Peor caso: brillo al máximo + textura blanca encima, sobre la base
    // más clara del degradado.
    // Trazo más fuerte de la textura: 0,28 × 0,2.
    const texture = 0.06;
    for (final art in DailyArt.all) {
      for (final glow in art.colors) {
        final lit = Color.alphaBlend(
          Colors.white.withValues(alpha: texture),
          Color.alphaBlend(
            glow.withValues(alpha: DailyArt.maxGlowAlpha),
            AppTheme.heroBaseEnd,
          ),
        );
        for (final (name, fg) in [
          ('texto', AppTheme.onHero),
          ('texto secundario', AppTheme.onHeroMuted),
          ('número en lima', AppTheme.accent),
        ]) {
          expect(
            _contrast(fg, lit),
            greaterThanOrEqualTo(7),
            reason: '${art.name}: $name',
          );
        }
      }
    }
  });

  test('cambia de un día al siguiente y se repite cada semana', () {
    final today = DailyArt.forDay(DateTime(2026, 10, 20));
    expect(DailyArt.forDay(DateTime(2026, 10, 21)), isNot(today));
    expect(DailyArt.forDay(DateTime(2026, 10, 27)), today);
  });
}
