import 'package:finance_app/domain/shared/money.dart';
import 'package:meta/meta.dart';

/// Las inversiones tienen su propio agregado (`Investment`).
enum AssetType { cash, bankAccount, vehicle, property, other }

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
  });

  final String id;
  final String name;
  final AssetType type;
  final Money currentValue;
  final DateTime valuedAt;
  final String? notes;

  @override
  bool operator ==(Object other) =>
      other is Asset &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.currentValue == currentValue &&
      other.valuedAt == valuedAt &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(id, name, type, currentValue, valuedAt, notes);
}
