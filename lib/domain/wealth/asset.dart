import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Las inversiones tienen su propio agregado (`Investment`).
enum AssetType { cash, bankAccount, vehicle, property, business, other }

/// Qué tan rápido se convierte en dinero sin perder valor.
enum Liquidity {
  /// Hoy mismo (efectivo, cuenta de ahorros).
  high,

  /// Semanas (CDT por vencer, participación vendible).
  medium,

  /// Meses (casa, carro, negocio).
  low,
}

/// Bien con valor registrado manualmente (valoración).
@immutable
final class Asset {
  const new({
    required this.id,
    required this.name,
    required this.type,
    required this.currentValue,
    required this.valuedAt,
    this.notes,
    this.monthlyCost = Money.zero,
    this.monthlyIncome = Money.zero,
    this.liquidity,
    this.linkedDebtId,
  });

  final String id;
  final String name;
  final AssetType type;
  final Money currentValue;
  final DateTime valuedAt;
  final String? notes;

  /// Lo que cuesta tenerlo al mes (seguro, impuestos, mantenimiento,
  /// administración…).
  final Money monthlyCost;

  /// Lo que produce al mes (arriendo, utilidades…).
  final Money monthlyIncome;

  /// `null` = la que corresponde a su tipo ([effectiveLiquidity]).
  final Liquidity? liquidity;

  /// Crédito con el que se financió (el saldo ya cuenta como pasivo: no se
  /// resta del valor del bien para no contarlo dos veces).
  final String? linkedDebtId;

  Liquidity get effectiveLiquidity =>
      liquidity ??
      switch (type) {
        AssetType.cash || AssetType.bankAccount => Liquidity.high,
        AssetType.other => Liquidity.medium,
        AssetType.vehicle ||
        AssetType.property ||
        AssetType.business => Liquidity.low,
      };

  /// Ingreso − costo mensual. Negativo = el bien te cuesta.
  Money get monthlyNet => monthlyIncome - monthlyCost;

  @override
  bool operator ==(Object other) =>
      other is Asset &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.currentValue == currentValue &&
      other.valuedAt == valuedAt &&
      other.notes == notes &&
      other.monthlyCost == monthlyCost &&
      other.monthlyIncome == monthlyIncome &&
      other.liquidity == liquidity &&
      other.linkedDebtId == linkedDebtId;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    currentValue,
    valuedAt,
    notes,
    monthlyCost,
    monthlyIncome,
    liquidity,
    linkedDebtId,
  );
}
