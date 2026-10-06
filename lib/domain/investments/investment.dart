import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

enum InvestmentType { fund, stocks, fixedTerm, crypto, other }

/// Inversión registrada manualmente (sin conexión a brokers).
@immutable
final class Investment {
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.date,
    this.notes,
  });

  final String id;
  final String name;
  final InvestmentType type;
  final Money investedAmount;
  final Money currentValue;
  final DateTime date;
  final String? notes;

  Money get gain => currentValue - investedAmount;

  /// Rentabilidad sobre lo invertido. `null` si no hay monto invertido.
  Percentage? get returnRate => Percentage.ratio(gain, investedAmount);

  @override
  bool operator ==(Object other) =>
      other is Investment &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.investedAmount == investedAmount &&
      other.currentValue == currentValue &&
      other.date == date &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(id, name, type, investedAmount, currentValue, date, notes);
}
