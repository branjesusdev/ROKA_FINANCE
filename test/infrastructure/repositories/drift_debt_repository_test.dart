import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/extra_payment.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftDebtRepository repository;

  final loan = Debt(
    id: 'd1',
    name: 'Crédito vehículo',
    type: DebtType.bankLoan,
    originalAmount: const Money.pesos(30000000),
    currentBalance: const Money.pesos(20000000),
    notes: 'Banco',
    terms: LoanTerms(
      rate: const InterestRate(
        rate: Percentage.whole(18),
        type: InterestRateType.effectiveAnnual,
      ),
      monthlyPayment: const Money.pesos(1300000),
      monthlyFees: const Money.pesos(45000),
      totalInstallments: 36,
      paidInstallments: 12,
      startDate: DateTime(2025, 10),
    ),
  );

  setUp(() {
    db = createTestDatabase();
    repository = DriftDebtRepository(db);
  });

  test('guarda y recupera un crédito con condiciones', () async {
    await repository.save(loan);

    expect(await repository.getById('d1'), loan);
  });

  test('un pasivo sin condiciones conserva terms = null', () async {
    const card = Debt(
      id: 'd2',
      name: 'Tarjeta',
      type: DebtType.creditCard,
      originalAmount: Money.pesos(2000000),
      currentBalance: Money.pesos(800000),
    );
    await repository.save(card);

    expect(await repository.getById('d2'), card);
  });

  test('abonos ordenados por fecha descendente', () async {
    await repository.save(loan);
    for (final (id, day) in [('p1', 1), ('p2', 20)]) {
      await repository.saveExtraPayment(
        ExtraPayment(
          id: id,
          debtId: 'd1',
          amount: const Money.pesos(500000),
          date: DateTime(2026, 9, day),
        ),
      );
    }

    final payments = await repository.getExtraPayments('d1');

    expect(payments.map((p) => p.id), ['p2', 'p1']);
  });

  test('borrar la deuda elimina abonos y desvincula pagos', () async {
    final transactions = DriftTransactionRepository(db);
    await repository.save(loan);
    await repository.saveExtraPayment(
      ExtraPayment(
        id: 'p1',
        debtId: 'd1',
        amount: const Money.pesos(500000),
        date: DateTime(2026, 9),
      ),
    );
    await transactions.save(
      Transaction(
        id: 't1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(1300000),
        categoryId: DefaultCategories.debtsId,
        date: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
        debtId: 'd1',
      ),
    );

    await repository.delete('d1');

    expect(await repository.getById('d1'), isNull);
    expect(await repository.getExtraPayments('d1'), isEmpty);
    expect((await transactions.getById('t1'))!.debtId, isNull);
  });
}
