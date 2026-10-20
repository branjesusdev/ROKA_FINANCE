import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

enum TransactionKind { income, expense }

/// Naturaleza del gasto. Los esenciales alimentan el fondo de emergencia.
enum ExpenseNature { essential, discretionary }

/// Ingreso o gasto. `amount` siempre es positivo; `kind` define el signo.
@immutable
final class Transaction {
  const new({
    required this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.description,
    this.accountId,
    this.nature,
    this.notes,
    this.debtId,
    this.provisionId,
    this.fixedMovementId,
    this.odometerKm,
  });

  final String id;
  final TransactionKind kind;
  final Money amount;
  final String categoryId;
  final DateTime date;
  final DateTime createdAt;
  final String? description;
  final String? accountId;
  final ExpenseNature? nature;
  final String? notes;

  /// Si es el pago de una deuda, su id.
  final String? debtId;

  /// Si es un aporte a un apartado o su uso al pagar, su id.
  final String? provisionId;

  /// Si lo generó un movimiento fijo (arriendo, sueldo…), su id.
  final String? fixedMovementId;

  /// Kilometraje del vehículo al tanquear (opcional, solo gasolina).
  final int? odometerKm;

  /// Vinculado a otro módulo (fijo, deuda o apartado): borrarlo cambia
  /// saldos o el ciclo que dependen de él.
  bool get isLinked =>
      fixedMovementId != null || debtId != null || provisionId != null;

  bool get isIncome => kind == TransactionKind.income;
  bool get isExpense => kind == TransactionKind.expense;

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.kind == kind &&
      other.amount == amount &&
      other.categoryId == categoryId &&
      other.date == date &&
      other.createdAt == createdAt &&
      other.description == description &&
      other.accountId == accountId &&
      other.nature == nature &&
      other.notes == notes &&
      other.debtId == debtId &&
      other.provisionId == provisionId &&
      other.fixedMovementId == fixedMovementId &&
      other.odometerKm == odometerKm;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    amount,
    categoryId,
    date,
    createdAt,
    description,
    accountId,
    nature,
    notes,
    debtId,
    provisionId,
    fixedMovementId,
    odometerKm,
  );
}
