import 'package:finance_app/domain/shared/money.dart';

/// Atajo para crear un apartado común con valores sugeridos (editables).
final class ProvisionTemplate {
  const new({
    required this.name,
    required this.everyMonths,
    required this.categoryId,
    this.amount,
    this.dueMonth,
    this.dueDay = 1,
  });

  final String name;
  final int everyMonths;
  final String categoryId;
  final Money? amount;

  /// Mes habitual del pago (1–12). `null`: dentro de [everyMonths] meses.
  final int? dueMonth;
  final int dueDay;

  /// Próxima fecha sugerida a partir de [today].
  DateTime suggestedDue(DateTime today) {
    final month = dueMonth;
    if (month == null) {
      return DateTime(today.year, today.month + everyMonths, today.day);
    }
    final thisYear = DateTime(today.year, month, dueDay);
    return thisYear.isBefore(DateTime(today.year, today.month, today.day))
        ? DateTime(today.year + 1, month, dueDay)
        : thisYear;
  }

  static const _transport = 'seed-expense-transport';

  static const all = [
    ProvisionTemplate(
      name: 'Gimnasio (trimestral)',
      everyMonths: 3,
      categoryId: 'seed-expense-sports',
      amount: Money.pesos(199000),
    ),
    ProvisionTemplate(
      name: 'SOAT',
      everyMonths: 12,
      categoryId: _transport,
      amount: Money.pesos(447000),
      dueMonth: DateTime.november,
    ),
    ProvisionTemplate(
      name: 'Tecnomecánica',
      everyMonths: 12,
      categoryId: _transport,
      amount: Money.pesos(317000),
      dueMonth: DateTime.november,
    ),
    ProvisionTemplate(
      name: 'Mantenimiento del carro',
      everyMonths: 6,
      categoryId: _transport,
    ),
    ProvisionTemplate(
      name: 'Colegio: matrícula, uniformes y útiles',
      everyMonths: 12,
      categoryId: 'seed-expense-education',
      amount: Money.pesos(1200000),
      dueMonth: DateTime.january,
      dueDay: 15,
    ),
    ProvisionTemplate(
      name: 'Impuesto del carro',
      everyMonths: 12,
      categoryId: _transport,
    ),
  ];
}
