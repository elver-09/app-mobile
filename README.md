![Trainyl Mobile App](assets/icon/app_icon.png)

# Trainyl Mobile App

Aplicación Flutter para conductores y repartidores, diseñada para gestionar rutas, órdenes y entregas desde un backend Odoo.

## Descripción

Este proyecto es una aplicación móvil Flutter usada por conductores para:
- iniciar sesión con usuario y PIN
- seleccionar sede y ruta del día
- revisar el estado de cada orden
- escanear códigos de barras y verificación de paquetes
- registrar entregas con fotos y comentarios
- rechazar o reprogramar órdenes
- acceder a datos de ubicación y rutas en mapa

La app se construye con:
- Flutter + Dart 3.10
- Arquitectura modular en `core` y `presentation`
- Cliente Odoo propio para autenticación, rutas y órdenes
- Integración con Google Maps, cámara/QR, almacenamiento local y compresión de imágenes

## Flujo principal de la app

1. **Inicio de sesión**: el conductor ingresa correo/PIN y se autentica contra el backend Odoo.
2. **Selección de sede/ruta**: muestra las rutas del día y permite seleccionar una ruta activa.
3. **Panel de ruta**: visualiza órdenes de la ruta, estadísticas y opciones para iniciar la siguiente orden.
4. **Escaneo de código de barras**: registra paquetes mediante cámara o búsqueda manual de número de orden.
5. **Detalle de orden**: muestra datos del cliente, dirección, estado, mapa de ruta y opciones de entrega.
6. **Captura de evidencia**: fotos de entrega, comentarios, estado de paquete y rechazos.
7. **Gestión de rechazos/reprogramaciones**: el conductor puede seleccionar razones de rechazo y reprogramar pedidos cuando corresponde.
8. **Perfil del conductor**: muestra datos del chofer y permite cerrar sesión.

## Funcionalidades destacadas

- Autenticación con Odoo
- Selección y visualización de rutas del día
- Filtro y búsqueda de órdenes
- Escaneo de códigos de barras con cámara
- Búsqueda global de órdenes en servidor si no se encuentran localmente
- Gestión de entregas parciales y múltiples paquetes
- Registro de fotos y comentarios por orden
- Mapa con ruta y geolocalización
- Rechazo de órdenes con razones dinámicas
- Reprogramación de órdenes rechazadas
- Interfaz responsiva para distintos tamaños de dispositivo

## Estructura del proyecto

- `lib/main.dart`: punto de entrada de la app
- `lib/core/`: cliente Odoo, servicios, modelos y utilidades
- `lib/presentation/`: pantallas, widgets y controladores UI
- `assets/`: icono de la app y otros recursos
- `pubspec.yaml`: dependencias y configuración de Flutter

## Dependencias clave

- `google_maps_flutter`
- `image_picker`
- `mobile_scanner`
- `shared_preferences`
- `flutter_image_compress`
- `http`
- `intl`
- `dotted_border`

## Cómo ejecutar

1. Instala Flutter y las herramientas de plataforma necesarias:
   - Flutter SDK
   - Android SDK / Xcode
2. En la raíz del proyecto:
   ```bash
   flutter pub get
   flutter run
   ```
3. Para compilar versiones de producción:
   ```bash
   flutter build apk
   flutter build ios
   ```

> Si necesitas ejecutar en un dispositivo específico, utiliza `flutter devices` y luego `flutter run -d <deviceId>`.

## Configuración de repositorios Git

Actualmente el repositorio está en GitLab con el remoto `origin`.

Tu repo de GitHub ya está conectado como remoto `github`: `https://github.com/elver-09/app-mobile.git`.

Para agregar el remoto GitHub manualmente (si aún no está configurado):

```bash
git remote add github https://github.com/elver-09/app-mobile.git
```

Enviar `main` a GitHub:

```bash
git push github main
```

### Enviar a ambos remotos

```bash
git push origin main
git push github main
```

O bien configurar `origin` para hacer push a ambos:

```bash
git remote set-url --add --push origin https://gitlab.com/contreraselver09/trainyl_2_0.git
git remote set-url --add --push origin https://github.com/elver-09/app-mobile.git
git push origin main
```

> Nota: este proyecto ya está empujado a GitHub en `https://github.com/elver-09/app-mobile.git`.
> 
> GitHub advirtió que los archivos APK en `releases/` son mayores de 50 MB. Para binarios grandes, usa Git LFS.

## Consideraciones importantes

- El backend actual de Odoo está configurado en `lib/presentation/screens/login_screen.dart` con:
  - `https://trainyl.digilab.pe`
  - base de datos `trainyl-prd`
- Si necesitas cambiar backend, actualiza `AuthController` / `OdooClient`.
- Verifica permisos de Google Maps, cámara y almacenamiento en Android/iOS.

## Próximos pasos sugeridos

- Añadir capturas de pantalla reales en el README
- Documentar el flujo de datos de Odoo y los endpoints usados
- Agregar pruebas unitarias y widget tests
- Configurar CI/CD en GitLab o GitHub Actions para builds y pruebas automáticas
