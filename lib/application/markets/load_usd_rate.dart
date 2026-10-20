import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/usd_rate.dart';

/// Precio del dólar en pesos hoy (Yahoo, `COP=X`). Solo envía ese símbolo.
/// `null` si no hay internet: el usuario lo escribe a mano.
final class LoadUsdRate {
  const new(this._market);

  static const symbol = 'COP=X';

  final MarketDataSource _market;

  Future<UsdRate?> call() async {
    try {
      final quote = await _market.fetch(symbol);
      if (quote.lastPriceMinor <= 0) return null;
      // El precio llega en centésimas de peso: ya son centavos.
      return UsdRate(Money(quote.lastPriceMinor));
    } on MarketDataException {
      return null;
    }
  }
}
