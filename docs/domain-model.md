# Modelo de dominio inicial

## Inconsistencias detectadas en los requisitos y decisión propuesta

| # | Problema | Decisión |
|---|---|---|
| 1 | "Pasivos" y "Créditos/Deudas" son dos módulos que registrarían lo mismo dos veces. | Una sola entidad `Debt`. Las condiciones de crédito (`LoanTerms`) son opcionales: una tarjeta o préstamo informal es un `Debt` sin cuotas. Pasivos = Σ saldos de `Debt`. |
| 2 | "Inversiones" aparece como categoría de gasto, tipo de activo y módulo propio (triple conteo). | `Investment` es su propio agregado y suma al patrimonio. El tipo de activo "inversión" se elimina. La categoría "Inversiones" se marca `countsAsSaving`: no cuenta como gasto, cuenta como ahorro. |
| 3 | "Ahorro del mes" sin definición. | `ahorro = ingresos − gastos` (gastos excluyen categorías `countsAsSaving`). Tasa de ahorro = ahorro / ingresos. |
| 4 | "Cuenta/fuente" vs activos "cuentas bancarias": ¿el saldo se calcula o se ingresa? | v1: `Account` es solo etiqueta de origen del movimiento. El valor de activos se registra manualmente (valoración). Saldo automático por cuenta = mejora futura. |
| 5 | Crédito pide a la vez cuotas iniciales, pagadas, restantes y fecha fin: pueden contradecirse. | Se almacenan saldo, tasa, cuota, cuotas iniciales/pagadas (opcionales). **Cuotas restantes, fecha fin e intereses se calculan** con `LoanProjector` desde el saldo actual. |
| 6 | "Tipo" del gasto no definido. | `ExpenseNature`: `essential` / `discretionary`. Alimenta el fondo de emergencia (gastos esenciales sugeridos = promedio de 3 meses). |
| 7 | Pago de una deuda es gasto y también reduce el pasivo. | Registrar pago crea `Transaction` (categoría Deudas, `debtId`) y reduce el saldo en la porción a capital (cuota − interés del mes − cargos). Abono extraordinario = 100% a capital. Saldo editable siempre. |
| 8 | Umbrales del semáforo y "compra pequeña" no definidos. | `FinanceSettings` configurable: amarillo ≥ 80%, rojo > 100%, compra pequeña ≤ $20.000, ahorro objetivo 10%. |
| 9 | Moneda. | Solo COP en v1, `Money` preparado para añadir moneda después. |

## Value objects (`domain/shared`)
- `Money(cents: int)` — `+ − × %`, comparación, `isZero`, nunca `double`.
- `Percentage(basisPoints: int)` — 10% = 1000 bp.
- `YearMonth(year, month)`, `DateRange(start, endExclusive)`.
- `TrafficLight { ok, warning, critical }` + `TrafficLightThresholds`.
- Ports transversales: `Clock { DateTime now(); }`, `IdGenerator { String next(); }`.

## Entidades / agregados

| Entidad | Campos clave |
|---|---|
| `Category` | id, name, kind (`income`/`expense`), iconKey, colorKey, sortOrder, isArchived, countsAsSaving |
| `Account` | id, name, type (`cash`/`bank`/`card`/`other`) |
| `Transaction` | id, kind, amount: Money, categoryId, date, description?, accountId?, nature? (solo gasto), notes?, debtId?, createdAt |
| `BudgetLine` | id, period: YearMonth, categoryId, limit: Money |
| `Asset` | id, name, type (`cash`/`bankAccount`/`vehicle`/`property`/`other`), currentValue, valuedAt, notes? |
| `Debt` | id, name, type (`bankLoan`/`creditCard`/`personalLoan`/`other`), originalAmount, currentBalance, notes?, terms?: `LoanTerms` |
| `LoanTerms` (VO) | rate: InterestRate, monthlyPayment (cuota total, incluye cargos), monthlyFees (seguros/comisiones), totalInstallments?, paidInstallments?, startDate? |
| `ExtraPayment` | id, debtId, amount, date |
| `SavingsGoal` | id, name, type (`emergency`/`travel`/`vehicle`/`housing`/`investment`/`custom`), targetAmount, targetDate?, desiredMonthlyContribution?, emergencyPlan? |
| `EmergencyPlan` (VO) | essentialMonthlyExpenses, targetMonths → target = producto |
| `GoalContribution` | id, goalId, amount, date (valor actual de la meta = Σ aportes) |
| `Investment` | id, name, type (`fund`/`stocks`/`fixedTerm` (CDT)/`crypto`/`other`), investedAmount, currentValue, date, notes? |
| `FinanceSettings` | savingsTargetRate, trafficLightThresholds, smallExpenseThreshold, payday (def. 20), dailyReminder, reminderHour (def. 18) |
| `PayCycle` (VO) | payday, start, endExclusive. Ciclo de sueldo: día de pago → día anterior al siguiente pago |
| `FixedMovement` | id, name, kind, amount, categoryId, dayOfMonth, isActive, lastPostedOn? (evita duplicados) |

