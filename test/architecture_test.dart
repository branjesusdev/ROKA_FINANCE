import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifica la regla de dependencias de la arquitectura hexagonal.
void main() {
  final importPattern = RegExp(r'''^import\s+['"]([^'"]+)['"]''');

  List<(String file, String uri)> importsUnder(String dir) {
    final root = Directory(dir);
    if (!root.existsSync()) return const [];
    return [
      for (final file in root.listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart'))
          for (final line in file.readAsLinesSync())
            if (importPattern.firstMatch(line.trim()) case final match?)
              (file.path, match.group(1)!),
    ];
  }

  void expectNoImports(String dir, List<String> forbiddenPrefixes) {
    final violations = [
      for (final (file, uri) in importsUnder(dir))
        if (forbiddenPrefixes.any(uri.startsWith)) '$file -> $uri',
    ];
    expect(violations, isEmpty, reason: 'Imports prohibidos en $dir');
  }

  const frameworks = [
    'package:flutter/',
    'package:flutter_riverpod/',
    'package:riverpod/',
    'package:drift',
    'package:intl/',
    'package:uuid/',
    'dart:io',
    'dart:ui',
  ];

  test('core es Dart puro', () {
    expectNoImports('lib/core', [
      ...frameworks,
      'package:finance_app/domain/',
      'package:finance_app/application/',
      'package:finance_app/infrastructure/',
      'package:finance_app/presentation/',
    ]);
  });

  test('domain es Dart puro y no conoce capas externas', () {
    expectNoImports('lib/domain', [
      ...frameworks,
      'package:finance_app/application/',
      'package:finance_app/infrastructure/',
      'package:finance_app/presentation/',
      'package:finance_app/bootstrap/',
    ]);
  });

  test('application solo depende de domain y core', () {
    expectNoImports('lib/application', [
      ...frameworks,
      'package:finance_app/infrastructure/',
      'package:finance_app/presentation/',
      'package:finance_app/bootstrap/',
    ]);
  });

  test('presentation no accede a infrastructure', () {
    expectNoImports('lib/presentation', [
      'package:finance_app/infrastructure/',
      'package:drift',
    ]);
  });
}
