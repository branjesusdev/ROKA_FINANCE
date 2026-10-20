# Arquitectura

## Decisión: hexagonal *layer-first* con módulos dentro de cada capa

La estructura sugerida inicialmente mezclaba dos ejes (`features/` y `domain/` + `application/` +
`infrastructure/` a nivel raíz), lo que deja ambiguo dónde vive cada cosa. Se elige **capa primero,
módulo dentro de la capa** porque:

1. Es un único *bounded context* (finanzas personales) con cálculos transversales: Home, salud
   financiera y fugas de dinero combinan transacciones, presupuestos, deudas y metas. Un dominio
   compartido evita dependencias cruzadas entre "features".
2. La regla de dependencias se verifica por carpeta (`test/architecture_test.dart` falla si
   `lib/domain` o `lib/application` importan Flutter, drift, riverpod o intl).
3. Sustituir SQLite por cloud = tocar solo `infrastructure/` y `bootstrap/`.

```text
lib/
  main.dart                      # runApp(ProviderScope(...)) — nada más
  bootstrap/                     # providers.dart (adapters → ports), use_cases.dart (escrituras)
  core/                          # Result, Failure, StorageException (Dart puro)
  domain/
    shared/                      # Money, Percentage, YearMonth, DateRange, TrafficLight, Clock, IdGenerator
    categories/ accounts/ transactions/ budgets/
    cycles/                      # PayCycle, PayCycleResolver, DailySpendingCap
    fixed/                       # FixedMovement, FixedMovementScheduler, VariableBillEstimator
    provisions/                  # Provision (pagos del año), ProvisionPlanner
    wealth/ debts/ investments/ savings/
    insights/                    # CashFlowCalculator, SpendingInsightsAnalyzer
    markets/ voice/ wisdom/      # watchlist, parser de voz, frases
  application/
    common/                      # guardUseCase, ValidationCodes, cleanText
    dashboard/                   # CycleSummary, CyclePulse, SpendingRadar, DailySpending, HomeSummary
    backup/                      # ports BackupStore/BackupFiles + ExportBackup/ImportBackup
    categories/ cycles/ fixed/ provisions/ transactions/ budgets/ debts/ savings/ wealth/
    advisor/ insights/ markets/ reminders/ settings/ voice/
  infrastructure/
    persistence/drift/           # AppDatabase (migraciones v1→v8), tablas
    repositories/                # Drift<X>Repository implements <X>Repository + storage_guard
    mappers/                     # fila drift ↔ entidad
    backup/                      # DriftBackupStore (JSON), AndroidBackupFiles (canal nativo)
    notifications/ speech/ markets/ system/
  presentation/
    app/                         # FinanceApp, AppTheme, AppShell (barra de iconos + FAB voz/+)
    shared/                      # data_providers, formatters, CategoryStyle, DonutChart, form_widgets…
    home/ transactions/ quick_entry/ days/ budgets/ wealth/ debts/ goals/ provisions/ fixed/
    categories/ cfo/ insights/ settings/
android/app/src/main/
  kotlin/.../MainActivity.kt     # canales nativos (dictado, archivos de respaldo)
  res/                           # icono adaptativo Roka (drawable + mipmap-anydpi-v26) y PNG legados
test/                            # espejo de lib/ + architecture_test.dart + support/
docs/
```

### Regla de dependencias

```text
presentation ──▶ application ──▶ domain ◀── infrastructure
      ▲                                        │
      └──────────── bootstrap ─────────────────┘   (único que conoce adapters concretos)
```

- `domain`: Dart puro. Entidades, VOs, ports, servicios de cálculo. Sin I/O.
- `application`: orquesta ports + servicios. Clases planas con `call()`. Sin Riverpod.
- `infrastructure`: implementa ports. drift solo aquí.
- `presentation`: lecturas con `StreamProvider`/`FutureProvider` en `shared/data_providers.dart`
  (observan ports y componen builders de `application/dashboard`); escrituras llamando casos de uso
  de `bootstrap/use_cases.dart`. Los widgets solo pintan y traducen `Failure` a texto.

### Ports & Adapters (ejemplo)

```dart
// domain/transactions/transaction_repository.dart
abstract interface class TransactionRepository {
  Future<void> save(Transaction transaction);
  Future<void> delete(TransactionId id);
  Future<List<Transaction>> getByPeriod(DateRange period);
  Stream<List<Transaction>> watchByPeriod(DateRange period);
  Future<List<Transaction>> getRecent({required int limit});
}

// infrastructure/repositories/drift_transaction_repository.dart
final class DriftTransactionRepository implements TransactionRepository { ... }

// futuro: infrastructure/repositories/cloud_transaction_repository.dart
```

