# finance_app

Finanzas personales offline-first (Flutter, Android). Ver `CLAUDE.md` y `docs/`.

## Desarrollo en el teléfono (USB)

```bash
adb devices          # el teléfono debe aparecer como "device"
flutter run          # modo debug con hot reload (r = reload, R = restart, q = salir)
```

## Generar APK (solo arm64-v8a, más rápido)

```bash
flutter build apk --release --target-platform android-arm64
```

Salida: `build/app/outputs/flutter-apk/app-release.apk`. Sirve para casi todos los teléfonos
Android desde 2017 y compila una sola arquitectura en vez de tres.

Instalar en el teléfono conectado: `flutter install`, o copiar el `.apk` al teléfono y abrirlo.

Si el build falla con archivos bloqueados: verifica que no haya otro build corriendo y ejecuta
`flutter clean`.


Si registrar un gasto toma demasiado tiempo, el usuario abandona la aplicación.
Si el usuario necesita aprender a usar la aplicación, la aplicación ya es demasiado compleja.
Cada gasto debería poder registrarse en segundos, no en minutos.
La pantalla principal debe responder “¿cómo estoy financieramente?” sin que el usuario tenga que buscar.
Menos gráficos y más decisiones accionables.
El usuario no quiere contabilidad; quiere entender qué hacer con su dinero.
La información financiera debe convertirse en una acción concreta.
Si una función requiere demasiados pasos, debe simplificarse o automatizarse.
La aplicación debe recordar antes que obligar al usuario a registrar.
La mejor interfaz financiera es la que desaparece detrás del hábito.
El usuario debe poder corregir un error sin rehacer todo el registro.
La aplicación debe adaptarse al comportamiento del usuario, no obligarlo a adaptarse a ella.
La velocidad de entrada es más importante que la cantidad de campos.
Una buena aplicación financiera debe poder utilizarse con una sola mano.
La información importante debe estar disponible en una sola mirada.

La aplicación debe hacer que administrar el dinero sea rápido, simple y accionable: registrar gastos en segundos, identificar fugas y malos hábitos, mostrar el impacto real de cada decisión sobre el presupuesto, las deudas y el patrimonio, ayudar al usuario a controlar sus impulsos y alcanzar objetivos, y convertir el dinero que logra liberar en capital para ahorrar, invertir o crear negocios. No debe limitarse a mostrar estadísticas, sino actuar como un CFO personal que, utilizando los datos reales del usuario, explique qué está pasando, qué opciones existen, cuánto cuesta cada decisión y cuál puede acercarlo más a construir patrimonio, generar nuevas fuentes de ingresos y alcanzar independencia financiera.


