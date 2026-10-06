import 'package:finance_app/domain/shared/clock.dart';

final class SystemClock implements Clock {
  const new();

  @override
  DateTime now() => DateTime.now();
}
