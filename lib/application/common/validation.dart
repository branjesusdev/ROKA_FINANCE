import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';

/// Códigos de validación. La UI los traduce; no contienen datos.
abstract final class ValidationCodes {
  static const nameRequired = 'name_required';
  static const amountMustBePositive = 'amount_must_be_positive';
  static const amountMustNotBeNegative = 'amount_must_not_be_negative';
  static const amountMustNotBeZero = 'amount_must_not_be_zero';
  static const rateOutOfRange = 'rate_out_of_range';
  static const monthsMustBePositive = 'months_must_be_positive';
  static const dayOutOfRange = 'day_out_of_range';
  static const hourOutOfRange = 'hour_out_of_range';
  static const monthsOutOfRange = 'months_out_of_range';
  static const notFound = 'not_found';
}

Future<Result<T>> invalid<T>(String code) =>
    Future.value(Err(ValidationFailure(code)));

/// Texto opcional: recorta espacios y convierte vacío en `null`.
String? cleanText(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