### Errores
`Result<T>` sealed (`Ok` / `Err(Failure)`). `Failure` sealed: `ValidationFailure`,
`NotFoundFailure`, `StorageFailure`. Los ports son simples (`Future`/`Stream`): los adapters
traducen excepciones de drift a `StorageException` (core), cuyo `toString` no incluye la causa
(SQL/valores). Los casos de uso capturan `StorageException` y devuelven `Err(StorageFailure)`.

### Dinero e intereses
- `Money`: `int` en centavos, moneda única COP en v1. Suma/resta exactas; redondeo *half-up* solo al
  convertir desde cálculos con tasas.
- `InterestRate`: valor + tipo (`effectiveAnnual` EA, `nominalAnnualMonthly` NMV, `effectiveMonthly` EM).
  Todo se normaliza a tasa efectiva mensual: `EM = (1 + EA)^(1/12) − 1`; `EM = NMV / 12`.
- Amortización francesa (cuota fija). Seguros/comisiones = cargo mensual fijo que no abona a capital.

### Navegación
`AppShell`: barra inferior flotante con **5 destinos con icono y nombre** (Inicio · Movimientos
· Plan · Patrimonio · Tu CFO) en un `IndexedStack`; Plan = pestañas Presupuesto | Metas. Atrás
desde otra sección vuelve a Inicio. Botones de voz y `+` en todas las secciones. AppBar: modo
claro/oscuro, Análisis, Ajustes. Ajustes es una hoja inferior con: día de pago, avisos, Tu CFO
con IA, mi hogar, cuadre, fijos, categorías, pagos del año, copia de seguridad y reiniciar mes.

Al abrir/volver a la app: registra fijos vencidos, reprograma avisos (con las alertas por
reglas), guarda la foto mensual del patrimonio (`RecordNetWorth`) y, si toca, corre la revisión
periódica de la IA (`RunAiReview.isDue`) y muestra su resultado como notificación.

### Tu CFO con IA (opt-in)
- **Reglas primero**: dinero libre (`MoneyOverviewBuilder`), reservas de fijos
  (`FixedCoverageCalculator`), alertas (`FinancialAlertsBuilder`) y reparto de extraordinarios
  (`WindfallPlanner`) son deterministas, sin red y con tests. La IA solo interpreta.
- **Ports** (`application/advisor/ai_ports.dart`): `AiAdvisor` (adapter `GroqAiAdvisor`,
  `dart:io` HTTP, modelo `openai/gpt-oss-120b`, JSON mode) y `AiKeyStore` (adapter
  `DriftAiKeyStore`). Revisiones: port de dominio `AiReviewRepository` (tabla `ai_reviews`,
  últimas 12).
- **Qué sale del teléfono**: solo `FinancialSnapshot` (totales por categoría, fijos, apartados,
  deudas con tasa, bienes por tipo, metas, patrimonio, precios de la lista si se pidieron y las
  alertas). Sin descripciones, notas, movimientos individuales ni nombres escritos por el
  usuario (deudas = "Deuda 1 (tipo)"). Visible en Ajustes › Tu CFO con IA antes de activar.
- **Llave**: la pega el usuario; vive en la tabla `ai_secrets` (base privada de la app). No está
  en el código/APK, no va en la copia de seguridad y nunca se loguea.
- **Periodicidad real**: diaria/semanal/mensual, evaluada al abrir la app (Android no garantiza
  tareas en segundo plano). Las alertas por reglas sí se programan como notificación local
  (resumen a las 8 p. m. y facturas vencidas a las 9 a. m.).
- Nada modifica datos sin confirmación: el reparto de un extraordinario se aplica solo con las
  partes que el usuario marca (`ApplyWindfallSlices`).

### Esquema v11 (todo nulo: los backups v8–v10 importan igual)
- `transactions.odometer_km`: kilometraje al tanquear. `FuelEconomyCalculator` (dominio) ordena
  por fecha, ignora lecturas que no avanzan y usa tanque lleno: lo pagado en una tanqueada
  repone lo recorrido desde la anterior ⇒ costo por km, por 100 km y del último tramo.
- `investments.invested_usd_cents`: lo pagado en dólares; `investedAmount` queda en pesos con el
  dólar que confirmó el usuario (`UsdRate.toPesos`, enteros). `LoadUsdRate` solo pide `COP=X`
  cuando el usuario elige "En dólares". `InvestmentMarketView.usdReturn` = rentabilidad en US$.
