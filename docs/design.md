# Diseño visual — Roka

## Marca
- Nombre visible: **Roka** (`android:label`, `MaterialApp.title`). El paquete, el applicationId y
  los canales nativos siguen como `finance_app` (cambiarlos rompería la instalación existente).
- Idea: una roca (solidez, base firme) con una línea que sube (crecimiento).

## Paleta "Roka Neo" (2026-10-20)
Reemplaza a "verde bosque + lima": el usuario pidió algo futurista, vivo como Spotify y con el
orden y contraste de Apple. Base neutra casi negra (sin tinte verde), un acento lima eléctrico
y apoyos vívidos que solo van en rellenos, gráficas y brillos (nunca como texto sobre claro).

| Token (`AppTheme`) | Color | Uso |
|---|---|---|
| `ink` | `#0A0B0D` | Texto y `primary` en claro, barra inferior, segmento elegido en claro |
| `accent` | `#C6FF3D` | Lima eléctrico: lo activo, número protagonista, `primary` y FAB |
| `onAccent` | `#0A0B0D` | Texto/icono sobre lima |
| `cyan` `blue` `orange` `sun` `mint` `sky` | `#22D3EE` `#3B82F6` `#FB923C` `#FBBF24` `#34D399` `#7DD3FC` | Brillos del arte del día, barra apilada del saldo, gráficas |
| `heroBase` → `heroBaseEnd` | `#0E1013` → `#16191D` | Base de las tarjetas protagonistas (siempre oscuras) |
| `onHero` / `onHeroMuted` | `#FFFFFF` / `#E1E6EA` | Texto sobre tarjetas protagonistas |
| fondo claro | `#F2F3F5` | Lista agrupada estilo Apple; tarjetas blancas sin borde |
| `_lightMuted` | `#4B535C` | Texto secundario en claro (≥ 7:1 sobre blanco) |
| `_darkBackground` / `_darkCard` / `_darkRaised` / `_darkHigh` | `#0A0B0D` / `#15171A` / `#1C1F23` / `#24282D` | Oscuro neutro por niveles; borde `#2C3036` |
| `_darkText` / `_darkMuted` | `#F5F7FA` / `#A9B1BA` | Texto en oscuro (≥ 7:1) |

**Tipografía**: Inter (OFL, empaquetada en `assets/fonts`, nunca se descarga). Títulos y
números pesados (700–800) con interletrado cerrado; cuerpo regular con altura 1,4; cifras
tabulares en todo el `TextTheme`.

**Componentes**: tarjetas radio 22 sin sombra (en oscuro borde sutil), controles radio 14 y
alto ≥ 48, `SegmentedButton` relleno de `ink` (claro) o lima (oscuro), snackbar flotante.

Reglas:
- Sin rosados ni morados (el esquema tonal de Material los genera: se sobrescriben en `AppTheme`).
- Rojo solo para alertas y para "subió" en comparaciones; verde `TransactionTile.incomeColor`
  para ingresos y "bajó".
- Nunca solo color: siempre icono + texto (+ % cuando aplica).
- Tarjetas sin elevación, radio 24. La barra inferior es flotante, en forma de píldora.

## Categorías
`CategoryStyle` traduce `iconKey` → icono + color. Los colores identifican la categoría en la dona,
las listas, la araña y los chips. `choosableKeys` = iconos que el usuario puede elegir al crear una
categoría (excluye los reservados: deudas, inversiones, apartados y los del cuadre). Cada icono
lleva palabras clave en español: `search` filtra (sin tildes) y `suggest` propone el icono al
escribir el nombre ("Gasolina" → surtidor). Las claves se guardan en la base y en las copias:
nunca renombrarlas.

## Gráficas (CustomPainter propio)
- Dona de categorías (`DonutChart`).
- Barras de gasto por día (`DailyBarChart`), con la línea del tope diario.
- Araña "Tu huella de gasto" (`SpendingRadarChart`): ciclo actual en línea sólida con relleno
  (`ink` en claro, `accent` en oscuro) y ciclo pasado en línea punteada gris; misma escala
  para ambos. Leyenda con icono + texto y `Semantics` con los valores por eje.

