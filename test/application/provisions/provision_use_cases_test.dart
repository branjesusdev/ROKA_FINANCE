import 'package:finance_app/application/provisions/provision_use_cases.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/insights/cash_flow_calculator.dart';
import 'package:finance_app/domain/provisions/provision.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/repositories/drift_provision_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  const transport = 'seed-expense-transport';

  late DriftProvisionRepository provisions;
  late DriftTransactionRepository transactions;
  late SaveProvision save;
  late SetAsideForProvision setAside;
  late PayProvision pay;

  setUp(() {
    final db = createTestDatabase();
    provisions = DriftProvisionRepository(db);
    transactions = DriftTransactionRepository(db);
    final clock = FixedClock(DateTime(2026, 10, 6, 12));
    final ids = SequentialIds();
    save = SaveProvision(provisions: provisions, ids: ids);
    setAside = SetAsideForProvision(
      transactions: transactions,
      clock: clock,
      ids: ids,
    );
    pay = PayProvision(
      provisions: provisions,
      transactions: transactions,
      clock: clock,
      ids: ids,
    );
  });

  Future<Provision> soat() async {
    final result = await save(
      name: ' SOAT ',
      amount: const Money.pesos(447000),
      everyMonths: 12,
      nextDue: DateTime(2026, 11, 1, 15),
      categoryId: transport,
    );
    return (result as Ok<Provision>).value;
  }

  /// Efecto en lo que queda del ciclo.
  Money wallet(List<Transaction> list) {
    final flow = const CashFlowCalculator().calculate(
      list,
      savingCategoryIds: {DefaultCategories.provisions.id},
    );
    return flow.adjustments +
        flow.income -
        flow.expenses -
        flow.savingContributions;
  }

  test('guarda limpio y sin hora', () async {
    final provision = await soat();

    expect(provision.name, 'SOAT');
    expect(provision.nextDue, DateTime(2026, 11));
    expect(await provisions.getAll(), [provision]);
  });

  test('valida los meses', () async {
    final result = await save(
      name: 'Gym',
      amount: const Money.pesos(199000),
      everyMonths: 1,
      nextDue: DateTime(2026, 12),
      categoryId: transport,
    );

    expect(
      (result as Err).failure,
      isA<ValidationFailure>().having(
        (f) => f.message,
        'code',
        'months_out_of_range',
      ),
    );
  });

  test('apartar sale de la billetera como ahorro y queda vinculado', () async {
    final provision = await soat();
    await setAside(provision: provision, amount: const Money.pesos(200000));

    final linked = await transactions.getLinkedToProvision(provision.id);
    expect(linked.single.categoryId, DefaultCategories.provisions.id);
    expect(linked.single.isExpense, isTrue);
    expect(wallet(linked), const Money.pesos(-200000));
  });

  test('pagar usa lo apartado y pasa la fecha al año siguiente', () async {
    final provision = await soat();
    await setAside(provision: provision, amount: const Money.pesos(400000));

    final result = await pay(provision: provision);

    expect((result as Ok<Provision>).value.nextDue, DateTime(2027, 11));
    final linked = await transactions.getLinkedToProvision(provision.id);
    final payment = linked.where((t) => t.categoryId == transport);
    expect(payment.single.amount, const Money.pesos(447000));
    // −400.000 al apartar, +400.000 al usarlo, −447.000 del pago: en el
    // ciclo del pago solo salen los 47.000 que faltaban.
    final paymentDay = linked.where(
      (t) => t.categoryId != DefaultCategories.provisions.id,
    );
    expect(wallet(paymentDay.toList()), const Money.pesos(-47000));
  });

  test('borrar el apartado conserva los movimientos sin vínculo', () async {
    final provision = await soat();
    await setAside(provision: provision, amount: const Money.pesos(1000));

    await DeleteProvision(provisions)(provision.id);

    expect(await provisions.getAll(), isEmpty);
    expect(await transactions.getLinkedToProvision(provision.id), isEmpty);
    expect(await transactions.getRecent(limit: 5), hasLength(1));
  });
}