- `fixed_movements.debt_id` (sin FK, ref `debts` en el backup): `PostDueFixedMovements` y
  `ConfirmVariableFixed` marcan el movimiento con `debtId` y llaman `payLinkedDebt`
  (`Debt.afterInstallment`: baja solo capital, suma cuota). `LinkDebtToFixed` enlaza uno existente
  o crea "Cuota X" sin registrar el ciclo actual. `ReminderPlanner` recibe las deudas y agrega
  "te quedan N cuotas y $Y de saldo" al aviso del fijo.
- `DebtOverview.recorded` (`RecordedSchedule`): cuota × cuotas de tu registro, intereses
  implícitos y `LoanProjector.impliedMonthlyRate` (bisección) para explicar por qué el cálculo
  por saldo/tasa no da las mismas cuotas que el extracto.

### Análisis por categoría y autocompletar
- `CategoryReportBuilder` (application/insights): 12 meses calendario, mes pico, promedio de meses
  cerrados, ítems agrupados por descripción normalizada (`DescriptionSuggestions.normalize`).
  Entradas: hoja de categoría en Inicio, Análisis › Gasto por categoría, Categorías, vista previa.
- `DescriptionSuggestions`: prefijo o palabra, sin tildes; orden prefijo → veces → reciente.

### Inversiones con precio real
- `Investment.symbol` + `unitsMicros` (millonésimas, permite fracciones) + `priceUpdatedAt`
  (esquema v10). Sin símbolo, el valor se escribe a mano como antes.
- `RefreshInvestmentPrices` (application/markets): por cada inversión con símbolo consulta el
  precio (port `MarketDataSource`, Yahoo) y la tasa a pesos (`COP=X`, `EURCOP=X`…), guarda el
  valor en pesos (patrimonio con rentabilidad real) y arma `InvestmentMarketView` con
  `QuoteStats`, `QuarterOutlook` (dominio, puro) y señales (`concentrated`, `volatile`,
  `farFromHigh`, `downTrend`, `upTrend`).
- `QuarterOutlookCalculator`: retornos semanales logarítmicos del último año → tendencia típica a
  13 semanas, rango ±1 desviación ("2 de cada 3") y peor/mejor trimestre. Es estadística del
  pasado; la UI lo dice así y nunca lo presenta como predicción ni recomendación.
- Se consulta al abrir Patrimonio (una vez por sesión, `investmentPricesRequestProvider`) solo si
  hay inversiones con símbolo, y con el botón de actualizar. Solo viajan símbolos.

### Dinero libre, tope diario y apartar
- `CycleSummary.plannedReserve` (presupuesto del mes por gastar + colchón de los niños) se
  descuenta igual en `MoneyOverview.free` y en `DailySpendingCap`: "libre" y "hoy puedes gastar"
  salen del mismo número.
- `MoneyOverview.provisionsSaved` / `provisionsToday`: lo ya apartado para pagos del año (salió
  de "Tienes") y la cuota de hoy, visibles en el Home.
- `SetAsidePlanner` → `SetAsidePlan`: pagos del año pendientes del ciclo y luego metas (fondo de
  emergencia primero) con máximo el 50% de lo libre. `ApplySetAside` usa `SetAsideForProvision`
  y `ApplyWindfallSlices`; solo aplica lo que el usuario marca.

### Fijos por estado y movimientos
- `FixedCycleStatusBuilder` (application/fixed): cada fijo como pagado / recibido / por pagar
  (con su cobertura) / vencido / pausado / no le toca. La pantalla de fijos los agrupa y colorea
  (verde pagado, ámbar por pagar, rojo sin plata), siempre con icono y texto.
- Tocar un movimiento abre `TransactionPreviewSheet` (solo lectura: monto, fecha, categoría,
  vínculo, notas); Editar abre el formulario de siempre.

### Canales nativos (Android, `MainActivity.kt`)
Se prefiere un canal pequeño a un paquete grande cuando la necesidad es puntual.

| Canal | Métodos | Uso |
|---|---|---|
| `finance_app/dictation` | `recognize`, `diagnose` | Ventana de dictado de Google como respaldo de `speech_to_text` |
| `finance_app/backup` | `save(fileName, content)` → bool, `open()` → String? | Selector de archivos (SAF: `ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`); E/S en hilo aparte |

Cancelar devuelve `false`/`null`; errores como `PlatformException` → el adapter los convierte
en `StorageException`.

### Copia de seguridad (exportar / importar)
**Formato: JSON**, no CSV: los datos están enlazados (movimiento→fijo/deuda/apartado/categoría,
abono→deuda, aporte→meta) y un CSV por tabla pierde esas relaciones. Un solo archivo
`finanzas-copia-AAAA-MM-DD.json`:

