import 'package:finance_app/domain/wisdom/wealth_wisdom.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/shared/decor.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:flutter/material.dart';

/// Lo primero al abrir: saludo, fecha y la frase del día con qué hacer hoy.
/// Tocar muestra u oculta el "Hoy:" para no ocupar tanto.
class GreetingBanner extends StatefulWidget {
  const new({required this.now, super.key});

  /// Ahora (del reloj de la app): fecha y saludo según la hora.
  final DateTime now;

  @override
  State<GreetingBanner> createState() => _GreetingBannerState();
}

class _GreetingBannerState extends State<GreetingBanner> {
  static const _morningEnd = 12;
  static const _afternoonEnd = 19;

  bool _expanded = false;

  String get _greeting => switch (widget.now.hour) {
    < _morningEnd => 'Buenos días',
    < _afternoonEnd => 'Buenas tardes',
    _ => 'Buenas noches',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = WealthWisdom.quoteFor(widget.now);
    // Arte del día (claro u oscuro según el tema), texto ≥ 7:1.
    final art = DailyArt.forDay(widget.now);
    final palette = HeroPalette.of(context);
    final ink = palette.text;
    final muted = palette.muted;
    return Semantics(
      button: true,
      label: '$_greeting. Frase del día: ${quote.text} ${quote.source}',
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: DecorBackdrop.daily(
          art,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: AnimatedSize(
            duration: Motion.enabled(context) ? Motion.medium : Duration.zero,
            curve: Motion.emphasized,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.sun.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 18,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${Formatters.longDate(widget.now)} · '
                            '${art.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded, color: ink, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        quote.text,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ink,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '— ${quote.source}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                if (_expanded && quote.today != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.panel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Hoy: ${quote.today}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