Categorías semilla — gasto: Alimentación, Vivienda, Transporte, Educación, Salud, Entretenimiento,
Deudas, Servicios, Compras, Hijos/Familia, Inversiones (`countsAsSaving`), Otros, Deporte (v2).
Ingreso: Salario, Ingresos adicionales, Ingresos extraordinarios, Otros.

## Ports (repositorios, en `domain/<modulo>/`)
`CategoryRepository`, `AccountRepository`, `TransactionRepository`, `BudgetRepository`,
`AssetRepository`, `DebtRepository` (incluye extra payments), `SavingsGoalRepository`
(incluye aportes), `InvestmentRepository`, `SettingsRepository`, `FixedMovementRepository`. Todos con `Future` para comandos
y `Stream watch*()` para lecturas que la UI observa. Fallos de almacenamiento → `StorageException`.
`BudgetRepository.save` reemplaza el límite si ya existe línea para (mes, categoría).

## Servicios de dominio (puros, 100% testeados)
- `NetWorthCalculator` — activos + inversiones − deudas.
- `CashFlowCalculator` — ingresos, gastos, ahorro y tasa de ahorro de un período.
- `BudgetEvaluator` — por categoría: presupuesto, gastado, disponible, % usado, `TrafficLight`.
- `TrafficLightThresholds.classifyUsage` — % de uso → ok/warning/critical según umbrales.
- `InterestRate.monthlyEffective` — EA/NMV/EM → efectiva mensual.
- `LoanProjector` — tabla francesa desde saldo actual: cuotas restantes, fecha fin, intereses
  totales; escenario con abono mensual adicional; comparación (meses e intereses ahorrados).
  Detecta cuota que no cubre intereses (deuda que nunca termina).
- `SavingsTargetEvaluator` — meta = ingreso × %, ahorro actual, % alcanzado, faltante.
- `GoalProgressCalculator` / `EmergencyFundCalculator`.
- `PayCycle.containing` — ciclo que contiene una fecha; días restantes; fecha de un día del mes
  dentro del ciclo (día inexistente → último del mes).
- `FixedMovementScheduler` — fijos vencidos (registrar ya) y pendientes del ciclo actual.
- `VoiceEntryParser` / `SpokenAmountParser` — frase dictada → tipo, monto, categoría,
  descripción, "ayer". Aritmética entera.
- `SpendingInsightsAnalyzer` — participación por categoría, variación vs mes anterior, conteo y
  suma de compras pequeñas, uso de presupuesto. Devuelve `Insight` tipados (no strings): la UI los
  redacta en lenguaje descriptivo.

## Casos de uso (`application/`)

| Módulo | Casos de uso |
|---|---|
| transactions | `RegisterExpense` (rápido: monto + categoría), `RegisterIncome`, `UpdateTransaction`, `DeleteTransaction`, `WatchMonthTransactions`, `GetRecentTransactions`, `GetFrequentCategories` |
| categories / accounts | `ListCategories`, `CreateCategory`, `UpdateCategory`, `ArchiveCategory`, `ReorderCategories`, `ListAccounts`, `CreateAccount`, `SeedDefaults` |
| budgets | `SetBudgetLine`, `CopyPreviousMonthBudget`, `GetMonthBudgetStatus` |
| wealth / debts | `UpsertAsset`, `DeleteAsset`, `UpsertDebt`, `RegisterDebtPayment`, `RegisterExtraPayment`, `GetDebtProjection`, `SimulateExtraMonthlyPayment` (no persiste), `GetNetWorth` |
| savings | `UpdateFinanceSettings`, `GetSavingsStatus`, `UpsertGoal`, `AddContribution`, `ConfigureEmergencyFund`, `SuggestEssentialExpenses` |
| investments | `UpsertInvestment`, `DeleteInvestment`, `GetPortfolioSummary` |
| fixed / cycle | `SaveFixedMovement`, `DeleteFixedMovement`, `PostDueFixedMovements` (al abrir/reanudar la app), `UpdatePayday`, `CycleSummaryBuilder` (Home: lo que queda del sueldo) |
| reminders / voice | `SyncDailyReminder` (port `ReminderScheduler`), port `SpeechInput` (reconocimiento en el dispositivo) |
| insights | `GetSpendingInsights`, `GetCategoryBreakdown`, `GetFinancialHealth`, `GetHomeSummary` (compone los anteriores) |

## UX clave: registro rápido de gasto
FAB `+` en Home → bottom sheet con monto enfocado (teclado numérico, formato `$5.000` en vivo) →
chips de 6 categorías frecuentes (últimos 30 días; semilla si no hay datos) → Guardar.
Fecha = hoy, cuenta = última usada. Descripción / fecha / notas en "Más detalles" colapsado.
Objetivo: registrar en < 5 s con 2 toques + dígitos.

Navegación (`NavigationBar`, 5 destinos): Inicio · Movimientos · Presupuesto · Patrimonio · Metas.
Análisis y salud financiera se abren desde tarjetas del Home.
