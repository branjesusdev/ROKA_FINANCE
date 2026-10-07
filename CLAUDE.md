# finance_app — Finanzas personales offline-first

App Flutter (Android, teléfono físico) 100% local: ingresos, gastos, presupuestos, patrimonio,
créditos, metas de ahorro, inversiones y análisis descriptivo. Sin login, sin backend, sin cloud.
Prioridad: claridad > features · UX > complejidad · arquitectura mantenible > velocidad.

## Stack
Flutter 3.47 / Dart 3.13 · drift (SQLite) · flutter_riverpod 3 (estado + DI) · intl · very_good_analysis.
Detalle y justificación: `docs/architecture.md`. Modelo: `docs/domain-model.md`. Fases: `docs/roadmap.md`.

## Arquitectura hexagonal (layer-first, módulos dentro de cada capa)
- `lib/domain/<modulo>/` entidades, value objects, ports (interfaces repositorio), servicios puros.
- `lib/application/<modulo>/` casos de uso + read models. Solo depende de domain.
- `lib/infrastructure/` adapters: drift (tablas, DAOs), repositorios, mappers, reloj, ids.
- `lib/presentation/<feature>/` screens/widgets. Lecturas: `shared/data_providers.dart` (observa ports);
  escrituras: casos de uso vía `bootstrap/use_cases.dart`. Nunca importar infrastructure.
- `lib/bootstrap/` composition root: único lugar que conecta adapters con ports.
- `domain/` y `application/` = Dart puro: PROHIBIDO importar flutter, drift, riverpod, intl.
  `test/architecture_test.dart` lo verifica.

## Reglas
- Dinero = `Money` (int en centavos, COP). Nunca `double` para montos. Tasas: `InterestRate`.
- Entidades `@immutable` (meta). Adapters lanzan `StorageException`; casos de uso devuelven `Result<T>`/`Failure`.
- Cero lógica financiera en widgets/controllers: va en servicios de dominio o casos de uso.
- Entidades de dominio ≠ filas drift: siempre mapper en infrastructure.
- Ports devuelven tipos de dominio; `watch*()` como `Stream` para UI reactiva.
- IDs String (UUID v4) generados vía port `IdGenerator` → listos para sincronizar en cloud.
- Fechas vía port `Clock` (testeable). Sin magic numbers: umbrales en `FinanceSettings`.
- Widgets pequeños y `const`; constructores con sintaxis `const new(...)` (Dart 3.13, lint activo).
- UI en español simple, sin jerga. Semáforo: siempre color + icono + texto + % (accesibilidad).
- Insights descriptivos basados en datos del usuario; nunca presentarlos como asesoría financiera.

## Futuro cloud
Nuevo adapter (`CloudXRepository`) que implemente el mismo port + cambio en `bootstrap/`.
Dominio y casos de uso no cambian. No añadir dependencias cloud/analytics/ads.

## Privacidad
Nunca loguear montos, descripciones ni registros completos. Nada sale del dispositivo.
Única excepción: precios públicos de acciones ("Tu CFO") vía port `MarketDataSource`
(Yahoo, gratis, sin clave): solo envía el símbolo y solo cuando el usuario lo pide.
Notificaciones con montos: `NotificationVisibility.private` (ocultas en pantalla bloqueada).

## Testing
Prioridad: servicios de dominio y casos de uso (fakes en memoria, sin mocks salvo necesidad).
Repos drift: tests con `NativeDatabase.memory()`. Nada de tests solo por cobertura.

## Comandos
`flutter pub get` · `dart run build_runner build` (codegen drift) · `dart format .`
`flutter analyze` · `flutter test` · `flutter devices` · `flutter run -d <id-telefono>`

## Flujo de trabajo
Inspeccionar → explicar cambio → implementar → analyze → tests → corregir → resumir.
Verificar versión en pub.dev antes de añadir paquete (`flutter pub add`). No editar código generado (`*.g.dart`).
