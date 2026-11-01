# Pollería Móvil

Aplicación Flutter para la gestión de pedidos, mesas, notificaciones en tiempo real (Pusher) y reportes de la pollería.

## Requisitos

- Flutter `3.47.9` (o superior dentro del canal stable)
- Java 17
- Android SDK configurado

## Ejecutar en local

```bash
flutter pub get
flutter run --dart-define=BACKEND_URL=https://localhost:7200
```

También puedes cambiar la URL desde la pantalla de configuración de la app.

## Variables de compilación

La app acepta las siguientes variables mediante `--dart-define`:

| Variable | Descripción | Valor por defecto |
| --- | --- | --- |
| `BACKEND_URL` | URL base del backend | `https://localhost:7200` (local) / `https://polleriaback1.onrender.com` (CI) |
| `PUSHER_APP_KEY` | App Key de Pusher Channels | `a442712ed0da505c97d1` |
| `PUSHER_CLUSTER` | Clúster de Pusher | `us2` |
| `PUSHER_PORT` | Puerto de conexión WebSocket | `443` |
| `PUSHER_USE_TLS` | Usar `wss://` (true) o `ws://` (false) | `true` |

Ejemplo:

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://api.midominio.com \
  --dart-define=PUSHER_APP_KEY=tu_app_key \
  --dart-define=PUSHER_CLUSTER=us2
```

## CI/CD: APK automático en GitHub Releases

El workflow [`.github/workflows/release-apk.yml`](.github/workflows/release-apk.yml) compila y publica los APK en la sección **Releases** de GitHub.

### Cuándo se ejecuta

- Al hacer push de un tag que empiece con `v`, por ejemplo:
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
- Manualmente desde **Actions → Release APK → Run workflow**.

### Artefactos generados

- `polleria-<version>+<build>-universal.apk` (instalable en cualquier Android)
- `polleria-<version>+<build>-armeabi-v7a.apk`
- `polleria-<version>+<build>-arm64-v8a.apk`
- `polleria-<version>+<build>-x86_64.apk`
- `polleria-<version>+<build>.aab` (para Google Play, opcional)
- `build-info.txt` (versión, backend, clúster de Pusher, commit y variables usadas)
- `SHA256SUMS.txt` (checksums de todos los archivos)

### Variables y secretos del repositorio

Configúralos en **Settings → Secrets and variables → Actions**.

Variables (no sensibles):

| Nombre | Obligatorio | Descripción |
| --- | --- | --- |
| `BACKEND_URL` | No | URL del backend para el APK |
| `PUSHER_APP_KEY` | No | App Key de Pusher |
| `PUSHER_CLUSTER` | No | Clúster de Pusher |
| `PUSHER_PORT` | No | Puerto de Pusher (`443`) |
| `PUSHER_USE_TLS` | No | `true` o `false` |

Secretos (firma del APK):

| Nombre | Obligatorio | Descripción |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Recomendado | Keystore `.jks` codificado en Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Recomendado | Contraseña del keystore |
| `ANDROID_KEY_ALIAS` | Recomendado | Alias de la clave |
| `ANDROID_KEY_PASSWORD` | Recomendado | Contraseña de la clave |

Si no se configura el keystore, el workflow genera el APK firmado con la clave de **debug** y muestra una advertencia.

### Crear el keystore y convertirlo a Base64

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

base64 -w 0 upload-keystore.jks > keystore.b64
```

Copia el contenido de `keystore.b64` en el secreto `ANDROID_KEYSTORE_BASE64`.

> Nunca subas `upload-keystore.jks`, `keystore.b64` ni `android/key.properties` al repositorio.

Para firma local, copia `android/key.properties.example` a `android/key.properties`, coloca el keystore en `android/app/upload-keystore.jks` y completa las contraseñas.

## Pruebas

```bash
flutter test
```
