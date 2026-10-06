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
  bootstrap/                     # composition root: providers que conectan adapters → ports
  core/                          # Result, Failure, utilidades Dart puras
  domain/
    shared/                      # Money, Percentage, YearMonth, DateRange, TrafficLight, Clock, IdGenerator
    categories/  accounts/  transactions/  budgets/
    wealth/                      # Asset (activos)
    debts/                       # Debt, InterestRate, LoanProjector
    savings/                     # SavingsGoal, EmergencyFund, FinanceSettings
    investments/
    insights/                    # análisis de gasto, métricas de salud financiera
  application/
    <modulo>/                    # un archivo por caso de uso + read models (dto)
  infrastructure/
    persistence/drift/           # AppDatabase, tablas, migraciones, DAOs
    repositories/                # Drift<X>Repository implements <X>Repository
    mappers/                     # fila drift ↔ entidad
    system/                      # SystemClock, UuidIdGenerator
  presentation/
    app/                         # MaterialApp, tema, navegación (NavigationBar)
    shared/                      # MoneyText, TrafficLightBadge, formatters intl
    home/ transactions/ quick_expense/ budgets/ wealth/ debts/ savings/ investments/ insights/ settings/
      screens/ widgets/ controllers/
test/                            # espejo de lib/ + architecture_test.dart
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
- `presentation`: Riverpod `Notifier`/`AsyncNotifier` llaman casos de uso; widgets solo pintan.

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

## Dependencias (verificadas en pub.dev el 2026-10-02, compatibles con Dart 3.13.4)

| Paquete | Versión | Capa | Motivo |
|---|---|---|---|
| `drift` + `drift_flutter` | 2.35.1 / 0.3.1 | infra | SQLite tipado, migraciones, `watch` reactivo, tests en memoria |
| `drift_dev` + `build_runner` (dev) | 2.35.1 / 2.16.1 | infra | codegen de drift |
| `flutter_riverpod` | 3.4.3 | presentation/bootstrap | estado + DI en uno; evita `get_it` redundante |
| `intl` + `flutter_localizations` (SDK) | 0.20.3 | presentation | formato COP / fechas es-CO |
| `uuid` | 4.6.0 | infra | IDs portables a cloud |
| `very_good_analysis` (dev) | 11.0.0 | — | lints estrictos (sustituye `flutter_lints`) |

Descartados / diferidos:
- `sqflite`: SQL a mano, sin tipado ni `watch`; drift lo cubre mejor. `sqlite3_flutter_libs` está EOL
  (drift actual empaqueta SQLite vía build hooks).
- `get_it`: Riverpod ya hace DI. `go_router`: `Navigator` + `NavigationBar` bastan en v1.
- `decimal`: `Money` en enteros es suficiente. `mocktail`: preferimos fakes en memoria.
- `fl_chart` (1.2.0): se decide en Fase 12; si barras/donut simples bastan, se dibujan con widgets.
- Sin riverpod_generator/freezed: menos codegen; `copyWith` manual en entidades pequeñas.

## Herramientas Claude Code del proyecto
- `.mcp.json`: servidor MCP oficial de Dart/Flutter (`dart mcp-server`, incluido en el SDK):
  análisis, tests, pub.dev, hot reload, errores runtime, widget inspector.
- Skills existentes útiles: `/code-review`, `/simplify`, `/security-review` (privacidad de datos).
  No hay skill Flutter instalada; no se inventa ninguna.
- `.claude/settings.json`: permisos solo para comandos flutter/dart de este proyecto.
