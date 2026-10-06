import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:meta/meta.dart';

/// Movimiento que se repite cada mes el mismo día: arriendo, colegio, cuota
/// alimentaria, crédito, entrenos… o el sueldo.
///
/// Se registra solo como movimiento cuando llega su día dentro del ciclo.
@immutable
final class FixedMovement {
  const new({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.dayOfMonth,
    this.isActive = true,
    this.lastPostedOn,
  });

  static const minDay = 1;
  static const maxDay = 31;

  final String id;
  final String name;
  final TransactionKind kind;
  final Money amount;
  final String categoryId;

  /// Día del mes en que se paga o se recibe (1–31).
  final int dayOfMonth;

  /// Pausado = no se registra hasta reactivarlo.
  final bool isActive;

  /// Fecha de la última vez que se registró. Evita duplicados aunque el
  /// usuario borre el movimiento generado.
  final DateTime? lastPostedOn;

  bool get isExpense => kind == TransactionKind.expense;

  FixedMovement copyWith({
    String? name,
    Money? amount,
    String? categoryId,
    int? dayOfMonth,
    bool? isActive,
    DateTime? lastPostedOn,
  }) => FixedMovement(
    id: id,
    name: name ?? this.name,
    kind: kind,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    isActive: isActive ?? this.isActive,
    lastPostedOn: lastPostedOn ?? this.lastPostedOn,
  );

  @override
  bool operator ==(Object other) =>
      other is FixedMovement &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.amount == amount &&
      other.categoryId == categoryId &&
      other.dayOfMonth == dayOfMonth &&
      other.isActive == isActive &&
      other.lastPostedOn == lastPostedOn;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    amount,
    categoryId,
    dayOfMonth,
    isActive,
    lastPostedOn,
  );
}
