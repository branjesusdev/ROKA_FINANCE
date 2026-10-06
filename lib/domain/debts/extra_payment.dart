import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Abono extraordinario: va 100% a capital.
@immutable
final class ExtraPayment {
  const new({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
  });

  final String id;
  final String debtId;
  final Money amount;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is ExtraPayment &&
      other.id == id &&
      other.debtId == debtId &&
      other.amount == amount &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, debtId, amount, date);
}
