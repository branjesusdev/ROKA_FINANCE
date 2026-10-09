import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_app/application/backup/backup_ports.dart';
import 'package:finance_app/core/storage_exception.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/persistence/drift/tables.dart';
import 'package:finance_app/infrastructure/repositories/storage_guard.dart';

/// Copia completa en JSON: una lista por tabla, con los mismos campos que
/// guarda SQLite (montos en centavos, fechas en milisegundos).
///
/// Al importar nada se borra ni se duplica:
/// 1. Si el id ya existe, se omite.
/// 2. Si no, se busca un registro equivalente (p. ej. mismo gasto: tipo,
///    valor, día, categoría y descripción). Si existe, se omite y sus
///    vínculos (movimientos de un fijo, abonos de una deuda…) apuntan al
///    registro que ya estaba.
/// 3. Lo demás se agrega.
///
/// Los equivalentes se cuentan: si ya hay 1 café de $5.000 el mismo día y
/// la copia trae 2, se agrega solo 1.
final class DriftBackupStore implements BackupStore {
  const new(this._db);

  final AppDatabase _db;

  static const appId = 'finance_app';

  /// Versión del formato del archivo (no del esquema SQLite).
  static const formatVersion = 1;

  static const _settingsKey = 'settings';

  List<_Section<DataClass>> get _sections => [
    _Section<CategoryRow>(
      key: 'categories',
      table: _db.categories,
      fromJson: CategoryRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['kind']]),
    ),
    _Section<AccountRow>(
      key: 'accounts',
      table: _db.accounts,
      fromJson: AccountRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['type']]),
    ),
    _Section<DebtRow>(
      key: 'debts',
      table: _db.debts,
      fromJson: DebtRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['type']]),
    ),
    _Section<SavingsGoalRow>(
      key: 'savingsGoals',
      table: _db.savingsGoals,
      fromJson: SavingsGoalRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['type']]),
    ),
    _Section<FixedMovementRow>(
      key: 'fixedMovements',
      table: _db.fixedMovements,
      fromJson: FixedMovementRow.fromJson,
      refs: const {'categoryId': 'categories'},
      naturalKey: (r) => _key([r['name'], r['kind'], r['categoryId']]),
    ),
    _Section<ProvisionRow>(
      key: 'provisions',
      table: _db.provisions,
      fromJson: ProvisionRow.fromJson,
      refs: const {'categoryId': 'categories'},
      naturalKey: (r) => _key([r['name'], r['categoryId']]),
    ),
    _Section<TransactionRow>(
      key: 'transactions',
      table: _db.transactions,
      fromJson: TransactionRow.fromJson,
      refs: const {
        'categoryId': 'categories',
        'accountId': 'accounts',
        'debtId': 'debts',
        'provisionId': 'provisions',
        'fixedMovementId': 'fixedMovements',
      },
      naturalKey: (r) => _key([
        r['kind'],
        r['amountCents'],
        _day(r['date']),
        r['categoryId'],
        r['description'],
      ]),
    ),
    _Section<BudgetLineRow>(
      key: 'budgetLines',
      table: _db.budgetLines,
      fromJson: BudgetLineRow.fromJson,
      refs: const {'categoryId': 'categories'},
      naturalKey: (r) => _key([r['year'], r['month'], r['categoryId']]),
    ),
    _Section<AssetRow>(
      key: 'assets',
      table: _db.assets,
      fromJson: AssetRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['type']]),
    ),
    _Section<ExtraPaymentRow>(
      key: 'extraPayments',
      table: _db.extraPayments,
      fromJson: ExtraPaymentRow.fromJson,
      refs: const {'debtId': 'debts'},
      naturalKey: (r) => _key([r['debtId'], r['amountCents'], _day(r['date'])]),
    ),
    _Section<GoalContributionRow>(
      key: 'goalContributions',
      table: _db.goalContributions,
      fromJson: GoalContributionRow.fromJson,
      refs: const {'goalId': 'savingsGoals'},
      naturalKey: (r) => _key([r['goalId'], r['amountCents'], _day(r['date'])]),
    ),
    _Section<InvestmentRow>(
      key: 'investments',
      table: _db.investments,
      fromJson: InvestmentRow.fromJson,
      naturalKey: (r) => _key([r['name'], r['type'], _day(r['date'])]),
    ),
  ];

  static String _key(List<Object?> parts) => jsonEncode(parts);

  /// Día calendario local (las fechas se guardan en milisegundos).
  static String? _day(Object? millis) {
    if (millis is! int) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  Future<String> export({required DateTime exportedAt}) =>
      guardStorage('backup.export', () async {
        final data = <String, Object?>{};
        for (final section in _sections) {
          final rows = await _db.select(section.table).get();
          data[section.key] = [for (final row in rows) row.toJson()];
        }
        final settings = await _db.select(_db.financeSettingsTable).get();
        data[_settingsKey] = settings.isEmpty ? null : settings.first.toJson();
        return jsonEncode({
          'app': appId,
          'format': formatVersion,
          'schemaVersion': _db.schemaVersion,
          'exportedAt': exportedAt.toIso8601String(),
          'data': data,
        });
      });

  @override
  Future<BackupImportReport> import(String content) async {
    final data = _parse(content);
    try {
      return await _db.transaction(() => _merge(data));
    } on InvalidBackupException {
      rethrow;
      // Campos faltantes o con otro tipo: el archivo
      // no es válido (no es un error de programación).
      // ignore: avoid_catching_errors
    } on TypeError {
      throw const InvalidBackupException();
      // Enum con un nombre desconocido.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw const InvalidBackupException();
    } on FormatException {
      throw const InvalidBackupException();
    } on Exception catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StorageException('backup.import', cause: error),
        stackTrace,
      );
    }
  }

  Map<String, Object?> _parse(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const InvalidBackupException();
    }
    if (decoded is! Map<String, Object?> ||
        decoded['app'] != appId ||
        decoded['data'] is! Map<String, Object?>) {
      throw const InvalidBackupException();
    }
    final format = decoded['format'];
    final schema = decoded['schemaVersion'];
    if (format is! int || schema is! int) {
      throw const InvalidBackupException();
    }
    if (format > formatVersion || schema > _db.schemaVersion) {
      throw const InvalidBackupException(newerVersion: true);
    }
    return decoded['data']! as Map<String, Object?>;
  }

  Future<BackupImportReport> _merge(Map<String, Object?> data) async {
    // Por sección: id en la copia → id con el que queda en este teléfono.
    final idMaps = <String, Map<String, String>>{};
    var added = 0;
    var skipped = 0;
    var movementsAdded = 0;
    for (final section in _sections) {
      final rows = data[section.key];
      if (rows == null) continue;
      if (rows is! List<Object?>) throw const InvalidBackupException();
      final result = await _mergeSection(section, rows, idMaps);
      added += result.added;
      skipped += result.skipped;
      if (section.key == 'transactions') movementsAdded = result.added;
    }
    if (data[_settingsKey] case final Map<String, Object?> settings) {
      await _db
          .into(_db.financeSettingsTable)
          .insertOnConflictUpdate(
            SettingsRow.fromJson({
              ...settings,
              'id': FinanceSettingsTable.singletonId,
            }),
          );
    }
    return BackupImportReport(
      added: added,
      skipped: skipped,
      movementsAdded: movementsAdded,
    );
  }

  Future<({int added, int skipped})> _mergeSection<D extends DataClass>(
    _Section<D> section,
    List<Object?> rows,
    Map<String, Map<String, String>> idMaps,
  ) async {
    final existing = [
      for (final row in await _db.select(section.table).get()) row.toJson(),
    ];
    final existingIds = {for (final r in existing) r['id']};
    final backupIds = {
      for (final r in rows)
        if (r is Map<String, Object?>) r['id'],
    };
    // Equivalentes disponibles (sin contar los que coinciden por id con la
    // copia: esos ya se emparejan solos).
    final available = <String, List<String>>{};
    for (final r in existing) {
      if (backupIds.contains(r['id'])) continue;
      (available[section.naturalKey(r)] ??= []).add(r['id']! as String);
    }
    final idMap = idMaps[section.key] = {};
    var added = 0;
    var skipped = 0;
    for (final raw in rows) {
      if (raw is! Map<String, Object?>) throw const InvalidBackupException();
      final row = _remap(raw, section.refs, idMaps);
      final id = row['id'];
      if (id is! String) throw const InvalidBackupException();
      if (existingIds.contains(id)) {
        idMap[id] = id;
        skipped++;
        continue;
      }
      final matches = available[section.naturalKey(row)];
      if (matches != null && matches.isNotEmpty) {
        idMap[id] = matches.removeLast();
        skipped++;
        continue;
      }
      final inserted = await _db
          .into(section.table)
          .insert(
            section.fromJson(row) as Insertable<D>,
            mode: InsertMode.insertOrIgnore,
          );
      idMap[id] = id;
      // 0 = chocó con una restricción única (p. ej. presupuesto del mismo
      // mes y categoría).
      if (inserted == 0) {
        skipped++;
      } else {
        added++;
      }
    }
    return (added: added, skipped: skipped);
  }

  static Map<String, Object?> _remap(
    Map<String, Object?> row,
    Map<String, String> refs,
    Map<String, Map<String, String>> idMaps,
  ) {
    if (refs.isEmpty) return row;
    final copy = {...row};
    for (final MapEntry(key: field, value: target) in refs.entries) {
      final value = copy[field];
      if (value is String) copy[field] = idMaps[target]?[value] ?? value;
    }
    return copy;
  }
}

final class _Section<D extends DataClass> {
  const new({
    required this.key,
    required this.table,
    required this.fromJson,
    required this.naturalKey,
    this.refs = const {},
  });

  /// Nombre de la lista en el archivo.
  final String key;
  final TableInfo<Table, D> table;
  final D Function(Map<String, dynamic> json) fromJson;

  /// Identifica un registro equivalente aunque tenga otro id.
  final String Function(Map<String, Object?> row) naturalKey;

  /// Campo → sección a la que apunta (para seguir los ids emparejados).
  final Map<String, String> refs;
}
