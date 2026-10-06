import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';

int _sequence = 0;

final defaultDate = DateTime(2026, 10, 5);

Transaction expense(
  int pesos, {
  String category = 'food',
  DateTime? date,
  ExpenseNature? nature,
}) => Transaction(
  id: 'tx-${_sequence++}',
  kind: TransactionKind.expense,
  amount: Money.pesos(pesos),
  categoryId: category,
  date: date ?? defaultDate,
  createdAt: date ?? defaultDate,
  nature: nature,
);

Transaction income(int pesos, {String category = 'salary', DateTime? date}) =>
    Transaction(
      id: 'tx-${_sequence++}',
      kind: TransactionKind.income,
      amount: Money.pesos(pesos),
      categoryId: category,
      date: date ?? defaultDate,
      createdAt: date ?? defaultDate,
    );
