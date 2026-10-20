import 'package:finance_app/application/common/guard_use_case.dart';
import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/investments/investment_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/usd_rate.dart';
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
    Money monthlyCost = Money.zero,
    Money monthlyIncome = Money.zero,
    Liquidity? liquidity,
    String? linkedDebtId,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (value.isNegative ||
        monthlyCost.isNegative ||
        monthlyIncome.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    final asset = Asset(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      currentValue: value,
      valuedAt: _clock.now(),
      notes: cleanText(notes),
      monthlyCost: monthlyCost,
      monthlyIncome: monthlyIncome,
      liquidity: liquidity,
      linkedDebtId: linkedDebtId,
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

  /// Símbolos como NVDA, VOO, BRK-B, BTC-USD, ECOPETROL.CL o ^GSPC.
  static final symbolPattern = RegExp(r'^[A-Z0-9^][A-Z0-9.\-=^]{0,14}$');

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
    String? symbol,
    int? unitsMicros,
    DateTime? priceUpdatedAt,
    int? investedUsdCents,
    int? currentUsdCents,
    UsdRate? usdRate,
  }) {
    final cleanName = cleanText(name);
    if (cleanName == null) return invalid(ValidationCodes.nameRequired);
    if (invested.isNegative || currentValue.isNegative) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    final inDollars = investedUsdCents != null || currentUsdCents != null;
    if ((investedUsdCents ?? 0) < 0 || (currentUsdCents ?? 0) < 0) {
      return invalid(ValidationCodes.amountMustNotBeNegative);
    }
    if (inDollars && !(usdRate?.isValid ?? false)) {
      return invalid(ValidationCodes.usdRateRequired);
    }
    final cleanSymbol = cleanText(symbol)?.toUpperCase();
    if (cleanSymbol != null && !symbolPattern.hasMatch(cleanSymbol)) {
      return invalid(ValidationCodes.invalidSymbol);
    }
    final units = unitsMicros != null && unitsMicros > 0 ? unitsMicros : null;
    if (cleanSymbol != null && units == null) {
      return invalid(ValidationCodes.unitsRequired);
    }
    final investment = Investment(
      id: id ?? _ids.next(),
      name: cleanName,
      type: type,
      // En dólares, los pesos salen del dólar que confirmó el usuario.
      investedAmount: investedUsdCents == null
          ? invested
          : usdRate!.toPesos(investedUsdCents),
      currentValue: currentUsdCents == null
          ? currentValue
          : usdRate!.toPesos(currentUsdCents),
      date: date ?? _clock.now(),
      notes: cleanText(notes),
      symbol: cleanSymbol,
      unitsMicros: cleanSymbol == null ? null : units,
      priceUpdatedAt: cleanSymbol == null ? null : priceUpdatedAt,
      investedUsdCents: investedUsdCents,
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
