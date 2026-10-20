import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:meta/meta.dart';

/// Cuánto te cuesta andar en tu vehículo según las tanqueadas con
/// kilometraje.
@immutable
final class FuelEconomy {
  const new({
    required this.fills,
    required this.kmDriven,
    required this.spent,
    required this.lastOdometerKm,
    this.lastSegmentKm,
    this.lastSegmentCost,
  });

  /// Tanqueadas con kilometraje válido.
  final int fills;

  /// Kilómetros entre la primera y la última tanqueada.
  final int kmDriven;

  /// Gasolina que se gastó en esos kilómetros (todas menos la primera).
  final Money spent;
  final int lastOdometerKm;

  /// Último tramo: de la penúltima a la última tanqueada.
  final int? lastSegmentKm;
  final Money? lastSegmentCost;

  bool get hasData => kmDriven > 0;

  /// Pesos por kilómetro en todo el historial.
  Money? get costPerKm => hasData ? spent.divide(kmDriven) : null;

  /// Pesos por cada 100 km (más fácil de comparar).
  Money? get costPer100Km =>
      hasData ? spent.times(kmPer100).divide(kmDriven) : null;

  /// Pesos por kilómetro en el último tramo.
  Money? get lastCostPerKm => switch ((lastSegmentKm, lastSegmentCost)) {
    (final km?, final cost?) when km > 0 => cost.divide(km),
    _ => null,
  };

  /// Kilómetros promedio entre tanqueadas.
  int? get kmPerFill => fills > 1 ? kmDriven ~/ (fills - 1) : null;

  /// El último tramo frente al promedio (positivo = te salió más caro).
  Percentage? get lastVsAverage {
    final last = lastCostPerKm;
    final average = costPerKm;
    if (last == null || average == null || !average.isPositive) return null;
    return Percentage.ratio(last - average, average);
  }

  static const kmPer100 = 100;
}

/// Calcula [FuelEconomy] con el método de tanque lleno: lo que pagas en
/// una tanqueada repone lo que gastaste desde la anterior. Ignora
/// kilometrajes que no avanzan (errores de digitación).
final class FuelEconomyCalculator {
  const new();

  /// Palabras que indican una categoría de vehículo.
  static const _keywords = [
    'gasolin',
    'combustib',
    'transport',
    'carro',
    'moto',
    'vehic',
    'vehíc',
  ];

  static const transportId = 'seed-expense-transport';

  /// La categoría admite kilometraje (Transporte o una de vehículo).
  static bool appliesTo(Category? category) {
    if (category == null || category.kind != CategoryKind.expense) {
      return false;
    }
    if (category.id == transportId) return true;
    final name = category.name.toLowerCase();
    return _keywords.any(name.contains);
  }

  /// `null` si no hay ninguna tanqueada con kilometraje.
  FuelEconomy? compute(Iterable<Transaction> transactions) {
    final withKm =
        transactions
            .where((t) => t.isExpense && (t.odometerKm ?? 0) > 0)
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
          });
    final fills = <Transaction>[];
    for (final t in withKm) {
      if (fills.isEmpty || t.odometerKm! > fills.last.odometerKm!) {
        fills.add(t);
      }
    }
    if (fills.isEmpty) return null;
    final first = fills.first.odometerKm!;
    final last = fills.last.odometerKm!;
    final previous = fills.length > 1 ? fills[fills.length - 2] : null;
    return FuelEconomy(
      fills: fills.length,
      kmDriven: last - first,
      spent: Money.sum(fills.skip(1).map((t) => t.amount)),
      lastOdometerKm: last,
      lastSegmentKm: previous == null ? null : last - previous.odometerKm!,
      lastSegmentCost: previous == null ? null : fills.last.amount,
    );
  }
}
