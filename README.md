![Trainyl Mobile App](assets/icon/app_icon.png)

# Trainyl Mobile App

Aplicación móvil Flutter para conductores y repartidores, optimizada para gestionar rutas, órdenes y entregas con conexión a Odoo.

## ✅ Qué hace esta app

Trainyl Mobile App está diseñada para que el conductor pueda:

- Iniciar sesión con usuario y PIN.
- Seleccionar la sede y la ruta del día.
- Visualizar órdenes pendientes, en transporte y entregadas.
- Escanear códigos de barras y validar paquetes con la cámara.
- Registrar fotos y comentarios en cada entrega.
- Rechazar órdenes con razones configurables.
- Reprogramar pedidos cuando corresponde.
- Consultar el estado de la ruta en un mapa y navegar con geolocalización.

## ✨ Características principales

- Autenticación segura con backend Odoo.
- Selección dinámica de rutas del día.
- Filtro y búsqueda rápida de órdenes.
- Escaneo de códigos de barras con soporte de cámara.
- Búsqueda global de órdenes en servidor si no se encuentran localmente.
- Manejo de entregas parciales y múltiples paquetes.
- Registro de evidencia fotográfica y comentarios de entrega.
- Rechazo inteligente con razones de cancelación.
- Reprogramación de órdenes rechazadas.
- Interfaz adaptativa para distintos tamaños de pantalla.

## 🚀 Valor para el usuario

Esta app ayuda a conductores a trabajar con mayor precisión y menos errores durante el proceso de entrega. Centraliza la información de orden, ruta y cliente en una sola pantalla, reduce la carga de papel y mejora el control en tiempo real.

## 🧱 Arquitectura del proyecto

- `lib/main.dart`: punto de entrada.
- `lib/core/`: cliente Odoo, servicios, modelos, utilidades y lógica de datos.
- `lib/presentation/`: pantallas, widgets y lógica de interacción.
- `assets/`: iconos y recursos estáticos.
- `pubspec.yaml`: configuración de dependencias.

## 🛠️ Tecnologías usadas

- Flutter 3.x
- Dart 3.10
- `google_maps_flutter`
- `mobile_scanner`
- `image_picker`
- `shared_preferences`
- `flutter_image_compress`
- `http`
- `intl`
- `dotted_border`

## 💡 Flujo principal de la app

1. El conductor hace login.
2. Elige la sede y la ruta asignada.
3. Ve la lista de órdenes del día.
4. Escanea el código de barras o busca la orden manualmente.
5. Revisa el detalle del pedido, la ubicación y la entrega.
6. Captura fotos, agrega comentarios y cierra la orden.
7. Rechaza o reprograma órdenes cuando sea necesario.
8. Consulta su perfil y cierra sesión.

## ⚙️ Cómo ejecutar

1. Instala Flutter y las herramientas necesarias:
   - Flutter SDK
   - Android SDK / Xcode
2. Ejecuta en la raíz del proyecto:
   ```bash
   flutter pub get
   flutter run
   ```
3. Para builds de producción:
   ```bash
   flutter build apk
   flutter build ios
   ```

> Para ejecutar en un dispositivo específico, usa `flutter devices` y `flutter run -d <deviceId>`.

## 🌐 Repositorios Git

El proyecto está sincronizado con:

- GitLab: `origin` → `https://gitlab.com/contreraselver09/trainyl_2_0.git`
- GitHub: `github` → `https://github.com/elver-09/app-mobile.git`

### Push a ambos remotos

```bash
git push origin main
git push github main
```

### Configurar push doble en el mismo remoto

```bash
git remote set-url --add --push origin https://gitlab.com/contreraselver09/trainyl_2_0.git
git remote set-url --add --push origin https://github.com/elver-09/app-mobile.git
git push origin main
```

## ⚠️ Nota de almacenamiento

Hay APKs grandes en `releases/` (>50 MB). Para proyectos públicos, recomiendo mover los binarios a GitHub Releases o usar Git LFS para no perjudicar el rendimiento del repositorio.

## 🔧 Configuración de backend

El backend Odoo se configura en `lib/presentation/screens/login_screen.dart`:

- URL: `https://trainyl.digilab.pe`
- Base de datos: `trainyl-prd`

Si necesitas cambiar el backend, actualiza `AuthController` / `OdooClient`.

## 📌 Recomendaciones para el README público

- Agregar capturas de pantalla reales de la app.
- Añadir un diagrama breve de flujo de rutas y órdenes.
- Incluir una sección de “Contribución” si planeas aceptar aportes.
- Colocar un badge de estado o versión si lo deseas.

## 📈 Próximos pasos

- Documentar los endpoints Odoo utilizados.
- Crear pruebas unitarias y de widgets.
- Configurar CI/CD con GitHub Actions o GitLab CI.
- Mejorar la documentación de instalación y despliegue.
