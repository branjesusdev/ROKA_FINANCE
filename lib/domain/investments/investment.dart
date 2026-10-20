import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:meta/meta.dart';

enum InvestmentType { fund, stocks, fixedTerm, crypto, other }

/// Inversión registrada manualmente (sin conexión a brokers).
///
/// Con [symbol] y [unitsMicros] su valor se puede actualizar con el precio
/// público de mercado (acciones, ETF, cripto).
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
    this.symbol,
    this.unitsMicros,
    this.priceUpdatedAt,
    this.investedUsdCents,
  });

  /// Millonésimas por unidad: permite acciones fraccionadas.
  static const microsPerUnit = 1000000;

  final String id;
  final String name;
  final InvestmentType type;
  final Money investedAmount;
  final Money currentValue;
  final DateTime date;
  final String? notes;

  /// Símbolo de bolsa en mayúsculas (NVDA, VOO, BTC-USD…).
  final String? symbol;

  /// Cantidad de acciones o unidades, en millonésimas.
  final int? unitsMicros;

  /// Cuándo se tomó [currentValue] del precio de mercado (`null` = valor
  /// escrito a mano).
  final DateTime? priceUpdatedAt;

  /// Si lo pagaste en dólares, cuánto (en centavos de dólar). En ese caso
  /// [investedAmount] es su equivalente en pesos con el dólar de ese día.
  final int? investedUsdCents;

  Money get gain => currentValue - investedAmount;

  /// Rentabilidad sobre lo invertido. `null` si no hay monto invertido.
  Percentage? get returnRate => Percentage.ratio(gain, investedAmount);

  /// Cantidad de unidades (solo para mostrar y valorar).
  double? get units =>
      unitsMicros == null ? null : unitsMicros! / microsPerUnit;

  /// Se puede valorar con el precio de mercado.
  bool get isMarketPriced =>
      symbol != null && unitsMicros != null && unitsMicros! > 0;

  Investment copyWith({Money? currentValue, DateTime? priceUpdatedAt}) =>
      Investment(
        id: id,
        name: name,
        type: type,
        investedAmount: investedAmount,
        currentValue: currentValue ?? this.currentValue,
        date: date,
        notes: notes,
        symbol: symbol,
        unitsMicros: unitsMicros,
        priceUpdatedAt: priceUpdatedAt ?? this.priceUpdatedAt,
        investedUsdCents: investedUsdCents,
      );

  @override
  bool operator ==(Object other) =>
      other is Investment &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.investedAmount == investedAmount &&
      other.currentValue == currentValue &&
      other.date == date &&
      other.notes == notes &&
      other.symbol == symbol &&
      other.unitsMicros == unitsMicros &&
      other.priceUpdatedAt == priceUpdatedAt &&
      other.investedUsdCents == investedUsdCents;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    investedAmount,
    currentValue,
    date,
    notes,
    symbol,
    unitsMicros,
    priceUpdatedAt,
    investedUsdCents,
  );
}
