# Roadmap por fases

Estado 2026-10-02: fases 1–12 implementadas (92 tests). Pendiente: Fase 13 (revisión, refactor,
prueba en el teléfono). Torta de gastos con `CustomPainter` propio (sin fl_chart).

Cada fase termina con `flutter analyze` limpio + `flutter test` verde + resumen de cambios.

| Fase | Entregable | Criterio de cierre |
|---|---|---|
| 1 ✅ | Análisis, arquitectura, modelo, CLAUDE.md, proyecto creado | Aprobación del usuario |
| 2 ✅ | Dependencias, very_good_analysis, estructura de carpetas, `Result`/`Failure`, bootstrap Riverpod, tema, `architecture_test` | App arranca en el teléfono con Home vacío |
| 3 ✅ | Dominio: VOs, entidades, ports, servicios de cálculo | Tests de patrimonio, ahorro, presupuesto, semáforo, tasas, proyección de crédito, variaciones |
| 4 ✅ | Persistencia drift: tablas, migración v1, mappers, repositorios, semillas | Tests de repos con DB en memoria |
| 5 ✅ | Casos de uso | Tests de aplicación con fakes |
| 6 ✅ | Home: patrimonio, mes (ingresos/gastos/ahorro), semáforo, últimos gastos, deudas, meta | Datos reales vía casos de uso |
| 7 ✅ | Registro rápido de gasto + ingreso + lista de movimientos | Gasto en < 5 s |
| 8 ✅ | Presupuestos mensuales + copiar mes anterior | Alertas por categoría |
| 9 ✅ | Activos y pasivos | Patrimonio neto correcto |
| 10 ✅ | Créditos: detalle, pagos, abonos, proyección, simulador | Tests de proyección y simulación |
| 11 ✅ | Metas, fondo de emergencia, regla de ahorro configurable, inversiones | Progreso y faltantes |
| 12 ✅ | Análisis de gasto y salud financiera (fugas, variaciones, desglose) | Insights descriptivos |
| 12b ✅ | Home por ciclo de sueldo (día 20), barra de iconos, colores por categoría, fijos mensuales automáticos, registro por voz (en el dispositivo), recordatorio diario 6 p. m. | Esquema v2 con migración; tests de ciclo, fijos, voz y migración |
| 13 | Testing, refactor, `/code-review`, `/security-review` | Sin warnings, sin logs con datos |

Futuro (fuera de v1): exportar/importar backup local, bloqueo con biometría / cifrado de DB
(SQLCipher), saldo automático por cuenta, multi-moneda, adapter cloud.
