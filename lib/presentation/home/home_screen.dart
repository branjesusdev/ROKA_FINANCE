import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/days/daily_bars_card.dart';
import 'package:finance_app/presentation/home/widgets/category_breakdown_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_header.dart';
import 'package:finance_app/presentation/home/widgets/cycle_pulse_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_savings_card.dart';
import 'package:finance_app/presentation/home/widgets/daily_cap_card.dart';
import 'package:finance_app/presentation/home/widgets/kind_toggle.dart';
import 'package:finance_app/presentation/home/widgets/pending_bills_card.dart';
import 'package:finance_app/presentation/home/widgets/provisions_card.dart';
import 'package:finance_app/presentation/home/widgets/spending_radar_card.dart';
import 'package:finance_app/presentation/home/widgets/upcoming_fixed_card.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abrir → entender: cuánto queda del sueldo en este ciclo y en qué se va.
/// El patrimonio vive en su propia sección.
class HomeScreen extends ConsumerStatefulWidget {
  const new({
    required this.onSeeAllTransactions,
    required this.onOpenAnalysis,
    super.key,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenAnalysis;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _spacing = SizedBox(height: 16);

  TransactionKind _kind = TransactionKind.expense;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(cycleSummaryProvider),
      builder: (summary) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
        children: [
          CycleHeader(summary: summary),
          _spacing,
          if (summary.upcomingFixed.awaitingAmount.isNotEmpty) ...[
            PendingBillsCard(bills: summary.upcomingFixed.awaitingAmount),
            _spacing,
          ],
          if (summary.dailyCap case final cap?
              when summary.income.isPositive) ...[
            DailyCapCard(cap: cap),
            _spacing,
          ],
          ProvisionsCard(plan: summary.provisionPlan),
          _spacing,
          const DailyBarsCard(),
          _spacing,
          if (summary.previousLeft case final left? when left.isPositive) ...[
            CycleSavingsCard(amount: left, cycle: summary.cycle),
            _spacing,
          ],
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
          const SpendingRadarCard(),
          _spacing,
          UpcomingFixedCard(summary: summary),
          _spacing,
          CyclePulseCard(onSeeAll: widget.onSeeAllTransactions),
        ],
      ),
    );
  }
}
