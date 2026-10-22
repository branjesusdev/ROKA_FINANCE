# Roka — Finanzas personales offline-first (paquete `finance_app`)

App Flutter (Android, teléfono físico) 100% local para una persona que vive de su sueldo:
"¿cuánto me queda hasta el próximo pago y en qué se me va?". Ingresos, gastos, fijos,
presupuestos, apartados, patrimonio, créditos, metas, inversiones y análisis descriptivo.
Sin login, sin backend, sin cloud. Nombre visible: **Roka** (paquete/IDs siguen `finance_app`).
Prioridad: claridad > features · UX > complejidad · arquitectura mantenible > velocidad.

## Stack
Flutter 3.47 / Dart 3.13 · drift (SQLite, esquema v14) · flutter_riverpod 3 (estado + DI) · intl ·
flutter_local_notifications · speech_to_text · very_good_analysis. Gráficas con `CustomPainter`
propio (sin fl_chart). Detalle: `docs/architecture.md` · modelo y conceptos: `docs/domain-model.md` ·
diseño visual: `docs/design.md` · estado/fases: `docs/roadmap.md` · entorno: `docs/setup.md`.

## Arquitectura hexagonal (layer-first, módulos dentro de cada capa)
- `lib/domain/<modulo>/` entidades, value objects, ports (interfaces repositorio), servicios puros.
- `lib/application/<modulo>/` casos de uso + read models/builders. Solo depende de domain.
  Ports que no son repositorios de dominio (backup, voz, recordatorios) viven aquí.
- `lib/infrastructure/` adapters: drift (tablas, migraciones), repositorios, mappers, backup,
  notificaciones, voz, mercado, reloj, ids.
- `lib/presentation/<feature>/` screens/widgets. Lecturas: `shared/data_providers.dart` (observa ports);
  escrituras: casos de uso vía `bootstrap/use_cases.dart`. Nunca importar infrastructure.
- `lib/bootstrap/` composition root (`providers.dart` adapters→ports, `use_cases.dart`).
- `domain/` y `application/` = Dart puro: PROHIBIDO importar flutter, drift, riverpod, intl, dart:io.
  `test/architecture_test.dart` lo verifica.

## Conceptos del producto (usar estos nombres)
- **Ciclo de sueldo** (`PayCycle`, `PayCycleResolver`): del día que llega el sueldo al día antes del
  siguiente. Lo marca el ingreso real en categoría Salario, no solo el `payday` configurado.
  Sueldo que aún no se registra (`salaryLate`, con `today`): sigue el ciclo anterior hasta mañana
  (máx. `lateSalaryGraceDays`).
- **"Te queda"**: ingresos − gastos − fijos pendientes del ciclo (Home, `CycleSummaryBuilder`).
- **Día a día** (`CycleSummaryBuilder.isDayToDay`): gasto que no es ahorro ni planeado del mes.
  **Tope diario** (`DailySpendingCap`) reparte lo que queda entre los días que faltan, sin pasar
  del promedio del ciclo (`trackedDays`); el resto es `surplus` ("Sobra: apártalo",
  `MoneyOverview.dayToDaySurplus`, va completo a `SetAsidePlanner`).
- **Fijos** (`FixedMovement`): ingresos y gastos con `autoDebit` se registran solos al vencer
  (`PostDueFixedMovements` al abrir/reanudar). Los demás gastos (`needsConfirmation`) quedan "por
  confirmar" hasta "Ya lo pagué" (`ConfirmVariableFixed`); `MarkFixedUnpaid` lo deshace. Avisos
  9/15/20 h hasta confirmar. Variables (agua, luz) esperan el valor real; estimado =
  `VariableBillEstimator`. "Ya lo pagué" / "Recuérdame mañana o en 2 días" (`SnoozeFixedBill`, `FixedMovement.remindOn`) en la app y en la
  notificación (`ReminderAction`; los botones abren la app y `AppShell` los aplica).
- **Apartados / Pagos del año** (`Provision`): SOAT, colegio… se reparte la cuota por ciclo.
- **Cuadrar con mi dinero real** (`ReconcileBalance`): diferencia → categorías archivadas
  "Gastos sin registrar" / "Saldo inicial / ajuste".
