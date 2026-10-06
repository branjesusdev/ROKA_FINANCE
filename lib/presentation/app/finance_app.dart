import 'package:finance_app/presentation/app/app_shell.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FinanceApp extends StatelessWidget {
  const new({super.key});

  static const locale = Locale('es', 'CO');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
    );
  }
}
