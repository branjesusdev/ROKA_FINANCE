import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/money_text.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/application/dashboard/home_summary.dart';
import 'package:finance_app/application/dashboard/money_overview.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/debt_repository.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/savings/savings_goal_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

/// A dónde va una parte del ingreso extraordinario.
enum WindfallUse {
  /// Cubrir pagos fijos y apartados que faltan (se queda en el ciclo).
  obligations,
  emergencyFund,
  debt,
  goal,
  investment,
  business,

  /// Un gusto planeado: gastar algo a propósito evita "fugas" después.
  personal,
}

final class WindfallSlice {
  const new({
    required this.use,
    required this.amount,
    required this.reason,
    this.label,
    this.targetId,
  });

  final WindfallUse use;
  final Money amount;

  /// Por qué esta parte (en simple).
  final String reason;

  /// Nombre de la meta o deuda.
  final String? label;

  /// Meta o deuda a la que se aplica al confirmar.
  final String? targetId;

  /// Se puede aplicar con un toque (meta o deuda). Lo demás es guía.
  bool get applicable =>
      targetId != null &&
      (use == WindfallUse.emergencyFund ||
          use == WindfallUse.debt ||
          use == WindfallUse.goal ||
          use == WindfallUse.business);
}

final class WindfallPlan {
  const new({required this.amount, required this.slices});

  final Money amount;
  final List<WindfallSlice> slices;
}

/// Reparte un ingreso extraordinario con prioridades fijas y explicables:
/// pagos pendientes → fondo de emergencia → deuda cara → metas → inversión
/// y negocio, con una parte pequeña para un gusto.
final class WindfallPlanner {
  const new();

  /// Del resto (después de pagos pendientes), tope por destino.
  static const emergencyShare = Percentage.whole(50);
  static const debtShare = Percentage.whole(50);
  static const goalShare = Percentage.whole(30);
  static const businessShare = Percentage.whole(30);
  static const personalShare = Percentage.whole(10);

  WindfallPlan plan({
    required Money amount,
    required MoneyOverview overview,
    required List<GoalProgressItem> goals,
    required List<Debt> debts,
    required Money essentialMonthly,
    required FinanceSettings settings,
  }) {
    final slices = <WindfallSlice>[];
    var rest = amount;
    void add(WindfallSlice slice) {
      if (!slice.amount.isPositive) return;
      slices.add(slice);
      rest -= slice.amount;
    }

    // 1. Lo comprometido primero. El ingreso ya está en el disponible: la
    // parte que no quedó libre es la que cubrió fijos, apartados y ahorro.
    final needed = (amount - overview.free.max(Money.zero)).max(Money.zero);
    add(
      WindfallSlice(
        use: WindfallUse.obligations,
        amount: needed.min(rest),
        reason:
            'Cubre lo que faltaba para tus pagos fijos, apartados y ahorro '
            'del ciclo. Se queda en tu dinero del ciclo.',
      ),
    );

    // 2. Fondo de emergencia.
    final emergency = goals
        .where((g) => g.goal.type == GoalType.emergency)
        .firstOrNull;
    final emergencyMissing =
        emergency?.progress.remaining ??
        essentialMonthly.times(settings.emergencyMonths);
    if (emergencyMissing.isPositive && rest.isPositive) {
      add(
        WindfallSlice(
          use: WindfallUse.emergencyFund,
          amount: rest.applyPercentage(emergencyShare).min(emergencyMissing),
          reason: emergency == null
              ? 'Aún no tienes fondo de emergencia (créalo en Metas para '
                    'aplicarlo).'
              : 'Le faltan ${_m(emergencyMissing)}: te protege de endeudarte '
                    'ante un imprevisto.',
          label: emergency?.goal.name,
          targetId: emergency?.goal.id,
        ),
      );
    }

    // 3. La deuda más cara.
    final expensive =
        debts
            .where(
              (d) =>
                  !d.isPaidOff &&
                  d.terms != null &&
                  Percentage.fromFraction(d.terms!.rate.annualEffective) >=
                      FinanceSettings.expensiveDebtRate,
            )
            .toList()
          ..sort(
            (a, b) => b.terms!.rate.annualEffective.compareTo(
              a.terms!.rate.annualEffective,
            ),
          );
    if (expensive.firstOrNull case final debt? when rest.isPositive) {
      final rate = Percentage.fromFraction(debt.terms!.rate.annualEffective);
      add(
        WindfallSlice(
          use: WindfallUse.debt,
          amount: rest.applyPercentage(debtShare).min(debt.currentBalance),
          reason:
              'Abonar a capital "rinde" lo que cobra: '
              '${rate.value.toStringAsFixed(1)}% al año, seguro.',
          label: debt.name,
          targetId: debt.id,
        ),
      );
    }

    // 4. La meta más cercana (que no sea emergencia ni negocio).
    final goal =
        goals
            .where(
              (g) =>
                  !g.progress.isCompleted &&
                  g.goal.type != GoalType.emergency &&
                  g.goal.type != GoalType.business,
            )
            .toList()
          ..sort(
            (a, b) => a.progress.remaining.compareTo(b.progress.remaining),
          );
    final personal = rest.applyPercentage(personalShare);
    if (goal.firstOrNull case final item? when rest.isPositive) {
      add(
        WindfallSlice(
          use: WindfallUse.goal,
          amount: rest.applyPercentage(goalShare).min(item.progress.remaining),
          reason: 'Te acerca a "${item.goal.name}" sin tocar tu sueldo.',
          label: item.goal.name,
          targetId: item.goal.id,
        ),
      );
    }

    // 5. Capital para emprender (si tienes esa meta).
    final business = goals
        .where(
          (g) => g.goal.type == GoalType.business && !g.progress.isCompleted,
        )
        .firstOrNull;
    if (business != null && rest.isPositive) {
      add(
        WindfallSlice(
          use: WindfallUse.business,
          amount: rest
              .applyPercentage(businessShare)
              .min(business.progress.remaining),
          reason: 'Capital para tu negocio: crece sin endeudarte.',
          label: business.goal.name,
          targetId: business.goal.id,
        ),
      );
    }

    // 6. Un gusto (pequeño y planeado) y el resto a invertir.
    if (rest.isPositive) {
      final treat = personal.min(rest);
      add(
        WindfallSlice(
          use: WindfallUse.personal,
          amount: treat,
          reason: 'Un gusto planeado evita gastar el resto por impulso.',
        ),
      );
      add(
        WindfallSlice(
          use: WindfallUse.investment,
          amount: rest,
          reason:
              'Lo que queda, a largo plazo y diversificado (p. ej. un fondo '
              'amplio). Puede bajar; no lo necesites en 3+ años.',
        ),
      );
    }
    return WindfallPlan(amount: amount, slices: slices);
  }

