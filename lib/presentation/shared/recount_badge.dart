import 'package:finance_app/domain/cycles/cycle_recount.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';

/// Color, icono y texto del desbalance de un reconteo (nunca solo color):
/// verde si es poco, ámbar si vale la pena revisar, rojo si es grande.
abstract final class RecountStyle {
  static Color color(RecountLevel level, ColorScheme scheme) => switch (level) {
    RecountLevel.fine => StatusColors.okOf(scheme),
    RecountLevel.warning => StatusColors.warningOf(scheme),
    RecountLevel.alert => scheme.error,
  };

  static IconData icon(RecountLevel level) => switch (level) {
    RecountLevel.fine => Icons.check_circle_outline,
    RecountLevel.warning => Icons.warning_amber_outlined,
    RecountLevel.alert => Icons.error_outline,
  };

  static String label(RecountLevel level) => switch (level) {
    RecountLevel.fine => 'Cuadra bien',
    RecountLevel.warning => 'Revisa',
    RecountLevel.alert => 'Desbalance grande',
  };

  /// "Se escaparon $X en gastos" / "Tenías $X más de lo registrado".
  static String detail(CycleRecount recount) {
    final gap = Formatters.money(recount.difference.abs);
    if (recount.difference.isZero) return 'Cuadra exacto con lo registrado.';
    return recount.difference.isNegative
        ? 'Se escaparon $gap sin registrar.'
        : 'Tenías $gap más de lo registrado.';
  }
}

/// Línea con el resultado del reconteo: nivel + diferencia.
class RecountBadge extends StatelessWidget {
  const new({required this.recount, super.key});

  final CycleRecount recount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = recount.level;
    final color = RecountStyle.color(level, theme.colorScheme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(RecountStyle.icon(level), size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${RecountStyle.label(level)}. ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: RecountStyle.detail(recount)),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
