import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/days/daily_bars_card.dart';
import 'package:finance_app/presentation/home/widgets/category_breakdown_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_pulse_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_savings_card.dart';
import 'package:finance_app/presentation/home/widgets/kind_toggle.dart';
import 'package:finance_app/presentation/home/widgets/money_hero_card.dart';
import 'package:finance_app/presentation/home/widgets/next_action_card.dart';
import 'package:finance_app/presentation/home/widgets/obligations_card.dart';
import 'package:finance_app/presentation/home/widgets/pending_bills_card.dart';
import 'package:finance_app/presentation/home/widgets/provisions_card.dart';
import 'package:finance_app/presentation/home/widgets/reconcile_sheet.dart';
import 'package:finance_app/presentation/home/widgets/spending_radar_card.dart';
import 'package:finance_app/presentation/home/widgets/wealth_glance_card.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abrir → entender, en este orden: cuánto puedo gastar de verdad, qué hago
/// ahora, qué pagos vienen y si me alcanzan, en qué se va el dinero y cómo
/// va mi patrimonio.
class HomeScreen extends ConsumerStatefulWidget {
  const new({
    required this.onSeeAllTransactions,
    required this.onOpenAnalysis,
    required this.onOpenCfo,
    required this.onOpenWealth,
    super.key,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenAnalysis;
  final VoidCallback onOpenCfo;
  final VoidCallback onOpenWealth;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _spacing = SizedBox(height: 16);

  TransactionKind _kind = TransactionKind.expense;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(moneyOverviewProvider),
      builder: (overview) {
        final summary = ref.watch(cycleSummaryProvider).requireValue;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
          children: [
            MoneyHeroCard(summary: summary, overview: overview),
            const Center(child: ReconcileButton()),
            if (summary.upcomingFixed.awaitingAmount.isNotEmpty) ...[
              PendingBillsCard(bills: summary.upcomingFixed.awaitingAmount),
              _spacing,
            ],
            NextActionCard(onOpenCfo: widget.onOpenCfo),
            _spacing,
            ObligationsCard(overview: overview),
            _spacing,
            ProvisionsCard(plan: summary.provisionPlan),
            _spacing,
            KindToggle(
              selected: _kind,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
            _spacing,
            CategoryBreakdownCard(
              totals: _kind == TransactionKind.expense
                  ? summary.expenseTotals
                  : summary.incomeTotals,
              cycle: summary.cycle,
              kind: _kind,
              onOpenAnalysis: widget.onOpenAnalysis,
            ),
            _spacing,
            const DailyBarsCard(),
            _spacing,
            if (summary.previousLeft case final left? when left.isPositive) ...[
              CycleSavingsCard(amount: left, cycle: summary.cycle),
              _spacing,
            ],
            WealthGlanceCard(onOpenWealth: widget.onOpenWealth),
            _spacing,
            const SpendingRadarCard(),
            _spacing,
            CyclePulseCard(onSeeAll: widget.onSeeAllTransactions),
          ],
        );
      },
    );
  }
}
