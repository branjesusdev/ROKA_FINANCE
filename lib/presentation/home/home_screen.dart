import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/presentation/days/daily_bars_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_pulse_card.dart';
import 'package:finance_app/presentation/home/widgets/cycle_savings_card.dart';
import 'package:finance_app/presentation/home/widgets/greeting_banner.dart';
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
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abrir → entender, en este orden: la frase del día, cuánto puedo gastar
/// de verdad, qué hago ahora, qué pagos vienen y si me alcanzan y cómo va
/// mi patrimonio. El detalle por categoría vive en Movimientos.
class HomeScreen extends ConsumerWidget {
  const new({
    required this.onSeeAllTransactions,
    required this.onOpenCfo,
    required this.onOpenWealth,
    super.key,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenCfo;
  final VoidCallback onOpenWealth;

  static const _spacing = SizedBox(height: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryLate = ref.watch(salaryLateProvider).value ?? false;
    final now = ref.watch(clockProvider).now();
    return AsyncView(
      value: ref.watch(moneyOverviewProvider),
      builder: (overview) {
        final summary = ref.watch(cycleSummaryProvider).requireValue;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
          // Las tarjetas entran en cascada la primera vez.
          children: staggered([
            GreetingBanner(now: now),
            const SizedBox(height: 12),
            MoneyHeroCard(
              summary: summary,
              overview: overview,
              salaryLate: salaryLate,
            ),
            const Center(child: ReconcileButton()),
            if (summary.upcomingFixed.awaitingAmount.isNotEmpty) ...[
              PendingBillsCard(bills: summary.upcomingFixed.awaitingAmount),
              _spacing,
            ],
            NextActionCard(onOpenCfo: onOpenCfo),
            _spacing,
            ObligationsCard(overview: overview),
            _spacing,
            ProvisionsCard(plan: summary.provisionPlan),
            _spacing,
            const DailyBarsCard(),
            _spacing,
            if (summary.previousLeft case final left? when left.isPositive) ...[
              CycleSavingsCard(amount: left, cycle: summary.cycle),
              _spacing,
            ],
            WealthGlanceCard(onOpenWealth: onOpenWealth),
            _spacing,
            const SpendingRadarCard(),
            _spacing,
            CyclePulseCard(onSeeAll: onSeeAllTransactions),
          ]),
        );
      },
    );
  }
}
