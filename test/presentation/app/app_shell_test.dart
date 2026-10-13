import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/presentation/app/finance_app.dart';
import 'package:finance_app/presentation/cfo/ai_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeReminderScheduler reminders;
  late FakeSpeechInput speech;

  setUp(() {
    db = openTestDatabase();
    reminders = FakeReminderScheduler();
    speech = FakeSpeechInput();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            FixedClock(DateTime(2026, 10, 3, 10)),
          ),
          reminderSchedulerProvider.overrideWithValue(reminders),
          speechInputProvider.overrideWithValue(speech),
        ],
        child: const FinanceApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Desmonta la app (cancela streams de drift) y cierra la base.
  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  }

  testWidgets('el Home muestra lo que queda del sueldo en el ciclo', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Libre para gastar hasta tu sueldo'), findsOneWidget);
    expect(find.text('17 días'), findsOneWidget, reason: '3 → 19 oct');
    expect(find.text('Qué hacer ahora'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Próximos pagos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Próximos pagos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gastos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Ingresos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Patrimonio y metas'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Patrimonio y metas'), findsOneWidget);
    expect(reminders.scheduledHour, 18, reason: 'recordatorio 6 p. m.');

    await tearDownApp(tester);
  });

  testWidgets('la barra inferior tiene 5 destinos con nombre', (tester) async {
    await pumpApp(tester);

    for (final label in [
      'Inicio',
      'Movimientos',
      'Plan',
      'Patrimonio',
      'Tu CFO',
    ]) {
      expect(find.byTooltip(label), findsOneWidget);
      expect(find.text(label), findsWidgets);
    }

    await tearDownApp(tester);
  });

  testWidgets('el botón del encabezado cambia a oscuro y a claro', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cambiar a modo claro'), findsOneWidget);

    await tester.tap(find.byTooltip('Cambiar a modo claro'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cambiar a modo oscuro'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('atrás desde otra sección vuelve a Inicio', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Plan'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Plan'), findsNothing);

    await tearDownApp(tester);
  });

  testWidgets('registro rápido: + → valor → Guardar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Registrar movimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pumpAndSettle();

    expect(find.text('5.000'), findsOneWidget, reason: 'separador de miles');

    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Gasto registrado'), findsOneWidget);
    expect(find.text(r'-$ 5.000'), findsOneWidget, reason: 'últimos');
    await tester.scrollUntilVisible(
      find.text('100%'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('100%'), findsOneWidget, reason: 'desglose por categoría');

    await tearDownApp(tester);
  });

  testWidgets('voz: la frase dictada prellena el registro', (tester) async {
    speech.phrase = 'gasté 25 mil en almuerzo';
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Registrar por voz'));
    await tester.pumpAndSettle();

    expect(find.text('Escuché: "gasté 25 mil en almuerzo"'), findsOneWidget);
    expect(find.text('25.000'), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Gasto registrado'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Alimentación'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alimentación'), findsWidgets);

    await tearDownApp(tester);
  });

  testWidgets('todas las secciones, el análisis y los fijos se abren', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Copiar del mes anterior'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Configurar fondo'), findsOneWidget);
    for (final section in ['Movimientos', 'Patrimonio', 'Tu CFO', 'Inicio']) {
      await tester.tap(find.byTooltip(section));
      await tester.pumpAndSettle();
    }
    expect(find.text('Deudas y créditos', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Consejos del ciclo', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Tu CFO con IA', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byTooltip('Análisis'));
    await tester.pumpAndSettle();
    expect(find.text('Indicadores del mes'), findsOneWidget);
    Navigator.of(tester.element(find.text('Indicadores del mes'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Día en que normalmente llega tu sueldo'), findsOneWidget);
    await tester.ensureVisible(find.text('Gastos e ingresos fijos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos e ingresos fijos'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo fijo'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('Tu CFO con IA: se activa solo con consentimiento', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Tu CFO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurar'));
    await tester.pumpAndSettle();

    expect(find.text('Tu llave de Groq'), findsOneWidget);
    final list = find
        .descendant(
          of: find.byType(AiSettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Activar Tu CFO con IA'),
      200,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar Tu CFO con IA'));
    await tester.pumpAndSettle();
    expect(find.text('¿Enviar tu resumen a Groq?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.scrollUntilVisible(
      find.text('Ver exactamente qué se envía'),
      300,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver exactamente qué se envía'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cicloDeSueldo'), findsOneWidget);

    await tearDownApp(tester);
  });
}
