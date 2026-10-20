import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:meta/meta.dart';

/// Movimiento que se repite cada mes el mismo día: arriendo, colegio, cuota
/// alimentaria, crédito, entrenos… o el sueldo.
///
/// Los ingresos y los gastos con débito automático se registran solos
/// cuando llega su día; los demás gastos esperan a que confirmes el pago.
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
    this.isVariable = false,
    this.autoDebit = false,
    this.lastPostedOn,
    this.debtId,
    this.remindOn,
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

  /// Valor que cambia cada mes (agua, luz, internet…): no se registra solo;
  /// su día pide el valor real. [amount] es el estimado.
  final bool isVariable;

  /// Gasto que el banco descuenta solo (débito automático): se registra
  /// como pagado el día que vence, sin preguntar.
  final bool autoDebit;

  /// Fecha de la última vez que se registró. Evita duplicados aunque el
  /// usuario borre el movimiento generado.
  final DateTime? lastPostedOn;

  /// Crédito que paga esta cuota fija: al registrarse baja su saldo y
  /// suma una cuota pagada.
  final String? debtId;

  /// "Recuérdame mañana / en 2 días": hasta este día (a medianoche) la
  /// factura sin confirmar no avisa ni se muestra como vencida.
  final DateTime? remindOn;

  bool get isExpense => kind == TransactionKind.expense;

  /// Al llegar su día no se registra solo: espera "Ya lo pagué" (o el valor
  /// real si es variable). Registrado no es pagado.
  bool get needsConfirmation => isVariable || (isExpense && !autoDebit);

  /// Pospuesto: [today] es antes del día en que vuelve a preguntar.
  bool isSnoozedOn(DateTime today) {
    final until = remindOn;
    return until != null &&
        DateTime(today.year, today.month, today.day).isBefore(until);
  }

  FixedMovement copyWith({
    String? name,
    Money? amount,
    String? categoryId,
    int? dayOfMonth,
    bool? isActive,
    bool? isVariable,
    bool? autoDebit,
    DateTime? lastPostedOn,
  }) => FixedMovement(
    id: id,
    name: name ?? this.name,
    kind: kind,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    isActive: isActive ?? this.isActive,
    isVariable: isVariable ?? this.isVariable,
    autoDebit: autoDebit ?? this.autoDebit,
    lastPostedOn: lastPostedOn ?? this.lastPostedOn,
    debtId: debtId,
    remindOn: remindOn,
  );

  /// Enlaza (o desenlaza con `null`) el crédito que paga.
  FixedMovement linkedTo(String? debtId) =>
      _with(debtId: debtId, remindOn: remindOn);

  /// Pospone el aviso hasta [day] (`null` = deja de estar pospuesto).
  FixedMovement remindedOn(DateTime? day) => _with(
    debtId: debtId,
    remindOn: day == null ? null : DateTime(day.year, day.month, day.day),
  );

  FixedMovement _with({required String? debtId, required DateTime? remindOn}) =>
      FixedMovement(
        id: id,
        name: name,
        kind: kind,
        amount: amount,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        isActive: isActive,
        isVariable: isVariable,
        autoDebit: autoDebit,
        lastPostedOn: lastPostedOn,
        debtId: debtId,
        remindOn: remindOn,
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
      other.isVariable == isVariable &&
      other.autoDebit == autoDebit &&
      other.lastPostedOn == lastPostedOn &&
      other.debtId == debtId &&
      other.remindOn == remindOn;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    amount,
    categoryId,
    dayOfMonth,
    isActive,
    isVariable,
    autoDebit,
    lastPostedOn,
    debtId,
    remindOn,
  );
}
