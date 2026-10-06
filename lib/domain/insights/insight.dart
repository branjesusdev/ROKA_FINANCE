import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/shared/traffic_light.dart';

/// Observación descriptiva basada en los datos del usuario. La UI la
/// redacta; nunca se presenta como asesoría financiera.
sealed class Insight {
  const new();
}

/// "Alimentación representa el 24% de tus gastos."
final class CategoryShareInsight extends Insight {
  const new({
    required this.categoryId,
    required this.amount,
    required this.share,
  });

  final String categoryId;
  final Money amount;
  final Percentage share;
}

/// "Entretenimiento aumentó 35% respecto al mes anterior."
final class CategoryVariationInsight extends Insight {
  const new({
    required this.categoryId,
    required this.current,
    required this.previous,
    required this.change,
  });

  final String categoryId;
  final Money current;
  final Money previous;

  /// Positivo = aumento, negativo = disminución.
  final Percentage change;
}

/// Variación del gasto total frente al mes anterior.
final class TotalSpendingVariationInsight extends Insight {
  const new({
    required this.current,
    required this.previous,
    required this.change,
  });

  final Money current;
  final Money previous;
  final Percentage change;
}

/// "Has realizado 18 compras pequeñas que suman $420.000."
final class SmallExpensesInsight extends Insight {
  const new({
    required this.count,
    required this.total,
    required this.threshold,
  });

  final int count;
  final Money total;
  final Money threshold;
}

/// "Estás utilizando el 92% de tu presupuesto."
final class BudgetUsageInsight extends Insight {
  const new({required this.usage, required this.light});

  final Percentage usage;
  final TrafficLight light;
}
