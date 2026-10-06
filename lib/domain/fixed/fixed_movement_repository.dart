import 'package:finance_app/domain/fixed/fixed_movement.dart';

/// Port de movimientos fijos. Listas ordenadas por día del mes.
abstract interface class FixedMovementRepository {
  Future<void> save(FixedMovement movement);

  Future<void> delete(String id);

  Future<List<FixedMovement>> getAll();

  Stream<List<FixedMovement>> watchAll();
}
