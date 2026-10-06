import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:uuid/uuid.dart';

final class UuidIdGenerator implements IdGenerator {
  const new();

  static const _uuid = Uuid();

  @override
  String next() => _uuid.v4();
}
