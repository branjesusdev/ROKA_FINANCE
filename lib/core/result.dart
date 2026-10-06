import 'package:finance_app/core/failure.dart';

/// Resultado explícito de una operación que puede fallar de forma esperada.
sealed class Result<T> {
  const new();

  bool get isOk => this is Ok<T>;

  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final failure) => onErr(failure),
  };
}

final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const new(this.failure);

  final Failure failure;
}
