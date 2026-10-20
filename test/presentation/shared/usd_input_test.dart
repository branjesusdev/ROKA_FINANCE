import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dólares con punto o coma decimal', () {
    expect(UsdInput.parse('253.70'), 25370);
    expect(UsdInput.parse('253,70'), 25370);
    expect(UsdInput.parse('253,7'), 25370);
    expect(UsdInput.parse('1.253,70'), 125370);
    expect(UsdInput.parse('1,253.70'), 125370);
    expect(UsdInput.parse('1.253'), 125300, reason: '3 cifras = miles');
    expect(UsdInput.parse('253'), 25300);
    expect(UsdInput.parse(''), isNull);
  });
}
