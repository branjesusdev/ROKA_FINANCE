import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Pago que no llega cada mes pero sí se repite: gimnasio trimestral, SOAT,
/// tecnomecánica, mantenimiento del carro, matrícula y útiles del colegio…
///
/// Para que no tome por sorpresa, se aparta un poco en cada ciclo de sueldo
/// hasta [nextDue]. Lo apartado son movimientos con `provisionId`.
@immutable
final class Provision {
  const new({
    required this.id,
    required this.name,
    required this.amount,
    required this.everyMonths,
    required this.nextDue,
    required this.categoryId,
    this.isActive = true,
  });

  static const minMonths = 2;
  static const maxMonths = 36;

  final String id;
  final String name;

  /// Lo que cuesta cada vez.
  final Money amount;

  /// Cada cuántos meses se repite (3 = trimestral, 12 = anual).
  final int everyMonths;

  /// Próxima fecha de pago.
  final DateTime nextDue;

  /// Categoría del gasto cuando se paga (Transporte, Educación…).
  final String categoryId;

  /// Pausado = no pide apartar.
  final bool isActive;

  /// Fecha de pago siguiente a [nextDue] (al marcarlo como pagado).
  DateTime get followingDue {
    final month = DateTime(nextDue.year, nextDue.month + everyMonths);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(
      month.year,
      month.month,
      nextDue.day > lastDay ? lastDay : nextDue.day,
    );
  }

  Provision copyWith({
    String? name,
    Money? amount,
    int? everyMonths,
    DateTime? nextDue,
    String? categoryId,
    bool? isActive,
  }) => Provision(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    everyMonths: everyMonths ?? this.everyMonths,
    nextDue: nextDue ?? this.nextDue,
    categoryId: categoryId ?? this.categoryId,
    isActive: isActive ?? this.isActive,
  );

  @override
  bool operator ==(Object other) =>
      other is Provision &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.everyMonths == everyMonths &&
      other.nextDue == nextDue &&
      other.categoryId == categoryId &&
      other.isActive == isActive;

  @override
  int get hashCode =>
      Object.hash(id, name, amount, everyMonths, nextDue, categoryId, isActive);
}
