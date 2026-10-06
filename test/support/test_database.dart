import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base SQLite en memoria, con migración y semillas reales.
///
/// `closeStreamsSynchronously` evita timers pendientes de drift al desmontar
/// widgets dentro del reloj falso de `testWidgets`.
AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

/// [openTestDatabase] que se cierra automáticamente al terminar el test.
AppDatabase createTestDatabase() {
  final database = openTestDatabase();
  addTearDown(database.close);
  return database;
}
