import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buscar iconos sin tildes ni mayúsculas', () {
    expect(CategoryStyle.search('Gasolina'), contains('fuel'));
    expect(CategoryStyle.search('café'), contains('coffee'));
    expect(CategoryStyle.search(''), CategoryStyle.choosableKeys);
    expect(CategoryStyle.search('xyzzy'), isEmpty);
  });

  test('los reservados no se ofrecen', () {
    expect(CategoryStyle.search('deudas'), isNot(contains('debts')));
  });

  test('sugiere icono por el nombre de la categoría', () {
    expect(CategoryStyle.suggest('Gasolina moto'), 'fuel');
    expect(CategoryStyle.suggest('Mascotas'), 'pets');
    expect(CategoryStyle.suggest('Gastos varios'), isNot('gas'));
  });
}
