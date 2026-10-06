import 'package:finance_app/domain/wealth/net_worth_calculator.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';

/// ¿Cuánto tengo? ¿Cuánto debo?
class NetWorthCard extends StatelessWidget {
  const new({required this.netWorth, super.key});

  final NetWorth netWorth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimonio neto',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.money(netWorth.total),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LabeledValue(
                    label: 'Tengo (activos)',
                    value: Formatters.money(netWorth.totalAssets),
                    valueColor: scheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: 'Debo (pasivos)',
                    value: Formatters.money(netWorth.liabilities),
                    valueColor: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
