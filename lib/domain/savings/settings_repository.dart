import 'package:finance_app/domain/savings/finance_settings.dart';

abstract interface class SettingsRepository {
  /// Devuelve los valores por defecto si nunca se guardaron.
  Future<FinanceSettings> get();

  Future<void> save(FinanceSettings settings);

  Stream<FinanceSettings> watch();
}
