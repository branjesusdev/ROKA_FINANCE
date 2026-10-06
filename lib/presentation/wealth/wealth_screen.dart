import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/debts/debt_detail_screen.dart';
import 'package:finance_app/presentation/home/widgets/net_worth_card.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/labels.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/transaction_tile.dart';
import 'package:finance_app/presentation/wealth/wealth_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Patrimonio: activos, inversiones y deudas. Patrimonio = activos − pasivos.
class WealthScreen extends ConsumerWidget {
  const new({super.key});

  static const _spacing = SizedBox(height: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorth = ref.watch(netWorthProvider).value;
    final assets = ref.watch(assetsProvider).value ?? const [];
    final investments = ref.watch(investmentsProvider).value ?? const [];
    final portfolio = ref.watch(portfolioProvider).value;
    final debts = ref.watch(debtsProvider).value ?? const [];
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (netWorth != null) NetWorthCard(netWorth: netWorth),
        _spacing,
        SectionCard(
          title: 'Activos',
          trailing: _AddButton(
            tooltip: 'Agregar activo',
            onPressed: () =>
                showFormSheet<void>(context, const AssetFormSheet()),
          ),
          child: assets.isEmpty
              ? const _EmptyHint(
                  'Agrega tus cuentas, efectivo, vehículo o propiedades.',
                )
              : Column(
                  children: [
                    for (final asset in assets)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Labels.assetIcon(asset.type)),
                        title: Text(asset.name),
                        subtitle: Text(
                          '${Labels.asset(asset.type)} · valorado '
                          '${Formatters.shortDate(asset.valuedAt)}',
                        ),
                        trailing: Text(
                          Formatters.money(asset.currentValue),
                          style: theme.textTheme.titleSmall,
                        ),
                        onTap: () => showFormSheet<void>(
                          context,
                          AssetFormSheet(asset: asset),
                        ),
                      ),
                  ],
                ),
        ),
        _spacing,
        SectionCard(
          title: 'Inversiones',
          trailing: _AddButton(
            tooltip: 'Agregar inversión',
            onPressed: () =>
                showFormSheet<void>(context, const InvestmentFormSheet()),
          ),
          child: investments.isEmpty
              ? const _EmptyHint(
                  'Registra fondos, CDT o acciones y su valor actual.',
                )
              : Column(
                  children: [
                    if (portfolio != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: LabeledValue(
                                label: 'Invertido',
                                value: Formatters.money(portfolio.invested),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: 'Valor actual',
                                value: Formatters.money(portfolio.current),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: 'Rentabilidad',
                                value: _returnText(portfolio.returnRate),
                                valueColor: _returnColor(
                                  portfolio.returnRate,
                                  theme,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final investment in investments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.trending_up),
                        title: Text(investment.name),
                        subtitle: Text(
                          '${Labels.investment(investment.type)} · '
                          '${_returnText(investment.returnRate)}',
                        ),
                        trailing: Text(
                          Formatters.money(investment.currentValue),
                          style: theme.textTheme.titleSmall,
                        ),
                        onTap: () => showFormSheet<void>(
                          context,
                          InvestmentFormSheet(investment: investment),
                        ),
                      ),
                  ],
                ),
        ),
        _spacing,
        SectionCard(
          title: 'Deudas y créditos',
          trailing: _AddButton(
            tooltip: 'Agregar deuda',
            onPressed: () =>
                showFormSheet<void>(context, const DebtFormSheet()),
          ),
          child: debts.isEmpty
              ? const _EmptyHint(
                  'Registra créditos, tarjetas o préstamos para ver cuánto '
                  'te falta por pagar.',
                )
              : Column(
                  children: [for (final debt in debts) _DebtTile(debt: debt)],
                ),
        ),
      ],
    );
  }

  static String _returnText(Percentage? rate) => rate == null
      ? 'Sin rentabilidad'
      : '${rate.isNegative ? '' : '+'}${Formatters.percent(rate)}';

  static Color? _returnColor(Percentage? rate, ThemeData theme) {
    if (rate == null) return null;
    return rate.isNegative
        ? theme.colorScheme.error
        : TransactionTile.incomeColor;
  }
}

class _DebtTile extends StatelessWidget {
  const new({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final paid = Percentage.ratio(debt.paidAmount, debt.originalAmount);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Labels.debtIcon(debt.type)),
      title: Text(debt.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: paid?.fraction.clamp(0, 1).toDouble() ?? 0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            semanticsLabel: 'Pagado',
            semanticsValue: paid == null ? null : Formatters.percent(paid),
          ),
          const SizedBox(height: 4),
          Text(
            debt.isPaidOff
                ? '¡Pagada!'
                : 'Pagado ${paid == null ? '-' : Formatters.percent(paid)}',
          ),
        ],
      ),
      trailing: Text(
        Formatters.money(debt.currentBalance),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DebtDetailScreen(debtId: debt.id),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const new({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: const Icon(Icons.add),
  );
}

class _EmptyHint extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}
