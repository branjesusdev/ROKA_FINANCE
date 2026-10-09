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
