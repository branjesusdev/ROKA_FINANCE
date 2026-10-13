import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/year_month.dart';
import 'package:meta/meta.dart';

/// Foto del patrimonio de un mes (para ver su evolución).
@immutable
final class NetWorthSnapshot {
  const new({
    required this.id,
    required this.month,
    required this.assets,
    required this.investments,
    required this.liabilities,
    required this.takenAt,
  });

  final String id;
  final YearMonth month;
  final Money assets;
  final Money investments;
  final Money liabilities;
  final DateTime takenAt;

  Money get total => assets + investments - liabilities;

  @override
  bool operator ==(Object other) =>
      other is NetWorthSnapshot &&
      other.id == id &&
      other.month == month &&
      other.assets == assets &&
      other.investments == investments &&
      other.liabilities == liabilities &&
      other.takenAt == takenAt;

  @override
  int get hashCode =>
      Object.hash(id, month, assets, investments, liabilities, takenAt);
}

/// Port del historial de patrimonio (una foto por mes).
abstract interface class NetWorthHistoryRepository {
  /// Reemplaza la foto del mismo mes si ya existe.
  Future<void> save(NetWorthSnapshot snapshot);

  /// Del mes más antiguo al más reciente.
  Stream<List<NetWorthSnapshot>> watchAll();
}
