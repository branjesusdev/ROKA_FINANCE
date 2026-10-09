# Roadmap por fases

Estado 2026-10-08: fases 1–12f implementadas (esquema drift v8, ~220 tests). Pendiente: Fase 13
(revisión, refactor, `/security-review`) y prueba completa en el teléfono. Gráficas con
`CustomPainter` propio (sin fl_chart).

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
| 12c ✅ | Pagos del año (apartados): gimnasio trimestral, SOAT, tecnomecánica, colegio… Cuota por ciclo y por día, semáforo de atraso, "Ya lo pagué" usa lo apartado; se protege del tope diario | Esquema v5 con migración; tests de planificador, casos de uso y migración |
| 12d ✅ | Ciclo marcado por el sueldo real, tope diario, fijos variables (facturas), cuadre con dinero real, reiniciar mes, "Así vas este ciclo", gasto por día (barras) e histórico de ciclos, Tu CFO, "Mi hogar" (personas a cargo), avisos inteligentes, voz con respaldo de Google, modo claro/oscuro | Esquema v6–v8; tests de resolver, tope, cuadre, reinicio y pulso |
| 12e ✅ | Copia de seguridad: exportar/importar JSON completo vía selector de Android, fusión sin duplicar (id + clave natural + remapeo de vínculos), todo o nada | Tests de `DriftBackupStore` en memoria y de casos de uso |
| 12f ✅ | Categorías propias (crear, renombrar, icono, ocultar; "+ Nueva" en el registro), lista compacta de categorías con detalle de movimientos al tocar, "Tu huella de gasto" (araña), paleta verde bosque + lima, marca e icono **Roka** | Tests de casos de uso de categorías y de `SpendingRadarBuilder`; `flutter build apk` |
| 13 | Testing, refactor, `/code-review`, `/security-review` | Sin warnings, sin logs con datos |

Futuro (fuera de v1): bloqueo con biometría / cifrado de DB (SQLCipher) y de la copia de
seguridad, recordatorio de hacer copia, exportar movimientos a CSV para hojas de cálculo (solo
lectura), saldo automático por cuenta, multi-moneda, adapter cloud.
