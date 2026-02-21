# MinasGo Frontend

Aplicación Flutter del frontend de MinasGo.

## Requisitos

- Flutter SDK instalado
- Xcode (para iOS en macOS)
- Android Studio + Android SDK (para Android)
- Chrome (para web)

Verifica tu entorno con:

```bash
flutter doctor
```

## Instalación inicial

Desde la raíz del proyecto:

```bash
flutter pub get
```

## Formas de ejecutar el proyecto

### 1. Ejecución rápida (dispositivo por defecto)

```bash
flutter run
```

Flutter escogerá un dispositivo disponible automáticamente.

### 2. Ejecutar en iOS Simulator (macOS)

1. Abre el simulador:

```bash
open -a Simulator
```

2. Lista dispositivos disponibles:

```bash
flutter devices
```

3. Ejecuta en un simulador específico:

```bash
flutter run -d "iPhone 15"
```

También puedes usar el `device_id` que entregue `flutter devices`.

### 3. Ejecutar en Android Emulator

1. Abre un emulador desde Android Studio (Device Manager).
2. Verifica que esté activo:

```bash
flutter devices
```

3. Ejecuta la app:

```bash
flutter run -d <device_id_android>
```

### 4. Ejecutar en Web (Chrome)

```bash
flutter run -d chrome
```

### 5. Ejecutar en dispositivo físico

1. Conecta el dispositivo por USB.
2. Habilita modo desarrollador/depuración USB (Android) o confía en el equipo (iOS).
3. Verifica que aparezca:

```bash
flutter devices
```

4. Ejecuta:

```bash
flutter run -d <device_id>
```

## Comandos útiles durante el desarrollo

Con `flutter run` activo en terminal:

- `r`: Hot Reload
- `R`: Hot Restart
- `q`: Salir

## Verificación estática

```bash
flutter analyze
```

## Estructura relevante actual

- `lib/main.dart`: punto de entrada de la app
- `lib/features/login/presentation/screens/login_view.dart`: pantalla de login
- `lib/features/login/presentation/widgets/google_mark.dart`: logo de Google en el botón
- `assets/images/`: imágenes estáticas (ej. login y logo)
