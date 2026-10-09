import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/app/app_shell.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceApp extends ConsumerWidget {
  const new({super.key});

  static const locale = Locale('es', 'CO');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(settingsProvider).value?.appearance ?? Appearance.system;
    return MaterialApp(
      title: 'Roka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
    );
  }
}
