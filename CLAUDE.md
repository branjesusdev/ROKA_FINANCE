# Roka — Finanzas personales offline-first (paquete `finance_app`)

App Flutter (Android, teléfono físico) 100% local para una persona que vive de su sueldo:
"¿cuánto me queda hasta el próximo pago y en qué se me va?". Ingresos, gastos, fijos,
presupuestos, apartados, patrimonio, créditos, metas, inversiones y análisis descriptivo.
Sin login, sin backend, sin cloud. Nombre visible: **Roka** (paquete/IDs siguen `finance_app`).
Prioridad: claridad > features · UX > complejidad · arquitectura mantenible > velocidad.

## Stack
Flutter 3.47 / Dart 3.13 · drift (SQLite, esquema v8) · flutter_riverpod 3 (estado + DI) · intl ·
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
- **"Te queda"**: ingresos − gastos − fijos pendientes del ciclo (Home, `CycleSummaryBuilder`).
- **Día a día** (`CycleSummaryBuilder.isDayToDay`): gasto que no es ahorro ni planeado del mes.
  **Tope diario** (`DailySpendingCap`) reparte lo que queda entre los días que faltan.
- **Fijos** (`FixedMovement`): se registran solos al vencer (`PostDueFixedMovements` al abrir/reanudar).
  Variables (agua, luz) esperan el valor real; estimado = `VariableBillEstimator`.
- **Apartados / Pagos del año** (`Provision`): SOAT, colegio… se reparte la cuota por ciclo.
- **Cuadrar con mi dinero real** (`ReconcileBalance`): diferencia → categorías archivadas
  "Gastos sin registrar" / "Saldo inicial / ajuste".
- **Reiniciar mes** (`ResetCycleMovements`): borra lo anotado a mano en el ciclo (con deshacer).
- **Así vas este ciclo** (`CyclePulse`) y **Tu huella de gasto** (`SpendingRadar`, araña: este ciclo vs
  el pasado a la misma altura, por categoría y por día de la semana; solo gasto variable).
- **Tu CFO** (`CfoBrief`): consejos accionables + precios públicos de acciones (opt-in).
- **Copia de seguridad** (`ExportBackup`/`ImportBackup`): JSON completo; importar fusiona sin duplicar.

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
- Colores desde `AppTheme`/`ColorScheme` (paleta verde bosque `#102521` + lima `#B3DD62`).
  Sin rosados ni morados; rojo solo para alertas. Categorías: `CategoryStyle` (icono + color por `iconKey`).

## Checklist al cambiar el esquema drift
1. Columna/tabla en `tables.dart` + subir `schemaVersion` + paso en `onUpgrade` (`app_database.dart`).
2. `dart run build_runner build`. Test en `test/infrastructure/persistence/migration_test.dart`.
3. Tabla nueva ⇒ añadir sección en `DriftBackupStore._sections` (clave natural + `refs` de ids)
   o no se exportará. Columna con default ⇒ los backups viejos siguen importando.

## Futuro cloud
Nuevo adapter (`CloudXRepository`) que implemente el mismo port + cambio en `bootstrap/`.
Dominio y casos de uso no cambian. No añadir dependencias cloud/analytics/ads.

## Privacidad
Nunca loguear montos, descripciones ni registros completos. Nada sale del dispositivo.
Única excepción: precios públicos de acciones ("Tu CFO") vía port `MarketDataSource`
(Yahoo, gratis, sin clave): solo envía el símbolo y solo cuando el usuario lo pide.
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