```json
{ "app": "finance_app", "format": 1, "schemaVersion": 11, "exportedAt": "…",
  "data": { "categories": [...], "accounts": [...], "debts": [...], "savingsGoals": [...],
            "fixedMovements": [...], "provisions": [...], "transactions": [...],
            "budgetLines": [...], "assets": [...], "extraPayments": [...],
            "goalContributions": [...], "investments": [...], "netWorthSnapshots": [...],
            "settings": {...} } }
```

Filas = `toJson()` de drift (campos camelCase, montos en centavos, fechas en ms epoch).
`DriftBackupStore` es infraestructura a propósito: serializa filas, no entidades, para no
mantener un segundo mapper por tabla. Reglas de importación (una transacción, todo o nada):
1. Mismo id ⇒ se omite.
2. Si no, **clave natural** por tabla (p. ej. movimiento = tipo + valor + día + categoría +
   descripción; fijo = nombre + tipo + categoría). Coincide ⇒ se omite y el id de la copia se
   **remapea** al local, para que los registros que lo referencian (`refs`) apunten bien.
   Las coincidencias se consumen una a una (2 cafés iguales en la copia y 1 local ⇒ entra 1).
3. Lo demás se inserta (`insertOrIgnore`: choques con claves únicas cuentan como omitidos).
4. Ajustes: se reemplazan por los de la copia; los campos que la copia no trae (p. ej. los de IA
   en una copia v8) conservan el valor del teléfono.
5. **Copias viejas**: columnas nuevas no nulas sin dato toman `_Section.defaults`
   (`test/fixtures/backup_v8.json` lo verifica). No se exportan `ai_secrets` (secreto) ni
   `ai_reviews` (derivadas).

Orden de secciones = orden de llaves foráneas. Archivo ajeno, dañado (campos faltantes, enums
desconocidos) o de versión más nueva ⇒ `InvalidBackupException` ⇒ `ValidationFailure`
(`backupInvalid` / `backupFromNewerVersion`).

## Dependencias (verificadas en pub.dev el 2026-10-02, compatibles con Dart 3.13.4)

| Paquete | Versión | Capa | Motivo |
|---|---|---|---|
| `drift` + `drift_flutter` | 2.35.1 / 0.3.1 | infra | SQLite tipado, migraciones, `watch` reactivo, tests en memoria |
| `drift_dev` + `build_runner` (dev) | 2.35.1 / 2.16.1 | infra | codegen de drift |
| `flutter_riverpod` | 3.4.3 | presentation/bootstrap | estado + DI en uno; evita `get_it` redundante |
| `intl` + `flutter_localizations` (SDK) | 0.20.3 | presentation | formato COP / fechas es-CO |
| `uuid` | 4.6.0 | infra | IDs portables a cloud |
| `flutter_local_notifications` + `timezone` + `flutter_timezone` | ^22.3.1 / ^0.11.1 / ^5.1.1 | infra | Recordatorio diario y avisos inteligentes programados |
| `speech_to_text` | ^7.5.0 | infra | Dictado en el dispositivo (`onDevice`) |
| `very_good_analysis` (dev) | 11.0.0 | — | lints estrictos (sustituye `flutter_lints`) |

Descartados / diferidos:
- `sqflite`: SQL a mano, sin tipado ni `watch`; drift lo cubre mejor. `sqlite3_flutter_libs` está EOL
  (drift actual empaqueta SQLite vía build hooks).
- `get_it`: Riverpod ya hace DI. `go_router`: `Navigator` + `NavigationBar` bastan en v1.
- `decimal`: `Money` en enteros es suficiente. `mocktail`: preferimos fakes en memoria.
- `fl_chart`: descartado. Dona, barras diarias y araña se dibujan con `CustomPainter` propio.
- `file_picker`/`share_plus`: descartados para el respaldo; basta el canal SAF nativo.
- Sin riverpod_generator/freezed: menos codegen; `copyWith` manual en entidades pequeñas.

## Herramientas Claude Code del proyecto
- `.mcp.json`: servidor MCP oficial de Dart/Flutter (`dart mcp-server`, incluido en el SDK):
  análisis, tests, pub.dev, hot reload, errores runtime, widget inspector.
- Skills existentes útiles: `/code-review`, `/simplify`, `/security-review` (privacidad de datos).
  No hay skill Flutter instalada; no se inventa ninguna.
- `.claude/settings.json`: permisos solo para comandos flutter/dart de este proyecto.
