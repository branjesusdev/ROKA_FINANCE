# Diseño visual — Roka

## Marca
- Nombre visible: **Roka** (`android:label`, `MaterialApp.title`). El paquete, el applicationId y
  los canales nativos siguen como `finance_app` (cambiarlos rompería la instalación existente).
- Idea: una roca (solidez, base firme) con una línea que sube (crecimiento).

## Paleta "verde bosque + lima"
Medida en la referencia del usuario (`verde_oscuro.png`, muestreo de píxeles): el verde base es
`#102521` (el usuario lo estimó como `#102520`).

| Token (`AppTheme`) | Color | Uso |
|---|---|---|
| `forest` / `ink` | `#102521` | Barra inferior, botón +, texto principal y `primary` en claro, fondo del icono |
| `accent` | `#B3DD62` | Opción activa (Gastos/Ingresos), micrófono, icono seleccionado de la barra, `primary` en oscuro |
| `onAccent` | `#102521` | Texto/icono sobre lima |
| fondo claro | `#EAEEED` | `scaffoldBackgroundColor` en claro; tarjetas blancas encima |
| `_darkBackground` | `#0A0D0C` | Fondo en oscuro (casi negro neutro: con fondo verde las tarjetas se perdían) |
| `_darkCard` | `#17221F` | Tarjetas en oscuro (+ borde `_darkOutline` `#2E3D39`) |
| `_darkRaised` / `inkOnDark` | `#1C2925` | Barra inferior en oscuro |
| `_darkHigh` | `#22302C` | Contenedores altos en oscuro |
| `_darkText` / `_darkMuted` | `#ECF3EF` / `#B8C6C1` | Texto y texto secundario en oscuro (≥ 7:1, AAA) |
| `inkMuted` | `#A9BAB4` | Iconos inactivos de la barra (≥ 7:1 sobre la barra oscura) |

En oscuro todo texto cumple WCAG AAA (≥ 7:1) sobre fondo, tarjeta y barra; el rojo de alerta
pasa a `#FCA5A5`.
| contenedor lima | `#E6F4C8` | `primaryContainer` / `secondaryContainer` en claro |

Reglas:
- Sin rosados ni morados (el esquema tonal de Material los genera: se sobrescriben en `AppTheme`).
- Rojo solo para alertas y para "subió" en comparaciones; verde `TransactionTile.incomeColor`
  para ingresos y "bajó".
- Nunca solo color: siempre icono + texto (+ % cuando aplica).
- Tarjetas sin elevación, radio 24. La barra inferior es flotante, en forma de píldora.

## Categorías
`CategoryStyle` traduce `iconKey` → icono + color. Los colores identifican la categoría en la dona,
las listas, la araña y los chips. `choosableKeys` = iconos que el usuario puede elegir al crear una
categoría (excluye los reservados: deudas, inversiones, apartados y los del cuadre).

## Gráficas (CustomPainter propio)
- Dona de categorías (`DonutChart`).
- Barras de gasto por día (`DailyBarChart`), con la línea del tope diario.
- Araña "Tu huella de gasto" (`SpendingRadarChart`): ciclo actual en línea sólida con relleno
  (`forest` en claro, `accent` en oscuro) y ciclo pasado en línea punteada gris; misma escala
  para ambos. Leyenda con icono + texto y `Semantics` con los valores por eje.

## Icono de la app
- Adaptativo (Android 8+): `res/mipmap-anydpi-v26/ic_launcher.xml` con fondo
  `@color/ic_launcher_background` (`#102521`) y frente vectorial `res/drawable/ic_launcher_foreground.xml`
  (lienzo 108, dentro de la zona segura de 66).
- Frente: roca facetada en tres tonos de lima (`#D4F08F` luz, `#B3DD62` medio, `#8CBF3F` sombra)
  con una línea de tendencia que sube y termina en flecha, en `#102521`.
- PNG legados (`mipmap-*/ic_launcher.png`, 48–192 px) generados con el mismo trazo en un
  cuadrado redondeado. Si se cambia el vector, regenerarlos con la misma geometría.
- Sin capa `monochrome`: la línea se perdería al teñir el icono con el tema del sistema.

## Revisión 2026-10-12: por qué el diseño anterior no convencía

Diagnóstico de `ui-ux-pro-max` (plugin v2.11.0, `--design-system "personal finance budgeting
mobile app trust clarity"`): propone una **landing de App Store**, paleta **azul genérica**
(#1E40AF) y un checklist **web** (hover, `cursor-pointer`, breakpoints 1440 px). Aplicado tal
cual a una app Flutter móvil con marca propia da un resultado genérico: por eso "no
convencía". Se tomó solo lo que aplica a este producto:
- Navegación inferior **≤ 5 destinos y con nombre** (antes: 6 iconos sin texto).
- Nada de botones solo con icono sin etiqueta; objetivos táctiles ≥ 48 px.
- Jerarquía: un número protagonista por pantalla; contraste AA/AAA; color + icono + texto.
Se descartó: paleta azul, landing, hover/cursor, fuentes externas (Lexend) — la marca verde
bosque + lima se mantiene.

Problemas concretos encontrados en la app:
1. El Home mostraba "Te queda" (saldo) como número principal: se confundía con dinero libre.
2. 15 tarjetas del mismo peso visual: nada indicaba qué hacer primero.
3. Barra de 6 iconos sin nombre (Presupuesto/Metas/Patrimonio se confundían).
4. Fijos sin estado (¿alcanza o no?), alertas dispersas en Tu CFO.

## Dirección visual "claridad accionable"
- **Tarjeta héroe** (`MoneyHeroCard`): fondo `forest` (en oscuro `surfaceContainerHighest`),
  número en lima = **Libre para gastar hasta tu sueldo**; debajo, barra apilada
  disponible = fijos + pagos del año + ahorro + libre (colores `#7FB3A5`, `#E2C46B`,
  `#6FA8DC`, lima) con leyenda en texto, y el tope de hoy. Montos con cifras tabulares.
- **Orden del Home** (responde las preguntas en orden): héroe → facturas por confirmar →
  **Qué hacer ahora** (IA + alertas) → **Próximos pagos** con estado y barra de reserva →
  pagos del año → gastos/ingresos por categoría → gasto por día → patrimonio y metas → araña →
  pulso.
- **Estados** (`status_style.dart`): `StatusChip` = icono + texto sobre fondo al 12 %.
  Urgente = rojo (`error`), Atención = ámbar `#B45309`/`#FCD34D`, Oportunidad = verde azulado
  `#2F6B5E`/`#9FD4C4`, Logro/Cubierto = verde `#15803D`/`#86EFAC`.
- **Navegación**: píldora oscura de 68 px con 5 destinos (icono + nombre), indicador lima.
- Gráfica nueva: evolución del patrimonio (`NetWorthHistoryCard`, línea con relleno suave y
  `Semantics` con inicio/fin).
