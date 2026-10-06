import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:flutter/material.dart';

/// Textos e iconos en español para los enums del dominio.
abstract final class Labels {
  static String asset(AssetType type) => switch (type) {
    AssetType.cash => 'Efectivo',
    AssetType.bankAccount => 'Cuenta bancaria',
    AssetType.vehicle => 'Vehículo',
    AssetType.property => 'Propiedad',
    AssetType.other => 'Otro',
  };

  static IconData assetIcon(AssetType type) => switch (type) {
    AssetType.cash => Icons.payments_outlined,
    AssetType.bankAccount => Icons.account_balance_outlined,
    AssetType.vehicle => Icons.directions_car_outlined,
    AssetType.property => Icons.house_outlined,
    AssetType.other => Icons.category_outlined,
  };

  static String investment(InvestmentType type) => switch (type) {
    InvestmentType.fund => 'Fondo',
    InvestmentType.stocks => 'Acciones',
    InvestmentType.fixedTerm => 'CDT',
    InvestmentType.crypto => 'Cripto',
    InvestmentType.other => 'Otra',
  };

  static String debt(DebtType type) => switch (type) {
    DebtType.bankLoan => 'Crédito bancario',
    DebtType.creditCard => 'Tarjeta de crédito',
    DebtType.personalLoan => 'Préstamo',
    DebtType.other => 'Otra obligación',
  };

  static IconData debtIcon(DebtType type) => switch (type) {
    DebtType.bankLoan => Icons.account_balance,
    DebtType.creditCard => Icons.credit_card,
    DebtType.personalLoan => Icons.handshake_outlined,
    DebtType.other => Icons.receipt_long_outlined,
  };

  static String rateType(InterestRateType type) => switch (type) {
    InterestRateType.effectiveAnnual => 'EA',
    InterestRateType.nominalAnnualMonthly => 'NMV',
    InterestRateType.effectiveMonthly => 'EM',
  };

  static String rateTypeLong(InterestRateType type) => switch (type) {
    InterestRateType.effectiveAnnual => 'Efectiva anual (EA)',
    InterestRateType.nominalAnnualMonthly => 'Nominal mes vencido (NMV)',
    InterestRateType.effectiveMonthly => 'Efectiva mensual (EM)',
  };

  static String goal(GoalType type) => switch (type) {
    GoalType.emergency => 'Fondo de emergencia',
    GoalType.travel => 'Viaje',
    GoalType.vehicle => 'Vehículo',
    GoalType.housing => 'Vivienda',
    GoalType.investment => 'Inversión',
    GoalType.custom => 'Personalizada',
  };

  static IconData goalIcon(GoalType type) => switch (type) {
    GoalType.emergency => Icons.health_and_safety_outlined,
    GoalType.travel => Icons.flight_takeoff,
    GoalType.vehicle => Icons.directions_car_outlined,
    GoalType.housing => Icons.house_outlined,
    GoalType.investment => Icons.trending_up,
    GoalType.custom => Icons.flag_outlined,
  };
}
