import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Así está tu plata": a dónde se va lo que tienes hasta el sueldo, en una
/// barra, y las cifras que importan antes de gastar. Solo muestra datos.
class SpendSituationPanel extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(moneyOverviewProvider).value;
    final summary = ref.watch(cycleSummaryProvider).value;
    final ledger = ref.watch(cycleLedgerProvider).value;
    if (overview == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final free = overview.free;
    final slices = _slices(overview, scheme);
    final cap = summary?.dailyCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Libre para gastar', style: theme.textTheme.labelLarge),
        Text(
          Formatters.money(free),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: free.isNegative ? scheme.error : StatusColors.okOf(scheme),
          ),
        ),
        Text(
          'hasta el sueldo · ${overview.daysLeft} '
          '${overview.daysLeft == 1 ? 'día' : 'días'}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _StackedBar(slices: slices),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in slices.where((s) => s.amount.isPositive))
              _Legend(slice: s),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (cap != null)
              Expanded(
                child: _Tile(
                  icon: Icons.today_outlined,
                  label: 'Tope de hoy',
                  value: Formatters.money(cap.remainingToday.max(Money.zero)),
                  color: cap.exceeded ? scheme.error : null,
                ),
              ),
            if (ledger != null && !ledger.isEmpty)
              Expanded(
                child: _Tile(
                  icon: Icons.savings_outlined,
                  label: 'Tu dinero total',
                  value: Formatters.money(ledger.total),
                  color: ledger.total.isNegative ? scheme.error : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.receipt_long_outlined,
                label: 'Fijos que faltan',
                value: Formatters.money(overview.committed),
              ),
            ),
            Expanded(
              child: _Tile(
                icon: Icons.lock_outline,
                label: 'Ya apartado',
                value: Formatters.money(overview.provisionsSaved),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_Slice> _slices(MoneyOverview o, ColorScheme scheme) => [
    _Slice('Fijos', o.committed, StatusColors.warningOf(scheme)),
    _Slice('Pagos del año', o.provisionsPending, StatusColors.infoOf(scheme)),
    _Slice('Ahorro', o.savingsPending, scheme.tertiary),
    _Slice('Gastos del mes', o.plannedPending, scheme.outline),
    _Slice('Libre', o.free.max(Money.zero), StatusColors.okOf(scheme)),
  ];
}

class _Slice {
  const new(this.label, this.amount, this.color);

  final String label;
  final Money amount;
  final Color color;
}

class _StackedBar extends StatelessWidget {
  const new({required this.slices});

  final List<_Slice> slices;

  @override
  Widget build(BuildContext context) {
    final shown = slices.where((s) => s.amount.isPositive).toList();
    final total = Money.sum(shown.map((s) => s.amount));
    return Semantics(
      label: [for (final s in shown) '${s.label} ${Formatters.money(s.amount)}']
          .join(', '),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 18,
          child: shown.isEmpty
              ? ColoredBox(color: Theme.of(context).colorScheme.outlineVariant)
              : Row(
                  children: [
                    for (final s in shown)
                      Expanded(
                        flex: (s.amount.cents * 1000 ~/ total.cents).clamp(
                          1,
                          1000,
                        ),
                        child: ColoredBox(color: s.color),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const new({required this.slice});

  final _Slice slice;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 10, color: slice.color),
      const SizedBox(width: 4),
      Text(
        '${slice.label} ${Formatters.money(slice.amount)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
