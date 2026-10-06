# Entorno de desarrollo (Windows + VS Code + teléfono Android)

Estado verificado el 2026-10-02: Flutter 3.47.5 stable, Dart 3.13.4, JDK 17.0.12.
**Bloqueante:** Android SDK no instalado (`ANDROID_HOME=C:\Android` apunta a una carpeta inexistente).

## 1. Verificar herramientas
```bash
flutter --version
dart --version
flutter doctor -v
flutter devices
```
El aviso de Visual Studio solo afecta apps de escritorio Windows: se ignora.

## 2. Instalar Android SDK sin Android Studio
1. Descargar *Command line tools only* (Windows) de https://developer.android.com/studio#command-line-tools-only
2. Descomprimir para que quede `C:\Android\cmdline-tools\latest\bin\sdkmanager.bat`
   (el PATH ya incluye `C:\Android\cmdline-tools\latest\bin` y `C:\Android\platform-tools`).
3. Instalar paquetes (usar las versiones que `flutter doctor` pida; listar con `sdkmanager --list`):
   ```bash
   sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "extras;google;usb_driver"
   flutter doctor --android-licenses
   ```
4. Si `flutter doctor` no encuentra Java: `flutter config --jdk-dir "<ruta JDK 17+>"`.

## 3. Preparar el teléfono
Ajustes → Acerca del teléfono → tocar 7 veces "Número de compilación" → Opciones de desarrollador →
activar **Depuración USB**. Conectar por USB, aceptar la huella RSA. Si Windows no lo reconoce,
instalar el driver USB del fabricante (o `C:\Android\extras\google\usb_driver`).
```bash
adb devices        # debe mostrar el teléfono como "device"
flutter devices
```

## 4. Proyecto
```bash
cd C:\FUENTES\PERSONALES\finance_app
code .
flutter pub get
dart run build_runner build   # desde Fase 4 (codegen drift)
dart format .
flutter analyze
flutter test
flutter run -d <id-del-telefono>
```
Extensiones VS Code: `Dart-Code.flutter` (recomendada en `.vscode/extensions.json`).
