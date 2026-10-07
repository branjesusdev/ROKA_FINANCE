import 'package:finance_app/domain/provisions/provision.dart';

/// Port de apartados. Listas ordenadas por próxima fecha de pago.
abstract interface class ProvisionRepository {
  Future<void> save(Provision provision);

  /// Elimina el apartado. Sus movimientos quedan, sin vínculo.
  Future<void> delete(String id);

  Future<Provision?> getById(String id);

  Future<List<Provision>> getAll();

  Stream<List<Provision>> watchAll();
}
