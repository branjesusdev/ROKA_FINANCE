import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/domain/categories/default_categories.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/debts/loan_terms.dart';
import 'package:finance_app/domain/fixed/fixed_movement.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/markets/market_quote.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/infrastructure/persistence/drift/app_database.dart';
import 'package:finance_app/infrastructure/repositories/drift_debt_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_fixed_movement_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_investment_repository.dart';
import 'package:finance_app/infrastructure/repositories/drift_transaction_repository.dart';
import 'package:finance_app/presentation/app/finance_app.dart';
import 'package:finance_app/presentation/cashflow/cashflow_screen.dart';
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
  late FakeMarketDataSource market;

  setUp(() {
    db = openTestDatabase();
    reminders = FakeReminderScheduler();
    speech = FakeSpeechInput();
    market = FakeMarketDataSource();
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
          marketDataSourceProvider.overrideWithValue(market),
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

  testWidgets('la barra inferior tiene 5 destinos solo con icono', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final label in [
      'Inicio',
      'Movimientos',
      'Plan',
      'Patrimonio',
      'Tu CFO',
    ]) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    expect(find.text('Movimientos'), findsNothing, reason: 'sin textos');

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

  testWidgets('fijos por color y movimiento en vista previa antes de editar', (
    tester,
  ) async {
    final fixed = DriftFixedMovementRepository(db);
    for (final (id, name, day) in [
      ('rent', 'Arriendo', 1),
      ('gym', 'Gimnasio', 15),
    ]) {
      await fixed.save(
        FixedMovement(
          id: id,
          name: name,
          kind: TransactionKind.expense,
          amount: const Money.pesos(300000),
          categoryId: 'seed-expense-housing',
          dayOfMonth: day,
          autoDebit: id == 'rent',
        ),
      );
    }
    await pumpApp(tester);

    // El arriendo (día 1, débito automático) se registró solo al abrir:
    // queda como pagado.
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gastos e ingresos fijos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos e ingresos fijos'));
    await tester.pumpAndSettle();
    expect(find.text('Por pagar este ciclo'), findsOneWidget);
    expect(find.text('Ya pagados este ciclo'), findsOneWidget);
    expect(find.text('Pagado 1 oct'), findsOneWidget);
    expect(find.text('Por pagar 15 oct'), findsOneWidget);
    Navigator.of(tester.element(find.text('Nuevo fijo'))).pop();
    await tester.pumpAndSettle();
    final settings = find.text('Día en que normalmente llega tu sueldo');
    if (settings.evaluate().isNotEmpty) {
      Navigator.of(tester.element(settings)).pop();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Movimientos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arriendo'));
    await tester.pumpAndSettle();
    expect(find.text('Fijo: Arriendo'), findsOneWidget, reason: 'vista previa');
    expect(find.text('Eliminar gasto'), findsNothing, reason: 'aún no edita');

    await tester.tap(find.widgetWithText(FilledButton, 'Editar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eliminar gasto'));
    expect(find.text('Eliminar gasto'), findsOneWidget, reason: 'formulario');

    await tearDownApp(tester);
  });

  testWidgets('Patrimonio: una acción se valora con su precio real', (
    tester,
  ) async {
    await DriftInvestmentRepository(db).save(
      Investment(
        id: 'nvda',
        name: 'Nvidia',
        type: InvestmentType.stocks,
        investedAmount: const Money.pesos(1000000),
        currentValue: const Money.pesos(1000000),
        date: DateTime(2026, 5),
        symbol: 'NVDA',
        unitsMicros: 2 * Investment.microsPerUnit,
      ),
    );
    MarketQuote quote(String symbol, int price, String currency) => MarketQuote(
      symbol: symbol,
      currency: currency,
      lastPriceMinor: price,
      weeklyClosesMinor: [
        for (var i = 0; i < 52; i++) price - 1000 + (i.isEven ? 300 : 0),
      ],
      asOf: DateTime(2026, 10, 3),
    );
    // 2 acciones × 150 USD × 4.000 = 1.200.000 pesos.
    market.quotes['NVDA'] = quote('NVDA', 15000, 'USD');
    market.quotes['COP=X'] = quote('COP=X', 400000, 'COP');
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Patrimonio'));
    await tester.pumpAndSettle();
    // Deja la fila lejos de la barra inferior antes de tocarla.
    await tester.scrollUntilVisible(
      find.text(
        'Registra créditos, tarjetas o préstamos para ver cuánto te '
        'falta por pagar.',
      ),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(market.requested, contains('NVDA'), reason: 'consulta al abrir');
    expect(find.text(r'$ 1.200.000'), findsWidgets);

    await tester.tap(find.text('Nvidia'));
    await tester.pumpAndSettle();
    expect(
      find.text('Próximos 3 meses, si se mueve como el último año'),
      findsOneWidget,
    );
    expect(find.text('Lectura de Tu CFO'), findsOneWidget);

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

  testWidgets('Tu Cashflow: tablero y una carta que cambia el flujo', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Tu CFO'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tu Cashflow'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tu Cashflow'));
    await tester.pumpAndSettle();

    expect(find.text('Salida de la carrera de la rata'), findsOneWidget);
    expect(find.text('Estado de resultados (al mes)'), findsOneWidget);

    final list = find
        .descendant(
          of: find.byType(CashflowScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Capricho'),
      300,
      scrollable: list,
    );
    await tester.ensureVisible(find.text('Capricho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capricho'));
    await tester.pumpAndSettle();
    expect(find.text('Te paga al mes'), findsNothing);
    final cost = find.widgetWithText(TextField, 'Te cuesta al mes');
    await tester.ensureVisible(cost);
    await tester.pumpAndSettle();
    await tester.enterText(cost, '250000');
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu flujo de caja baja'), findsOneWidget);
    expect(find.textContaining('avanzarías en vez de'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('la llave guardada se ve enmascarada y activa la IA', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Tu CFO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Llave (empieza por gsk_)'),
      'gsk_prueba123456XYZ9',
    );
    await tester.ensureVisible(find.text('Guardar llave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar llave'));
    await tester.pumpAndSettle();
    expect(find.text('¿Enviar tu resumen a Groq?'), findsOneWidget);
    await tester.tap(find.text('Acepto'));
    await tester.pumpAndSettle();

    expect(find.text('Llave guardada en este teléfono'), findsOneWidget);
    expect(
      find.text('gsk_\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022XYZ9'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byTooltip('Mostrar llave'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mostrar llave'));
    await tester.pumpAndSettle();
    expect(find.text('gsk_prueba123456XYZ9'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Cambiar llave'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cambiar llave'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pega la llave nueva para reemplazar la actual.'),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
      reason: 'guardar la llave y aceptar la deja activa',
    );

    await tearDownApp(tester);
  });

  testWidgets('¿Puedo gastar…?: SÍ o NO con el sueldo y la proyección', (
    tester,
  ) async {
    await DriftTransactionRepository(db).save(
      Transaction(
        id: 'sueldo',
        kind: TransactionKind.income,
        amount: const Money.pesos(3400000),
        categoryId: DefaultCategories.salaryId,
        date: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
      ),
    );
    await pumpApp(tester);

    await tester.tap(find.text('¿Puedo gastar…?').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '20000');
    await tester.pumpAndSettle();
    expect(find.text('SÍ, puedes'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '9000000');
    await tester.pumpAndSettle();
    expect(find.text('NO lo gastes'), findsOneWidget);
    expect(
      find.text(
        'Así quedarían tus próximos meses si lo pagas hoy',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tearDownApp(tester);
  });

  testWidgets('autocompletar pone la categoría; gasolina con km y análisis', (
    tester,
  ) async {
    await DriftTransactionRepository(db).save(
      Transaction(
        id: 'gas-1',
        kind: TransactionKind.expense,
        amount: const Money.pesos(90000),
        categoryId: 'seed-expense-transport',
        date: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
        description: 'Gasolina',
        odometerKm: 10000,
      ),
    );
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Registrar movimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '100000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Descripción (opcional)'),
      'gas',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Transporte · última'), findsOneWidget);
    await tester.tap(find.textContaining('Transporte · última'));
    await tester.pumpAndSettle();

    final km = find.widgetWithText(
      TextField,
      'Kilometraje del vehículo (opcional)',
    );
    expect(km, findsOneWidget, reason: 'Transporte quedó elegida');
    expect(find.text('La última vez: 10.000 km.'), findsOneWidget);
    await tester.ensureVisible(km);
    await tester.enterText(km, '10400');
    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(r'Te costó $ 250 por km en los últimos 400 km'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Movimientos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasolina'));
    await tester.pumpAndSettle();
    expect(find.text('10.400 km'), findsOneWidget);
    await tester.tap(find.text('Ver análisis de Transporte'));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué mes gasté más?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gasolina de tu vehículo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(r'$ 250 por km'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('inversión en dólares: 253,70 dólares se pasan a pesos', (
    tester,
  ) async {
    market.quotes['COP=X'] = MarketQuote(
      symbol: 'COP=X',
      currency: 'COP',
      lastPriceMinor: 400000,
      weeklyClosesMinor: const [400000],
      asOf: DateTime(2026, 10, 3),
    );
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Patrimonio'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Agregar inversión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar inversión'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Nvidia');
    await tester.ensureVisible(find.text('En dólares'));
    await tester.tap(find.text('En dólares'));
    await tester.pumpAndSettle();
    expect(market.requested, contains('COP=X'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor invertido en dólares'),
      '253.70',
    );
    await tester.pumpAndSettle();
    expect(find.text(r'≈ $ 1.014.800 pesos'), findsWidgets);

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final saved = (await DriftInvestmentRepository(db).getAll()).single;
    expect(saved.investedUsdCents, 25370);
    expect(saved.investedAmount, const Money.pesos(1014800));

    await tearDownApp(tester);
  });

  testWidgets('crédito: explica las cuotas y se enlaza a un gasto fijo', (
    tester,
  ) async {
    await DriftDebtRepository(db).save(
      const Debt(
        id: 'carro',
        name: 'Crédito carro',
        type: DebtType.bankLoan,
        originalAmount: Money.pesos(20000000),
        currentBalance: Money.pesos(15000000),
        terms: LoanTerms(
          rate: InterestRate(
            rate: Percentage.whole(24),
            type: InterestRateType.effectiveAnnual,
          ),
          monthlyPayment: Money.pesos(1000000),
          totalInstallments: 24,
          paidInstallments: 5,
        ),
      ),
    );
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Patrimonio'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Crédito carro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crédito carro'));
    await tester.pumpAndSettle();

    expect(find.text('Según tu saldo, tasa y cuota'), findsOneWidget);
    expect(find.text('Según tu registro (19 cuotas)'), findsOneWidget);
    expect(find.textContaining('No cuadran'), findsOneWidget);

    final create = find.textContaining('Crear fijo de');
    await tester.scrollUntilVisible(
      create,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enlazado con «Cuota Crédito carro»'), findsOne);
    final fixed = (await DriftFixedMovementRepository(db).getAll()).single;
    expect(fixed.debtId, 'carro');
    expect(fixed.dayOfMonth, 15);

    await tearDownApp(tester);
  });
}