- **Reconteo al llegar el sueldo** (`ReconcileBalance(closingOn:)`, `CycleRecount`, `RecountLevel`):
  al registrar Salario, "¿cuánto tenías antes?" cuadra el ciclo que cierra (diferencia el día antes,
  `recountDescription`). `CycleMovements.recount`: registrado, real que quedó y diferencia;
  < $50 mil verde, hasta $100 mil ámbar, más rojo (`FinanceSettings.recountWarningGap/AlertGap`).
- **Reiniciar mes** (`ResetCycleMovements`): borra lo anotado a mano en el ciclo (con deshacer).
- **Así vas este ciclo** (`CyclePulse`) y **Tu huella de gasto** (`SpendingRadar`, araña: este ciclo vs
  el pasado a la misma altura, por categoría y por día de la semana; solo gasto variable).
- **Tu CFO** (`CfoBrief`): consejos accionables + precios públicos de acciones (opt-in).
- **Libre para gastar** (`MoneyOverview`): disponible − fijos que faltan − apartados − ahorro
  pendiente (+ ingresos fijos por llegar). Nunca confundir con el saldo.
- **Reservas de fijos** (`FixedCoverageCalculator`): pagado / cubierto / parcial / sin cubrir /
  vencido. Pago anotado a mano que coincide con un fijo (`FixedPaymentMatcher`) ⇒ preguntar.
- **Alertas por reglas** (`FinancialAlertsBuilder`): deterministas, sin red; resumen 8 p. m.
- **Ingresos extraordinarios** (`Category.isExtraordinary`: prima, cesantías…) ⇒ `WindfallPlanner`
  propone reparto; `ApplyWindfallSlices` solo aplica lo que el usuario marca.
- **Tu CFO con IA** (`RunAiReview`, `AskCfo`): opt-in; interpreta `FinancialSnapshot`, nunca
  calcula montos base ni cambia datos.
- **Fijos por estado** (`FixedCycleStatusBuilder`): pagado/recibido (verde) vs por pagar (ámbar;
  rojo si no alcanza) vs vencido/pausado. La pantalla de fijos agrupa por estado y su cabecera
  (`FixedCycleOverviewBuilder`) da total, % pagado, vencidos, neto con ingresos fijos y dona por categoría.
- **Libre = tope diario**: `CycleSummary.plannedReserve` (presupuesto del mes por gastar + colchón
  de niños) se descuenta igual en `MoneyOverview.free` y en `DailySpendingCap`. El Home muestra lo
  ya apartado para pagos del año (`provisionsSaved`) y la cuota de hoy (`provisionsToday`).
- **Apartar para no gastarlo** (`SetAsidePlanner` → `ApplySetAside`): pagos del año pendientes y
  metas (máx. 50% de lo libre, o todo el `surplus` del tope si es más); solo aplica lo que el
  usuario marca.
- **Inversiones con precio real** (`RefreshInvestmentPrices`): `Investment.symbol` + `unitsMicros`
  ⇒ valor en pesos con precio público y tasa `COP=X`; `QuarterOutlookCalculator` = rango a 3 meses
  según el último año (estadística, nunca predicción ni recomendación).
- **Inversión en dólares** (`Investment.investedUsdCents`, `UsdRate`, `LoadUsdRate`): se escribe en
  US$ con decimales (`UsdInput`), se guarda en pesos con el dólar que confirma el usuario.
- **Vista previa de movimiento** (`TransactionPreviewSheet`): tocar = ver; Editar abre el formulario.
  Incluye análisis de 12 meses (`MovementHistoryBuilder`: misma descripción si se repite, si no
  la categoría; el usuario puede reagrupar a toda la categoría), barras o línea, tocar un mes =
  su detalle, y total, promedio, extremos, valor por vez, vs. promedio y tendencia trimestral.
- **Movimientos por ciclo** (`CycleMovementsBuilder`, `cycleMovementsProvider(back)`): ‹ ciclo ›,
  Gastos/Ingresos con su total, dona + lista por categoría; tocar una categoría filtra los
  movimientos de abajo (mismos datos, siempre suman igual).
- **Autocompletar descripción** (`DescriptionSuggestions`): máx. 5, de lo ya anotado y los fijos;
  elegir pone su categoría.
- **Análisis por categoría** (`CategoryReportBuilder`, `CategoryReportScreen`): 12 meses, mes más
  alto, promedio, cosas que más pesan. IA opcional: la pregunta se ve antes; las descripciones
  solo van si el usuario marca "Incluir lo que más compras".
