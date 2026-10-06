import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wealth/asset.dart';
import 'package:finance_app/domain/wealth/asset_repository.dart';

/// Crea (sin `id`) o actualiza un activo. La fecha de valoración es hoy.
final class SaveAsset {
  const new({required this._assets, required this._clock, required this._ids});

  final AssetRepository _assets;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Asset>> call({
    required String name,
    required AssetType type,
    required Money value,
    String? id,
    String? notes,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (value.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    final asset = Asset(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      currentValue: value,
      valuedAt: _clock.now(),
      notes: cleanText(notes),
    );
    return guardUseCase(() async {
      await _assets.save(asset);
      return asset;
    });
  }
}

final class DeleteAsset {
  const new(this._assets);

  final AssetRepository _assets;

  Future<Result<void>> call(String id) =>
      guardUseCase(() => _assets.delete(id));
}

/// Crea (sin `id`) o actualiza una inversión registrada manualmente.
final class SaveInvestment {
  const new({
    required this._investments,
    required this._clock,
    required this._ids,
  });

  final InvestmentRepository _investments;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Investment>> call({
    required String name,
    required InvestmentType type,
    required Money invested,
    required Money currentValue,
    String? id,
    DateTime? date,
    String? notes,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (invested.isNegative || currentValue.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    final investment = Investment(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      investedAmount: invested,
      currentValue: currentValue,
      date: date ?? _clock.now(),
      notes: cleanText(notes),
    );
    return guardUseCase(() async {
      await _investments.save(investment);
      return investment;
    });
  }
}

final class DeleteInvestment {
  const new(this._investments);

  final InvestmentRepository _investments;

  Future<Result<void>> call(String id) =>
      guardUseCase(() => _investments.delete(id));
}
