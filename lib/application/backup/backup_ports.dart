/// Resultado de importar una copia: cuántos registros se agregaron y cuántos
/// se omitieron porque ya existían (mismo id o mismos datos).
final class BackupImportReport {
  const new({
    required this.added,
    required this.skipped,
    required this.movementsAdded,
  });

  final int added;
  final int skipped;

  /// Ingresos y gastos agregados (parte de [added]).
  final int movementsAdded;
}

/// El archivo no es una copia de la app, está dañado o es de una versión
/// más nueva.
final class InvalidBackupException implements Exception {
  const new({this.newerVersion = false});

  final bool newerVersion;

  @override
  String toString() => 'InvalidBackupException(newer: $newerVersion)';
}

/// Port: lee y combina todos los datos de la app en un texto portable.
abstract interface class BackupStore {
  /// Todos los datos (movimientos, fijos, deudas, metas, apartados,
  /// patrimonio, presupuestos y ajustes).
  Future<String> export({required DateTime exportedAt});

  /// Agrega lo que no exista; nunca borra ni duplica. Los ajustes se toman
  /// de la copia. Todo o nada: si falla, no cambia nada.
  ///
  /// Lanza [InvalidBackupException] si el archivo no sirve.
  Future<BackupImportReport> import(String content);
}

/// Port: el usuario elige dónde guardar o qué archivo abrir.
abstract interface class BackupFiles {
  /// `false` si el usuario canceló.
  Future<bool> save({required String fileName, required String content});

  /// Contenido del archivo elegido o `null` si canceló.
  Future<String?> open();
}