- **Kilometraje** (`Transaction.odometerKm`, `FuelEconomyCalculator`): en Transporte/vehículo;
  costo por km con el método de tanque lleno.
- **Crédito enlazado a un fijo** (`FixedMovement.debtId`, `LinkDebtToFixed`, `payLinkedDebt`): al
  registrarse la cuota baja el saldo y suma la cuota pagada; el aviso dice cuántas faltan.
  `DebtOverview.recorded` compara tu registro (cuotas) con la proyección y la tasa implícita.
- **Tabla de pagos** (`LoanProjector.schedule`, `DebtOverview.schedule`/`interestCost`): cuota a cuota
  como la proyección del banco; intereses ya pagados (aprox. con el plan) + los que faltan.
- **¿Puedo gastar…?** (`SpendCheckBuilder` + `SpendDecision`): regla definitiva SÍ/NO. NO si toca fijos
  o lo apartado, si el tope de los días que siguen baja a menos de la mitad, o si un ciclo siguiente
  cierra en rojo; dice cuándo sí (`ForecastWhen`) y lista los fijos que faltan antes del sueldo.
  Lo que cabe en el tope de hoy siempre es SÍ. Simulación: no registra nada.
- **Mi sueldo / ¿Estaré corto?** (`FinanceSettings.monthlySalary`, `SalaryForecastBuilder`): sueldo de
  Ajustes (o fijo en Salario, promedio de ciclos cerrados, el de este ciclo) − fijos (las cuotas de un
  crédito enlazado se acaban) − pagos del año − gasto variable promedio, 6 ciclos; `ForecastChart`.
- **Frase del día** (`WealthWisdom`, `Quote.book`/`today`): libros de dinero con qué hacer hoy; aviso
  6:30 a. m. "escríbela" (`ReminderPlanner.wisdomFirstId`).
- **Gastos de hoy** (`CycleSummary.todaySpends`, `TodaySpendKind`): qué baja el tope (día a día) y qué
  no (fijos/cuotas, categorías del mes, ahorro). Hoja al tocar el tope del Inicio.
- **Tu Cashflow** (`CashflowStatementBuilder`, Padre Rico): ingreso activo/pasivo (`Asset.monthlyIncome`),
  gastos promedio de ciclos cerrados, flujo del mes, carrera de la rata; `play(CashflowCard)` simula
  una oportunidad o un capricho (no registra nada).
- **Copia de seguridad** (`ExportBackup`/`ImportBackup`): JSON completo; importar fusiona sin duplicar y,
  si la copia es más reciente que el último movimiento local, actualiza lo emparejado (y los ajustes).
- **Ideas para invertir** (`WatchScoreCalculator`, `LoadWatchlist.rank`, `InvestmentIdeasQuestion`): lista
  ordenada por puntaje descriptivo + tipo de riesgo; "¿Cuánto quieres invertir?" arma la pregunta a la IA.

## Reglas
- Dinero = `Money` (int en centavos, COP). Nunca `double` para montos (solo para pintar). Tasas: `InterestRate`.
- Entidades `@immutable` (meta). Adapters lanzan `StorageException`; casos de uso devuelven `Result<T>`/`Failure`.
  Errores de validación = códigos en `ValidationCodes`; la UI los traduce en `failureMessage`.
- Cero lógica financiera en widgets/controllers: va en servicios de dominio o casos de uso/builders.
- Entidades de dominio ≠ filas drift: siempre mapper en infrastructure.
- Ports devuelven tipos de dominio; `watch*()` como `Stream` para UI reactiva.
- IDs String (UUID v4) vía port `IdGenerator`. Fechas vía port `Clock`. Umbrales financieros en
  `FinanceSettings`; constantes de UI/algoritmo como `static const` con nombre (sin magic numbers).
- Widgets pequeños y `const`; constructores `const new(...)` y parámetros privados con nombre
  (`required this._repo`, el llamador usa `repo:`) — Dart 3.13, lint activo.
- UI en español simple, sin jerga. Semáforo y comparaciones: color + icono + texto + % (accesibilidad).
  Gráficas con `Semantics` que resuma los valores.