  static String _m(Money money) => MoneyText.format(money);
}

/// Aplica las partes que el usuario confirmó: aporta a metas (y lo saca del
/// dinero libre del ciclo como ahorro) y abona a deudas. Nada se aplica sin
/// confirmación.
final class ApplyWindfallSlices {
  const new({
    required this._goals,
    required this._debts,
    required this._transactions,
    required this._clock,
    required this._ids,
  });

  final SavingsGoalRepository _goals;
  final DebtRepository _debts;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGenerator _ids;

  /// Devuelve cuántas partes se aplicaron.
  Future<Result<int>> call(List<WindfallSlice> slices) {
    final applicable = slices.where((s) => s.applicable).toList();
    if (applicable.any((s) => !s.amount.isPositive)) {
      return invalid(ValidationCodes.amountMustBePositive);
    }
    return guardUseCase(() async {
      final now = _clock.now();
      for (final slice in applicable) {
        if (slice.use == WindfallUse.debt) {
          final debt = await _debts.getById(slice.targetId!);
          if (debt == null) continue;
          final applied = slice.amount.min(debt.currentBalance);
          await _debts.saveExtraPayment(
            ExtraPayment(
              id: _ids.next(),
              debtId: debt.id,
              amount: applied,
              date: now,
            ),
          );
          await _transactions.save(
            Transaction(
              id: _ids.next(),
              kind: TransactionKind.expense,
              amount: applied,
              categoryId: DefaultCategories.debtsId,
              date: now,
              createdAt: now,
              description: 'Abono extra ${debt.name}',
              debtId: debt.id,
            ),
          );
          await _debts.save(debt.afterPayment(debt.currentBalance - applied));
          continue;
        }
        await _goals.addContribution(
          GoalContribution(
            id: _ids.next(),
            goalId: slice.targetId!,
            amount: slice.amount,
            date: now,
          ),
        );
        // Cuenta como ahorro (no gasto): sale del dinero libre del ciclo.
        await _transactions.save(
          Transaction(
            id: _ids.next(),
            kind: TransactionKind.expense,
            amount: slice.amount,
            categoryId: DefaultCategories.investmentsId,
            date: now,
            createdAt: now,
            description: 'Ahorro: ${slice.label ?? 'meta'}',
          ),
        );
      }
      return applicable.length;
    });
  }
}
