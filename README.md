<div align="center">

<img src="assets/icon/app_icon.png" alt="Trainyl Mobile App" width="120"/>

# Trainyl Mobile App

**Aplicación móvil para conductores y repartidores** — gestión de rutas, órdenes y entregas en tiempo real, con backend en **Odoo** y soporte **offline-first** para el recojo en tienda.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Odoo](https://img.shields.io/badge/Backend-Odoo%2018-714B67?logo=odoo&logoColor=white)](https://www.odoo.com)
[![Platform](https://img.shields.io/badge/Plataforma-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white)](#)
[![Estado](https://img.shields.io/badge/Estado-Activo-success)](#)

</div>

---

## 📑 Tabla de contenido

- [Descripción](#-descripción)
- [Capturas](#-capturas)
- [Características principales](#-características-principales)
- [Recojo en tienda offline-first](#-recojo-en-tienda-offline-first)
- [Seguridad de sesión](#-seguridad-de-sesión)
- [Flujo de uso](#-flujo-de-uso)
- [Arquitectura del proyecto](#-arquitectura-del-proyecto)
- [Tecnologías](#-tecnologías)
- [Requisitos previos](#-requisitos-previos)
- [Instalación y ejecución](#-instalación-y-ejecución)
- [Builds de producción](#-builds-de-producción)
- [Integración con Odoo](#-integración-con-odoo)
- [Repositorios Git](#-repositorios-git)
- [Buenas prácticas del repositorio](#-buenas-prácticas-del-repositorio)
- [Roadmap](#-roadmap)
- [Contribución](#-contribución)

---

## 📦 Descripción

**Trainyl Mobile App** centraliza, en una sola herramienta, todo el trabajo diario del conductor:
desde el inicio de jornada hasta el cierre de cada entrega. La app conecta con un backend **Odoo**
para sincronizar rutas, órdenes y evidencias, y está pensada para operar incluso con **conexión
intermitente** en campo.

Reduce el uso de papel, disminuye errores de entrega y da **trazabilidad en tiempo real** de cada
acción del conductor (inicio de orden, entrega, rechazo, reprogramación, recojo en tienda).

---

## 📸 Capturas

> Reemplaza estas rutas por tus imágenes reales (sugerencia: carpeta `docs/screenshots/`).

| Inicio de jornada | Rutas del día | Detalle de órdenes | Recojo en tienda |
|:---:|:---:|:---:|:---:|
| ![Splash](docs/screenshots/splash.png) | ![Rutas](docs/screenshots/rutas.png) | ![Órdenes](docs/screenshots/ordenes.png) | ![Recojo](docs/screenshots/recojo.png) |

---

## ✨ Características principales

### Operación de rutas y entregas
- Autenticación segura contra **Odoo** (usuario + clave).
- Selección de **modo de operación**: *Entregar pedidos* o *Recoger en tienda*.
- Tablero del día con **estados de rutas y de órdenes** (gráficos de resumen).
- Lista de **rutas de hoy** con progreso, paradas y órdenes pendientes.
- Botón **Terminar** por ruta: la ruta solo se oculta cuando el conductor lo confirma (no de forma automática).
- Inicio de orden **directo**, con bloqueo si ya hay otra orden **en curso**.
- **Entrega múltiple** (todas las órdenes de un cliente) y **entrega parcial**.
- **Rechazo** de órdenes con razones configurables y **reprogramación** posterior.
- Captura de **evidencia fotográfica** y comentarios por entrega.
- **Mapa y geolocalización** para ubicar al cliente y navegar.

### Escaneo y validación
- Escaneo de **códigos de barras** con la cámara (`mobile_scanner`).
- Validación de formato por cliente (prefijo y longitud exacta) antes de aceptar el código.
- **Búsqueda global** de la orden en el servidor cuando no se encuentra localmente.

### Experiencia de usuario
- Interfaz **responsiva** para distintos tamaños de pantalla.
- Respeto del **área segura** (no se solapa con la barra de navegación del sistema).
- Reanudación de sesiones de escaneo y manejo cuidadoso de estados.

---

## 📡 Recojo en tienda (offline-first)

El módulo de **recojo en tienda** está diseñado para funcionar **sin conexión** y sincronizar
automáticamente al recuperar señal:

- Cada escaneo se guarda **primero** en una **cola local (SQLite)** → funciona sin internet y
  sobrevive al cierre de la app.
- La **validación de formato** y el **deduplicado** ocurren en el dispositivo (respuesta inmediata).
- Indicador en pantalla: *En línea / Sin conexión*, cantidad **sincronizada** y **pendiente**, con
  botón **Sincronizar**.
- Al recuperar conexión, un *worker* envía los escaneos **en lote** al backend, que de forma
  **idempotente** recoge o **crea automáticamente** las órdenes inexistentes.
- Cada ítem muestra su estado: **Pendiente** · **Recogido/Creado** · **Error** (con el motivo).

> Resultado: el conductor escanea siempre, con o sin señal, y el sistema concilia los datos cuando
> hay conexión, sin duplicar órdenes ni perder registros.

---

## 🔐 Seguridad de sesión

- La sesión **no se conserva** indefinidamente: si la app se **cierra por completo**, al reabrir se
  solicita iniciar sesión nuevamente.
- Si la app permanece **bloqueada o minimizada por mucho tiempo**, la sesión se cierra
  automáticamente al volver, por seguridad.
- El umbral de inactividad es **configurable** (`kBackgroundLogoutTimeout` en `lib/main.dart`).

---

## 🧭 Flujo de uso

1. El conductor **inicia sesión**.
2. Elige el **modo de operación** (entregar o recoger en tienda).
3. **Entregar pedidos:** ve las rutas del día → abre el detalle → inicia, entrega, rechaza o
   reprograma órdenes → captura fotos y comentarios → termina la ruta.
4. **Recoger en tienda:** elige la tienda → escanea los pedidos (incluso sin señal) → sincroniza →
   genera el cargo de recojo.
5. Consulta su **perfil** y **cierra sesión**.

---

## 🧱 Arquitectura del proyecto

```text
lib/
├── main.dart                 # Punto de entrada + control de sesión por inactividad
├── core/
│   ├── odoo/                 # Cliente HTTP de Odoo y modelos de datos
│   ├── offline/              # Cola local (SQLite) y servicio de conectividad
│   ├── pdf/                  # Generación de PDFs (cargo de recojo)
│   ├── constants/            # Estados, rutas de navegación y constantes
│   └── responsive/           # Helpers de diseño responsivo
├── presentation/
│   ├── screens/              # Pantallas (login, rutas, órdenes, recojo, perfil…)
│   │   └── pickup/           # Flujo de recojo en tienda
│   └── widgets/              # Componentes reutilizables
│       ├── route_orders/     # Tarjetas y acciones de órdenes
│       └── order_detail/     # Modales de entrega, rechazo y reprogramación
assets/                       # Iconos y recursos estáticos
pubspec.yaml                  # Dependencias y configuración del proyecto
```

**Separación de responsabilidades**
- `core/` — datos, integración con Odoo, lógica offline y utilidades.
- `presentation/` — UI, navegación e interacción con el usuario.

---

## 🛠️ Tecnologías

| Categoría | Paquetes |
|---|---|
| **Framework** | Flutter 3.x · Dart 3.x |
| **Red / API** | `http` |
| **Mapas / GPS** | `google_maps_flutter` · `geolocator` |
| **Escaneo** | `mobile_scanner` |
| **Cámara / Imágenes** | `image_picker` · `flutter_image_compress` |
| **Offline / Datos locales** | `sqflite` · `path` · `connectivity_plus` · `uuid` · `shared_preferences` |
| **Documentos** | `pdf` · `printing` |
| **UI / Utilidades** | `flutter_svg` · `dotted_border` · `intl` · `path_provider` |

---

## ✅ Requisitos previos

- **Flutter SDK** 3.x ([guía de instalación](https://docs.flutter.dev/get-started/install))
- **Android Studio** + **Android SDK** (para Android)
- **Xcode** (para iOS, solo en macOS)
- Acceso a un **backend Odoo** con el módulo `trainyl_base` desplegado

Verifica tu entorno con:

```bash
flutter doctor
```

---

## 🚀 Instalación y ejecución

```bash
# 1. Clonar el repositorio
git clone https://gitlab.com/contreraselver09/trainyl_2_0.git
cd trainyl_2_0

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo
flutter run
```

Para ejecutar en un dispositivo específico:

```bash
flutter devices
flutter run -d <deviceId>
```

---

## 📦 Builds de producción

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle, recomendado para Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔌 Integración con Odoo

La app consume endpoints del módulo **`trainyl_base`** (Odoo 18). Algunos de los principales:

| Endpoint | Descripción |
|---|---|
| `POST /driver/login` | Autenticación del conductor |
| `GET  /driver/routes/today` | Rutas del día del conductor |
| `POST /driver/routes/close/<route_id>` | Marca la ruta como terminada (la oculta) |
| `POST /driver/order/start/<route_id>/<order_id>` | Inicia una orden (bloquea si hay otra en curso) |
| `GET  /driver/pickup/stores` | Tiendas de recojo |
| `POST /driver/pickup/scan_batch` | Sincronización offline de escaneos (idempotente) |

> El token se envía en el header `Authorization: Bearer <token>`.

---

## 🌐 Repositorios Git

El proyecto se mantiene sincronizado en dos remotos:

- **GitLab** — `origin` → `https://gitlab.com/contreraselver09/trainyl_2_0.git`
- **GitHub** — `github` → `https://github.com/elver-09/app-mobile.git`

### Push a ambos remotos

```bash
git push origin main
git push github main
```

### Configurar un push doble (un solo comando)

```bash
git remote set-url --add --push origin https://gitlab.com/contreraselver09/trainyl_2_0.git
git remote set-url --add --push origin https://github.com/elver-09/app-mobile.git

# A partir de ahora, esto empuja a GitLab y GitHub a la vez:
git push origin main
```

---

## 🧹 Buenas prácticas del repositorio

- **No versionar APKs grandes** (>50 MB) en el repositorio. Usa **GitHub Releases** o **Git LFS**
  para los binarios de `releases/`, así el repo se mantiene ligero y rápido.
- Mantén un `.gitignore` adecuado para Flutter (carpeta `build/`, `.dart_tool/`, etc.).
- Versiona los cambios de `pubspec.lock` para builds reproducibles.

---

## 📈 Roadmap

- [ ] Documentar todos los endpoints de Odoo utilizados.
- [ ] Pruebas **unitarias** y de **widgets**.
- [ ] **CI/CD** con GitHub Actions / GitLab CI (análisis + build automático).
- [ ] Reintento automático periódico de sincronización offline.
- [ ] Almacenamiento del token con `flutter_secure_storage`.
- [ ] Diagrama de flujo de rutas y órdenes en la documentación.

---

## 🤝 Contribución

1. Crea una rama desde `main`: `git checkout -b feature/mi-mejora`
2. Realiza tus cambios y verifica el análisis estático: `flutter analyze`
3. Haz commit con mensajes claros y descriptivos.
4. Abre un *Merge Request* / *Pull Request* describiendo el cambio.

---

<div align="center">

**Trainyl · Logística de confianza**

</div>