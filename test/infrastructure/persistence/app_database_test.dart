import 'package:finance_app/core/storage_exception.dart';
import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/infrastructure/repositories/drift_account_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_category_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_settings_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders.dart';
import '../../support/test_database.dart';

void main() {
  test(
    'la primera apertura siembra categorías, cuenta y configuración',
    () async {
      final db = createTestDatabase();

      final categories = await DriftCategoryRepository(db).getAll();
      expect(categories, hasLength(DefaultCategories.all.length));
      expect(
        categories.where((c) => c.kind == CategoryKind.expense),
        hasLength(DefaultCategories.expenses.length),
      );
      expect(
        categories.singleWhere((c) => c.countsAsSaving).name,
        'Inversiones',
      );

      expect(await DriftAccountRepository(db).getAll(), [Account.defaultCash]);
      expect(await DriftSettingsRepository(db).get(), const FinanceSettings());
    },
  );

  test('las claves foráneas están activas', () async {
    final repository = DriftTransactionRepository(createTestDatabase());

    await expectLater(
      repository.save(expense(1000, category: 'no-existe')),
      throwsA(isA<StorageException>()),
    );
  });

  test('StorageException no expone la causa al convertirse en texto', () {
    const exception = StorageException(
      'transactions.save',
      cause: 'INSERT ... 5000',
    );
    expect(exception.toString(), 'StorageException(transactions.save)');
  });
}
