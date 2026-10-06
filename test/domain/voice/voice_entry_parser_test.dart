import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/voice/spoken_amount_parser.dart';
import 'package:finance_app/domain/voice/voice_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpokenAmountParser', () {
    int? pesos(String text) => const SpokenAmountParser()
        .parse(text.split(' ').map(VoiceEntryParser.normalize).toList())
        ?.pesos;

    test('lee cifras con y sin separadores', () {
      expect(pesos('25000'), 25000);
      expect(pesos('25.000'), 25000);
      expect(pesos(r'$25,000'), 25000);
      expect(pesos('1.200.000'), 1200000);
      expect(pesos('15k'), 15000);
    });

    test('lee "mil", "millones" y "lucas"', () {
      expect(pesos('25 mil'), 25000);
      expect(pesos('30 lucas'), 30000);
      expect(pesos('1,5 millones'), 1500000);
      expect(pesos('2 millones 300 mil'), 2300000);
      expect(pesos('mil pesos'), 1000);
    });

    test('lee números en palabras', () {
      expect(pesos('veinticinco mil'), 25000);
      expect(pesos('treinta y cinco mil quinientos'), 35500);
      expect(pesos('dos millones trescientos mil'), 2300000);
      expect(pesos('un millón'), 1000000);
    });

    test('con varios números toma el mayor', () {
      expect(pesos('20 mil en 2 almuerzos'), 20000);
      expect(pesos('un almuerzo de 18 mil'), 18000);
    });

    test('sin número devuelve null', () {
      expect(pesos('almuerzo con Juan'), isNull);
    });
  });

  group('VoiceEntryParser', () {
    VoiceEntry parse(String text) =>
        const VoiceEntryParser().parse(text, categories: DefaultCategories.all);

    test('gasto con categoría y descripción', () {
      final entry = parse('Gasté 25 mil en almuerzo con Juan');
      expect(entry.kind, TransactionKind.expense);
      expect(entry.pesos, 25000);
      expect(entry.categoryId, 'seed-expense-food');
      expect(entry.description, 'Almuerzo con Juan');
      expect(entry.daysAgo, 0);
    });

    test('ingreso de sueldo', () {
      final entry = parse('me pagaron el sueldo 4 millones');
      expect(entry.kind, TransactionKind.income);
      expect(entry.pesos, 4000000);
      expect(entry.categoryId, 'seed-income-salary');
    });

    test('prefiere la palabra clave más específica', () {
      expect(
        parse('pagué la cuota alimentaria 800 mil').categoryId,
        'seed-expense-family',
      );
      expect(
        parse('pagué la cuota del crédito').categoryId,
        'seed-expense-debts',
      );
      expect(parse('pagué entrenos 120 mil').categoryId, 'seed-expense-sports');
      expect(parse('arriendo 1.200.000').categoryId, 'seed-expense-housing');
    });

    test('entiende "ayer" y "antier"', () {
      expect(parse('ayer 30 lucas de taxi').daysAgo, 1);
      expect(parse('antier 10 mil de pan').daysAgo, 2);
      expect(
        parse('ayer 30 lucas de taxi').categoryId,
        'seed-expense-transport',
      );
    });

    test('sin categoría reconocible la deja vacía', () {
      final entry = parse('50 mil');
      expect(entry.categoryId, isNull);
      expect(entry.description, isNull);
    });
  });
}