- Insights descriptivos basados en datos del usuario; nunca presentarlos como asesoría financiera.
- Colores desde `AppTheme`/`ColorScheme` ("Roka Neo": negro neutro `#0A0B0D` + lima eléctrico
  `#C6FF3D`; vívidos solo en rellenos/gráficas). Fuente Inter empaquetada. Tarjetas protagonistas:
  `DailyArt` (cambia cada día; `daily_art_test` exige ≥ 7:1).
  Animaciones con `shared/motion.dart` (`Motion` duraciones/curvas, `FadeSlideIn`, `ChartReveal`,
  `AnimatedMoneyText`); sin timers y respetando "quitar animaciones" del sistema.
  Sin rosados ni morados; rojo solo para alertas. Categorías: `CategoryStyle` (icono + color por `iconKey`).

## Checklist al cambiar el esquema drift
1. Columna/tabla en `tables.dart` + subir `schemaVersion` + paso en `onUpgrade` (`app_database.dart`).
2. `dart run build_runner build`. Test en `test/infrastructure/persistence/migration_test.dart`.
3. Tabla nueva ⇒ añadir sección en `DriftBackupStore._sections` (clave natural + `refs` de ids)
   o no se exportará (excepto secretos y datos derivados: `ai_secrets`, `ai_reviews`).
   Columna nueva no nula ⇒ su valor en `_Section.defaults` para que los backups viejos importen
   (test con `test/fixtures/backup_v8.json`). Si un paso viejo de `onUpgrade` inserta filas de
   esa tabla, agrega la columna antes (ver `isExtraordinary`).

## Futuro cloud
Nuevo adapter (`CloudXRepository`) que implemente el mismo port + cambio en `bootstrap/`.
Dominio y casos de uso no cambian. No añadir dependencias cloud/analytics/ads.

## Privacidad
Nunca loguear montos, descripciones ni registros completos. Nada sale del dispositivo.
Excepciones (ambas opt-in):
1. Precios públicos de acciones vía port `MarketDataSource` (Yahoo, gratis, sin clave): solo
   envía símbolos (y el de la tasa de cambio). Lista de "Tu CFO": cuando el usuario lo pide.
   Inversiones propias: al abrir Patrimonio (una vez por sesión) solo si el usuario escribió el
   símbolo — escribirlo es la autorización — y con el botón de actualizar.
   Dólar de hoy (`COP=X`): solo al elegir "En dólares" en una inversión.
2. "Tu CFO con IA" vía port `AiAdvisor` (Groq, `openai/gpt-oss-120b`): solo con
   `FinanceSettings.aiEnabled` (consentimiento explícito) y solo `FinancialSnapshot` — totales y
   tipos (y símbolos de bolsa, públicos), sin descripciones, notas, movimientos individuales ni
   nombres escritos por el usuario.
   Excepción visible: "Pregúntale a tu CFO" envía la pregunta que el usuario ve y puede editar
   (análisis por categoría: totales por mes; descripciones solo si marca "Incluir lo que más compras").
   La llave la pega el usuario (`AiKeyStore`, tabla `ai_secrets`): **nunca en el código, el APK,
   la copia de seguridad ni los logs**.
Dictado por voz: en el dispositivo por defecto; con internet (reconocedor de Google) solo si
el usuario lo elige explícitamente porque el teléfono no tiene español sin conexión.
Notificaciones con montos: `NotificationVisibility.private` (ocultas en pantalla bloqueada).
Copia de seguridad: el archivo solo va donde el usuario elige (selector de Android, SAF); la app
no lo sube a ningún lado. Contiene todos los datos en claro: avisarlo en la UI.

## Testing
Prioridad: servicios de dominio, builders y casos de uso (fakes en memoria en `test/support/fakes.dart`,
sin mocks). Repos drift y backup: `createTestDatabase()` (`NativeDatabase.memory()`, semillas reales).
Widgets: `test/presentation/app/app_shell_test.dart`. Nada de tests solo por cobertura.

## Comandos
`flutter pub get` · `dart run build_runner build` (codegen drift) · `dart format .`
`flutter analyze` · `flutter test` · `flutter devices` · `flutter run -d <id-telefono>`
`flutter build apk --debug` (verifica Kotlin/recursos Android).

## Flujo de trabajo
Inspeccionar → explicar cambio → implementar → analyze → tests → corregir → resumir.
Verificar versión en pub.dev antes de añadir paquete (`flutter pub add`); preferir canal nativo
pequeño en `MainActivity.kt` antes que un paquete grande. No editar código generado (`*.g.dart`).
Al terminar algo visible, actualizar `docs/roadmap.md`.