## Movimiento (`lib/presentation/shared/motion.dart`)
Corto, con frenado suave (`easeOutCubic`), nunca bloquea un toque. Duraciones en `Motion`:
`quick` 180 ms (indicadores), `medium` 320 ms (entradas, secciones), `slow` 650 ms (gráficas y montos).
- Pantallas nuevas: `FadeForwardsPageTransitionsBuilder` (Android moderno, atrás predictivo).
- Cambio de sección: `RevealOnActive` (fundido + subida leve, conserva el estado). Icono activo crece.
- Inicio: tarjetas en cascada la primera vez (`staggered`, máx. 6 pasos de 45 ms; sin timers).
- "Libre para gastar" cuenta hasta su valor (`AnimatedMoneyText`); barra apilada y tope de hoy se llenan.
- Gráficas (`ChartReveal`): dona se dibuja en sentido horario, barras e histograma crecen desde la
  base, araña se abre desde el centro. Se repite solo si cambian los datos (no al elegir un mes).
- Movimientos: el ciclo entra desde el lado al que se navegó; la lista entra de nuevo al cambiar
  Gastos/Ingresos o el filtro.
- Accesibilidad: si el teléfono pide quitar animaciones (`MediaQuery.disableAnimations`), todo
  aparece al instante (`motion_test`).

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
- **Tarjeta héroe** (`MoneyHeroCard`): **arte del día** (`DailyArt` + `DecorBackdrop.daily`),
  número en lima = **Libre para gastar hasta tu sueldo** (sin lo que sobra del tope parejo);
  debajo, barra apilada disponible = fijos + pagos del año + ahorro + presupuesto + sobra +
  libre (`sky`, `orange`, `blue`, `mint`, `sun`, lima) con leyenda en texto, y el tope de hoy.
- **Orden del Home** (responde las preguntas en orden): **frase del día** (`GreetingBanner`,
  saludo + fecha; tocar muestra el "Hoy:") → héroe → facturas por confirmar → **Qué hacer
  ahora** (IA + alertas) → **Próximos pagos** con estado y barra de reserva → pagos del año →
  gasto por día → patrimonio y metas → araña → pulso. La dona Gastos/Ingresos por categoría
  vive en **Movimientos**, por ciclo de sueldo.
- **Arte del día** (`DailyArt`, 7 que rotan): base `heroBase` con dos brillos radiales de
  color vívido (Volt, Océano, Atardecer, Aurora, Eléctrico, Dorado, Roca) a opacidad máxima
  `maxGlowAlpha` (0,16), una textura blanca muy tenue distinta cada día (ondas, rayas, rocas,
  sol, burbujas, montañas, órbitas) y borde de 1 px tipo vidrio. Lo usan el banner de la
  frase, la tarjeta del saldo y la de Cashflow. `daily_art_test` verifica ≥ 7:1 para texto
  blanco, gris claro y lima en el punto más brillante de cada arte.
- **Histograma de 12 meses** (`MonthlyHistogram`): barras redondeadas, mes pico en ámbar
  `#E2A52B` con su valor encima, mes actual en `primary`, promedio en línea punteada.
- **Estados** (`status_style.dart`): `StatusChip` = icono + texto sobre fondo al 12 %.
  Urgente = rojo (`error`), Atención = ámbar `#B45309`/`#FCD34D`, Oportunidad = azul
  `#1D4ED8`/`#93C5FD`, Logro/Cubierto = verde `#15803D`/`#86EFAC`.
- **Navegación**: píldora oscura de 68 px con 5 destinos (icono + nombre), indicador lima.
- Gráfica nueva: evolución del patrimonio (`NetWorthHistoryCard`, línea con relleno suave y
  `Semantics` con inicio/fin).
