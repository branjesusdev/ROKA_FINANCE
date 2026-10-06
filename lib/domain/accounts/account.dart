import 'package:meta/meta.dart';

enum AccountType { cash, bank, card, other }

/// Origen del dinero de un movimiento. En v1 es solo una etiqueta: su saldo
/// no se calcula (ver docs/domain-model.md).
@immutable
final class Account {
  const new({required this.id, required this.name, required this.type});

  static const defaultCash = Account(
    id: 'seed-account-cash',
    name: 'Efectivo',
    type: AccountType.cash,
  );

  final String id;
  final String name;
  final AccountType type;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.id == id &&
      other.name == name &&
      other.type == type;

  @override
  int get hashCode => Object.hash(id, name, type);
}
