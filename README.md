# CleanArch CLI

> **Generador de estructura Clean Architecture + GetX para proyectos Flutter**
> Desarrollado por [RamonChenoDev](https://github.com/RamonChenoDev)

```
  ____ _                      _             _
 / ___| | ___  __ _ _ __     / \   _ __ ___| |__
| |   | |/ _ \/ _` | '_ \  / _ \ | '__/ __| '_ \
| |___| |  __/ (_| | | | |/ ___ \| | | (__| | | |
 \____|_|\___|\__,_|_| |_/_/   \_\_|  \___|_| |_|

  Flutter Clean Architecture + GetX Generator v1.2.0
```

CleanArch es una herramienta de línea de comandos (CLI) escrita en Dart que genera automáticamente toda la estructura de carpetas y archivos boilerplate para proyectos Flutter siguiendo los principios de **Clean Architecture**, con **GetX** como manejador de estado, navegación e inyección de dependencias.

---

## Tabla de contenido

- [¿Por qué usar esta herramienta?](#por-qué-usar-esta-herramienta)
- [Requisitos](#requisitos)
- [Para el desarrollador del CLI](#para-el-desarrollador-del-cli)
- [Para los usuarios del CLI](#para-los-usuarios-del-cli)
- [Comandos](#comandos)
  - [create project](#-create-project)
  - [create module](#-create-module)
  - [create feature](#-create-feature)
  - [create screen](#-create-screen)
  - [create controller](#-create-controller)
  - [create widget](#-create-widget)
  - [create table](#-create-table)
  - [create test](#-create-test)
  - [update](#-update)
- [Opciones globales](#opciones-globales)
- [Shell completion](#shell-completion)
- [Inyección automática de rutas](#inyección-automática-de-rutas)
- [Plataformas objetivo](#plataformas-objetivo)
- [Dependencias externas](#dependencias-externas)
- [Estructura del proyecto generado](#estructura-del-proyecto-generado)
- [Capas de Clean Architecture](#capas-de-clean-architecture)
- [Flujo de datos completo](#flujo-de-datos-completo)
- [Diferencias: Module vs Feature vs Screen](#diferencias-module-vs-feature-vs-screen)
- [Estructura del CLI](#estructura-del-cli)
- [Archivos generados por capa](#archivos-generados-por-capa)

---

## ¿Por qué usar esta herramienta?

Cada vez que empiezas un proyecto Flutter con Clean Architecture tienes que crear
manualmente decenas de archivos con la misma estructura base. CleanArch lo hace por ti
en segundos, con comentarios explicativos en cada archivo para que cualquier persona
del equipo entienda para qué sirve cada pieza, aunque sea nueva en esta arquitectura.

**Sin CleanArch:** crear un módulo nuevo tarda ~20 minutos de copiar, pegar y renombrar.  
**Con CleanArch:** `cleanarch create module producto` → archivos generados y ruta registrada en 2 segundos.

---

## Requisitos

- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0`
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (para los proyectos generados)

---

## 👨‍💻 Para el desarrollador del CLI

> Sigue estos pasos si eres el desarrollador del proyecto y necesitas generar
> el ejecutable desde cero para distribuirlo al equipo.

### Requisitos previos

- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0` instalado
- Tener la carpeta del proyecto `clean_arch_cli` en tu máquina
- `mason_cli` instalado globalmente: `dart pub global activate mason_cli`

### Paso 1 — Instalar dependencias del CLI

```bash
cd clean_arch_cli
dart pub get
```

### Paso 2 — (Solo si editas templates) Regenerar los bundles de Mason

Los templates de código se encuentran en `bricks/`. Después de editar cualquier
archivo `.mustache` o `brick.yaml`, debes regenerar los bundles embebidos:

```bash
dart run tool/generate_bundles.dart
```

Esto ejecuta `mason bundle` para cada brick y actualiza los archivos en
`lib/src/bundles/`. **No es necesario** si solo cambias lógica del CLI (comandos,
generadores, utilidades).

### Paso 3 — Compilar el ejecutable

```bash
dart compile exe bin/main.dart -o bin/cleanarch.exe
```

Genera `bin/cleanarch.exe` (~10 MB). El archivo es autocontenido: los usuarios **no necesitan
tener Dart instalado** para usarlo.

### Paso 4 — Verificar que compiló correctamente

```bash
bin/cleanarch.exe --help
```

Debe mostrarse el banner de CleanArch y la lista de comandos disponibles.

### Paso 5 — Distribuir

Entrega el archivo `bin/cleanarch.exe` a los usuarios del equipo. Ellos lo instalan siguiendo
la [sección de usuarios](#para-los-usuarios-del-cli).

### Actualizar la versión

La versión está definida en **dos lugares** que deben mantenerse sincronizados:

1. `pubspec.yaml` → campo `version`
2. `lib/src/version.dart` → constante `cliVersion`

```dart
// lib/src/version.dart
const cliVersion = '1.3.0';  // ← actualizar aquí al hacer un release
```

---

## 👤 Para los usuarios del CLI

> Sigue estos pasos si recibes el CLI del desarrollador o tienes acceso al código fuente.

### Opción A — Sin Dart (solo el ejecutable) ✅ Recomendada

Ideal para usuarios finales del equipo que solo necesitan usar el CLI.

**Requisitos:** `cleanarch.exe` (proporcionado por el desarrollador) + Flutter SDK instalado.

**Paso 1 — Crear una carpeta para el CLI**

```
C:\tools\cleanarch\
```

Copia `cleanarch.exe` dentro de esa carpeta.

**Paso 2 — Agregar la carpeta al PATH de Windows**

1. Busca **"Variables de entorno"** en el menú inicio
2. En **Variables de usuario** selecciona `Path` → **Editar**
3. Clic en **Nuevo** y escribe la ruta de la carpeta (ej. `C:\tools\cleanarch`)
4. **Aceptar** en todas las ventanas

**Paso 3 — Verificar en una terminal nueva**

```bash
cleanarch --help
```

**Para actualizar el CLI:** solo reemplaza el archivo `cleanarch.exe` por la nueva versión.
O si tienes Dart instalado: `cleanarch update`

---

### Opción B — Con Dart instalado (activación global)

Ideal si ya tienes Dart instalado y tienes acceso al código fuente del CLI.

**Requisitos:** Dart SDK `>=3.0.0`, carpeta `clean_arch_cli` y Flutter SDK.

**Paso 1 — Activar el CLI globalmente**

```bash
dart pub global activate --source path "ruta\al\clean_arch_cli"
```

**Paso 2 — Agregar el PATH de Dart**

Agrega esta ruta a las variables de entorno del usuario:

```
C:\Users\<TuUsuario>\AppData\Local\Pub\Cache\bin
```

1. Busca **"Variables de entorno"** en el menú inicio
2. En **Variables de usuario** selecciona `Path` → **Editar**
3. Clic en **Nuevo** y pega la ruta anterior (con tu nombre de usuario)
4. **Aceptar** en todas las ventanas

**Paso 3 — Verificar en una terminal nueva**

```bash
cleanarch --help
```

**Para actualizar el CLI:** vuelve a ejecutar el comando del Paso 1, o usa `cleanarch update`.

---

### Comparativa de opciones

| | Opción A — exe directo | Opción B — dart global |
|--|--|--|
| **Requiere Dart** | No | Sí |
| **Actualizar el CLI** | Reemplazar `cleanarch.exe` | `dart pub global activate` de nuevo |
| **Recomendado para** | Usuarios finales del equipo | Desarrolladores con Dart instalado |

---

## Comandos

### Ver ayuda general

```bash
cleanarch --help
cleanarch --version
```

---

### 📦 `create project`


Crea un **proyecto Flutter completo** con toda la estructura de Clean Architecture,
archivos de configuración, tema, traducciones, red y los módulos iniciales que indiques.
Ejecuta `flutter create` internamente para generar las carpetas nativas de cada plataforma
(`android/`, `ios/`, `web/`, `windows/`, etc.) y luego aplica los templates de Clean Architecture.

```bash
cleanarch create project <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--org` | `-o` | Bundle ID / organización | `dev.ramonchenodev` |
| `--output` | `-d` | Carpeta donde crear el proyecto | `.` (carpeta actual) |
| `--modules` | `-m` | Módulos iniciales separados por coma | `home` |
| `--platforms` | `-l` | Plataformas objetivo (ver [Plataformas objetivo](#plataformas-objetivo)) | `mobile` |
| `--datasource` | `-s` | Fuente de datos: `rest`, `local`, `both` | `rest` |
| `--http-lib` | — | Librería HTTP: `dio`, `get_connect`, `http` | `get_connect` |
| `--storage-lib` | — | ORM / storage: `get_storage`, `drift`, `isar`, `sqflite`, `objectbox`, `floor`, `hive`, `shared_preferences` | `get_storage` |
| `--deps` | — | Paquetes a incluir (ver [Dependencias externas](#dependencias-externas)) | — |
| `--interactive` | `-i` | Modo interactivo: pregunta cada dato | — |

**Ejemplos:**

```bash
# Proyecto básico (Android + iOS por defecto)
cleanarch create project mi_app

# Solo Android
cleanarch create project mi_app --platforms android

# Android + iOS + Web
cleanarch create project mi_app --platforms android,ios,web

# App de escritorio (Windows + Linux + macOS)
cleanarch create project mi_app --platforms windows,linux,macos

# Todas las plataformas
cleanarch create project mi_app --platforms all

# Con módulos, org y plataformas
cleanarch create project tienda_app --org com.miempresa --modules home,producto,carrito --platforms android,ios

# App offline-first con Drift como base de datos local
cleanarch create project mi_app --datasource local --storage-lib drift

# App offline-first con REST + base de datos local Isar
cleanarch create project mi_app --datasource both --http-lib dio --storage-lib isar

# App con dos storages: Drift para base de datos + SharedPreferences para settings
cleanarch create project mi_app --datasource both --storage-lib "drift:database,shared_preferences:settings"

# Con dependencias del catálogo
cleanarch create project mi_app --deps dio,firebase_core,lottie

# Modo interactivo completo (pregunta nombre, org, módulos, plataformas y dependencias)
cleanarch create project -i
```

---

### 🧩 `create module`

Agrega un **módulo completo** (las 3 capas: Domain + Data + Presentation) a un proyecto
Flutter existente. La ruta se **inyecta automáticamente** en `app_pages.dart` y `app_routes.dart`.

```bash
cleanarch create module <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` (carpeta actual) |
| `--datasource` | `-s` | Fuente de datos: `rest`, `local`, `both` | interactivo |
| `--http-lib` | — | Librería HTTP (ej: `dio`, `get_connect`, `http`) | `dio` |
| `--storage-lib` | — | Librería local (ej: `get_storage`, `hive`, `sqflite`) | `get_storage` |
| `--overwrite` | `-f` | Sobreescribir archivos existentes | `false` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |
| `--container` | `-c` | Módulo contenedor: solo directorio + marker de rutas | `false` |
| `--presentation-only` | `-P` | Solo Controller + Binding + View (sin domain/data) | `false` |

> Si el módulo ya existe parcialmente, al responder **No** a la pregunta de sobreescritura
> el CLI **continúa y crea únicamente los archivos faltantes**, saltando los existentes.

**Modo interactivo** — al ejecutar sin `--datasource`, el CLI pregunta:

```
  ¿Cómo accederá a los datos este módulo?

  1. API REST           → provider con llamadas HTTP
  2. Solo local         → provider con almacenamiento en dispositivo
  3. Ambas              → REST con caché local (offline-first)
  4. Decidir después    → REST por defecto
  5. Sin datos propios  → solo Controller + Binding + View
  6. Módulo contenedor  → agrupa sub-screens (sin domain/data/controller)
```

**Ejemplos:**

```bash
cd mi_app
cleanarch create module producto

cleanarch create module categoria --path D:\Proyectos\mi_app
cleanarch create module producto --overwrite

# Ver qué se generaría sin crear nada
cleanarch create module auth --dry-run

# Módulo con Dio (REST)
cleanarch create module auth --datasource rest --http-lib dio

# Módulo local con Hive
cleanarch create module config --datasource local --storage-lib hive

# Módulo offline-first
cleanarch create module catalogo --datasource both --http-lib dio --storage-lib hive

# Solo Controller + Binding + View (sin domain/data)
cleanarch create module home --presentation-only

# Módulo contenedor para agrupar sub-screens (sin domain/data/controller)
cleanarch create module tasks --container
```

**Archivos generados:**

```
lib/app/
├── domain/
│   ├── entities/
│   │   └── producto_entity.dart
│   ├── repositories/
│   │   └── producto_repository.dart
│   └── usecases/
│       ├── get_all_productos_usecase.dart
│       └── get_producto_by_id_usecase.dart
├── data/
│   ├── models/
│   │   └── producto_model.dart
│   ├── providers/
│   │   └── producto_provider.dart
│   └── repositories/
│       └── producto_repository_impl.dart
└── modules/
    └── producto/
        ├── controllers/
        │   └── producto_controller.dart
        ├── bindings/
        │   └── producto_binding.dart
        ├── views/
        │   └── producto_view.dart
        └── widgets/
```

**Ruta inyectada automáticamente en `app_pages.dart`:**

```dart
GetPage(
  name: Routes.home,
  page: () => const HomeView(),
  binding: HomeBinding(),
  children: [
    GetPage(                          // ← inyectado automáticamente
      name: Routes.producto,
      page: () => const ProductoView(),
      binding: ProductoBinding(),
      children: [
        // cleanarch:inject:producto  ← aquí se inyectarán sus screens
      ],
    ),
    // cleanarch:inject
  ],
),
```

---

### ⚡ `create feature`

Crea un **feature ligero** (solo Presentation: controller + binding + view) sin capas
domain/data propias. La ruta se **inyecta automáticamente** como hijo de home.

```bash
cleanarch create feature <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` |
| `--overwrite` | `-f` | Sobreescribir archivos existentes | `false` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |

**Ejemplos:**

```bash
cleanarch create feature dashboard
cleanarch create feature splash --path D:\Proyectos\mi_app
cleanarch create feature perfil_usuario
cleanarch create feature settings --dry-run
```

**Archivos generados:**

```
lib/app/features/dashboard/
├── controllers/
│   └── dashboard_controller.dart
├── bindings/
│   └── dashboard_binding.dart
├── views/
│   └── dashboard_view.dart
└── widgets/
```

---

### 📱 `create screen`

Crea una **sub-pantalla** dentro de un módulo o en la carpeta `screens/` global.
La ruta se **inyecta automáticamente** en los `children` del módulo padre (o de home).

```bash
cleanarch create screen <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` |
| `--module` | `-m` | Módulo padre donde insertar la screen | — (hijo de home) |
| `--overwrite` | `-f` | Sobreescribir archivos existentes | `false` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |

**Alias:** `page` (puedes usar `cleanarch create page <nombre>`)

**Ejemplos:**

```bash
cleanarch create screen login
cleanarch create screen detalle --module producto
cleanarch create screen confirmacion --module orden --path D:\Proyectos\mi_app
```

**Auto-creación del módulo contenedor**

Si usas `--module <nombre>` y el módulo padre aún no existe como contenedor en
`app_pages.dart`, el CLI lo detecta y pregunta:

```
⚠  El módulo "producto" no existe como contenedor en app_pages.dart.
   Las sub-screens necesitan que el módulo padre esté registrado.

  ¿Deseas crearlo automáticamente como módulo contenedor? [S/n]:
```

- **S (Enter):** crea el módulo contenedor (`create module producto --container`) y luego
  genera la screen, todo en un solo comando.
- **n:** el CLI muestra el comando exacto para crearlo y cancela sin tocar archivos.

Si prefieres hacerlo en dos pasos:
```bash
cleanarch create module producto --container   # primero el contenedor
cleanarch create screen detalle --module producto
```

**Archivos generados (con `--module producto`):**

```
lib/app/modules/producto/screens/detalle/
├── controllers/
│   └── detalle_controller.dart
├── bindings/
│   └── detalle_binding.dart
└── views/
    └── detalle_screen.dart
```

**Convención de rutas**

El nombre de la constante usa **lowerCamelCase** y la ruta URL usa **kebab-case**:

| Screen | Constante (`app_routes.dart`) | Ruta URL |
|--------|-------------------------------|----------|
| `detalle` | `Routes.detalle` | `/detalle` |
| `add_task` | `Routes.addTask` | `/add-task` |
| `orden_confirmacion` | `Routes.ordenConfirmacion` | `/orden-confirmacion` |

**Para navegar:**

```dart
Get.toNamed(Routes.detalle);
Get.toNamed(Routes.detalle, arguments: {'id': producto.id});
Get.back();
```

---

### 🎮 `create controller`

Crea **únicamente un GetxController** sin vista ni binding.

```bash
cleanarch create controller <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` |
| `--module` | `-m` | Módulo donde colocar el controller | — (global) |
| `--overwrite` | `-f` | Sobreescribir si ya existe | `false` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |

**Alias:** `ctrl` — el sufijo "Controller" en el nombre se elimina automáticamente
para evitar `ProductoControllerController`.

```bash
cleanarch create controller auth
cleanarch create controller carrito_global --module carrito
cleanarch create controller SessionController   # genera SessionController (sin duplicar)
```

---

### 🧱 `create widget`

Crea un **widget reutilizable** de forma individual. Puede ser un widget global (en
`widgets/`) o ligado a un módulo específico (en `modules/<nombre>/widgets/`).
Soporta widgets `StatelessWidget` (por defecto) y `StatefulWidget` con `--stateful`.

```bash
cleanarch create widget <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` |
| `--module` | `-m` | Módulo al que pertenece el widget | — (global) |
| `--global` | `-g` | Fuerza ubicación global (`app/widgets/`) | `false` |
| `--stateful` | — | Genera `StatefulWidget` en lugar de `StatelessWidget` | `false` |
| `--overwrite` | `-f` | Sobreescribir si ya existe | `false` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |

**Ejemplos:**

```bash
# Widget global reutilizable (en app/widgets/)
cleanarch create widget app_button --global

# Widget para un módulo específico (en modules/home/widgets/)
cleanarch create widget home_card --module home

# Widget con estado (StatefulWidget)
cleanarch create widget counter --module home --stateful

# Ver qué se generaría sin crear nada
cleanarch create widget app_button --global --dry-run
```

**Archivos generados:**

```
# --global
lib/app/widgets/
└── app_button.dart

# --module home
lib/app/modules/home/widgets/
└── home_card.dart
```

---

### 🗄️ `create table`

Genera una **tabla de base de datos** completa con su DAO (o equivalente según el ORM del proyecto),
e **inyecta automáticamente** los archivos en `AppDatabase` y `DatabaseService`.
El ORM se detecta automáticamente leyendo el `pubspec.yaml`.

```bash
cleanarch create table <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` |
| `--dry-run` | — | Lista los archivos que se generarían sin crearlos | `false` |

**Alias:** `tbl`

**Archivos generados y acciones por ORM:**

| ORM | Archivos generados | Inyecciones automáticas |
|-----|--------------------|-------------------------|
| **Drift** | `*_table.dart` + `*_dao.dart` | `@DriftDatabase(tables, daos)`, imports en `AppDatabase`, getter en `DatabaseService` |
| **Isar** | `*_collection.dart` | Schema en `Isar.open([...])`, import en `AppDatabase`, `IsarCollection<T>` getter en `DatabaseService` |
| **Sqflite** | `*_model.dart` + `*_dao.dart` | `CREATE TABLE` SQL en `_onCreate`, import + getter en `DatabaseService` |
| **ObjectBox** | `*_entity.dart` | Import + `Box<T>` getter en `DatabaseService` (ObjectBox descubre entidades automáticamente) |
| **Floor** | `*_entity.dart` + `*_dao.dart` | `entities: []` en `@Database`, getter abstracto en `AppFloorDatabase`, import + getter en `DatabaseService` |

**Ejemplos:**

```bash
# Detecta el ORM automáticamente desde pubspec.yaml
cleanarch create table tarea

# Especificando la ruta del proyecto
cleanarch create table categoria --path ./mi_app

# Ver qué se generaría sin crear nada
cleanarch create table producto --dry-run

# Alias
cleanarch create tbl usuario
```

**Flujo completo con Drift:**

```bash
# 1. Crear la tabla (inyecta en AppDatabase y DatabaseService)
cleanarch create table tarea

# 2. Abrir tarea_table.dart y definir las columnas
# 3. Regenerar el código generado por Drift
dart run build_runner build --delete-conflicting-outputs

# 4. Usar el DAO desde cualquier parte del código
final dao = Get.find<DatabaseService>().tareaDao;
final tareas = await dao.getAll();
await dao.insert(TareasCompanion(/* campos */));
```

> 📖 Al crear el proyecto con `--datasource local` o `--datasource both`, se genera
> automáticamente un archivo `docs/DATABASE.md` con guías completas de CRUD básico,
> relaciones, queries avanzadas y migraciones para el ORM elegido.

---

### 🧪 `create test`

Genera **archivos de prueba** (unit tests y widget tests) para un módulo o feature existente.
Usa `mockito` con `@GenerateMocks` para generar los mocks automáticamente.

```bash
cleanarch create test <nombre> [opciones]
```

| Opción | Abreviación | Descripción | Valor por defecto |
|--------|-------------|-------------|-------------------|
| `--type` | `-t` | Tipo de test: `all`, `controller`, `usecase`, `repository`, `widget` | `all` |
| `--path` | `-p` | Ruta raíz del proyecto Flutter | `.` (carpeta actual) |
| `--feature` | `-f` | Genera tests para un feature ligero (en lugar de un módulo completo) | `false` |

**Ejemplos:**

```bash
# Todos los tests de un módulo (controller + usecase + repository + widget)
cleanarch create test producto

# Solo el controller test
cleanarch create test producto --type controller

# Solo el widget test
cleanarch create test producto --type widget

# Tests para un feature (ligero: controller + widget)
cleanarch create test dashboard --feature

# Especificando la ruta del proyecto
cleanarch create test carrito --path D:\Proyectos\mi_app
```

**Archivos generados para un módulo (`cleanarch create test producto`):**

```
test/
└── app/
    ├── modules/
    │   └── producto/
    │       ├── controllers/
    │       │   └── producto_controller_test.dart   ← unit test con mock del UseCase
    │       └── views/
    │           └── producto_view_test.dart          ← widget test
    ├── domain/
    │   └── usecases/
    │       └── get_all_productos_usecase_test.dart  ← unit test con mock del Repository
    └── data/
        └── repositories/
            └── producto_repository_impl_test.dart  ← unit test con mock del Provider
```

**Archivos generados para un feature (`--feature`):**

```
test/
└── app/
    └── features/
        └── dashboard/
            ├── controllers/
            │   └── dashboard_controller_test.dart
            └── views/
                └── dashboard_view_test.dart
```

**Flujo completo de trabajo con tests:**

```bash
# 1. Crea el módulo
cleanarch create module producto

# 2. Genera los tests
cleanarch create test producto

# 3. Genera los mocks con build_runner
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecuta los tests
flutter test
flutter test --coverage
```

> **Nota:** Los archivos `*.mocks.dart` se generan automáticamente con `build_runner`
> y están en `.gitignore`. No los edites ni los subas al repositorio.

Los proyectos generados con `cleanarch create project` ya incluyen `mockito` y
`build_runner` en las `dev_dependencies`, por lo que no es necesario agregarlos manualmente.

---

### 🔄 `update`

Actualiza cleanarch a la última versión disponible sin salir de la terminal.

```bash
cleanarch update
```

Requiere tener Dart instalado (Opción B de instalación). El comando ejecuta
`dart pub global activate clean_arch_cli` internamente y muestra el resultado.

---

## Opciones globales

Estas opciones se pueden usar con cualquier comando:

| Opción | Abreviación | Descripción |
|--------|-------------|-------------|
| `--help` | `-h` | Muestra la ayuda del comando |
| `--version` | `-v` | Muestra la versión del CLI |
| `--verbose` | `-V` | Muestra el stack trace completo en caso de error |
| `--quiet` | `-q` | Suprime la salida informativa (solo errores y resultado final) |

```bash
# Modo silencioso para CI/scripts (solo imprime errores y el resultado)
cleanarch create module producto --quiet

# Ver el stack trace completo al depurar un error
cleanarch create module producto --verbose
```

---

## Shell completion

cleanarch incluye autocompletado para bash, zsh y fish. Se instala una vez:

```bash
cleanarch completion install
```

Después de instalar (y reiniciar la terminal), puedes usar Tab para autocompletar
comandos, subcomandos y opciones:

```bash
cleanarch create <Tab>        # muestra: project, module, feature, screen, controller, widget, table, test
cleanarch create module <Tab> # muestra: --path, --datasource, --http-lib, --storage-lib, --dry-run, ...
cleanarch create table <Tab>  # muestra: --path, --dry-run
```

---

## Inyección automática de rutas

Al crear un módulo, feature o screen, el CLI modifica automáticamente
`app_pages.dart` y `app_routes.dart`. No es necesario tocarlos manualmente.

### Estructura de rutas generada

Todas las pantallas son **hijos de home**. Los módulos tienen su propio bloque
`children` donde se añaden sus screens:

```dart
// app_routes.dart — constantes inyectadas automáticamente
abstract class Routes {
  static const home     = '/home';
  static const producto = '/producto';   // ← cleanarch create module producto
  static const carrito  = '/carrito';    // ← cleanarch create module carrito
  static const detalle  = '/detalle';    // ← cleanarch create screen detalle --module producto
  // cleanarch:route
}

// app_pages.dart — GetPages inyectadas automáticamente
class AppPages {
  static const initial = Routes.home;

  static final routes = <GetPage>[
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      children: [

        GetPage(
          name: Routes.producto,
          page: () => const ProductoView(),
          binding: ProductoBinding(),
          children: [
            GetPage(                              // ← create screen detalle --module producto
              name: Routes.detalle,
              page: () => const DetalleScreen(),
              binding: DetalleBinding(),
            ),
            // cleanarch:inject:producto
          ],
        ),

        GetPage(
          name: Routes.carrito,
          page: () => const CarritoView(),
          binding: CarritoBinding(),
          children: [
            // cleanarch:inject:carrito
          ],
        ),

        // cleanarch:inject  ← nuevos módulos y features se añaden aquí
      ],
    ),
  ];
}
```

### Marcadores usados por el CLI

El CLI usa comentarios especiales en los archivos de rutas para saber dónde insertar:

| Marcador | Archivo | Qué se inserta |
|----------|---------|----------------|
| `// cleanarch:import` | `app_pages.dart` | Imports de nuevas Views y Bindings |
| `// cleanarch:inject` | `app_pages.dart` | GetPage de módulos y features (hijos de home) |
| `// cleanarch:inject:nombre` | `app_pages.dart` | GetPage de screens (hijos del módulo `nombre`) |
| `// cleanarch:route` | `app_routes.dart` | Nuevas constantes de ruta |

> Si eliminas un marcador, el CLI avisará y mostrará los pasos para agregar la ruta manualmente.

---

## Plataformas objetivo

Al crear un proyecto el CLI pregunta para qué plataforma(s) vas a desarrollar.
Internamente ejecuta `flutter create --platforms <selección>` para generar las carpetas
nativas correctas desde el inicio.

### Atajos disponibles

| Atajo | Equivale a |
|-------|-----------|
| `mobile` *(defecto)* | `android,ios` |
| `all` | `android,ios,web,windows,linux,macos` |

### Menú interactivo (`-i`)

```
  Plataformas objetivo
  ¿Para qué sistema(s) operativo(s) vas a desarrollar?

  1.  Android + iOS                                     android, ios
  2.  Android solamente                                 android
  3.  iOS solamente                                     ios
  4.  Android + iOS + Web                               android, ios, web
  5.  Escritorio (Windows, Linux, macOS)                windows, linux, macos
  6.  Multi-plataforma (Android + iOS + Web + Escritorio)
  7.  Personalizado  (escribe las plataformas separadas por coma)
```

### Flag `--platforms` (no interactivo)

```bash
cleanarch create project mi_app --platforms android
cleanarch create project mi_app --platforms android,ios,web
cleanarch create project mi_app --platforms windows,linux,macos
cleanarch create project mi_app --platforms mobile   # atajo: android,ios
cleanarch create project mi_app --platforms all      # todas las plataformas
```

### Dependencias específicas por plataforma

Cuando se seleccionan **2 o más categorías de plataforma** (móvil + escritorio, móvil + web, etc.),
el menú de dependencias muestra automáticamente una sección adicional con paquetes
recomendados para cada plataforma seleccionada. La numeración es continua con el catálogo general.

**Ejemplo: Android + iOS + Windows**

```
  Dependencias externas
  GetX ya está incluido. Selecciona paquetes adicionales:

  Almacenamiento local
    1. get_storage         ^2.1.1    Storage ligero compatible con GetX
   ...
   23. json_annotation     ^4.9.0    Genera fromJson/toJson automáticamente

  Específicos por plataforma
  Recomendados según las plataformas seleccionadas (android, ios, windows, linux, macos):

  📱 Móvil — Android / iOS
   24. geolocator                   ^13.0.2   GPS y ubicación en tiempo real
   25. flutter_local_notifications  ^18.0.1   Notificaciones locales programadas
   26. camera                       ^0.11.0+2 Acceso directo a la cámara
   27. share_plus                   ^10.1.2   Compartir con otras apps
   28. sensors_plus                 ^6.1.0    Acelerómetro, giroscopio y magnetómetro
   29. local_auth                   ^2.3.0    Autenticación biométrica (huella, Face ID)

  🖥️  Escritorio — Windows / Linux / macOS
   30. window_manager               ^0.4.3    Control de ventana: tamaño, título, siempre al frente
   31. file_picker                  ^8.1.3    Selector de archivos y carpetas del sistema
   32. desktop_drop                 ^0.4.4    Arrastrar y soltar archivos (drag & drop)
   33. system_tray                  ^2.0.3    Ícono en la bandeja del sistema (system tray)
   34. hotkey_manager               ^0.2.3    Atajos de teclado globales del sistema
   35. launch_at_startup            ^0.3.0    Lanzar la app automáticamente al iniciar

Ingresa los números separados por comas (Enter para ninguna): 5,24,30,31
```

**Categorías y cuándo aparecen:**

| Sección | Aparece cuando seleccionas... |
|---------|-------------------------------|
| 📱 Móvil | `android` o `ios` + al menos otra categoría |
| 🖥️ Escritorio | `windows`, `linux` o `macos` (siempre que haya 2+ categorías) |
| 🌐 Web | `web` + al menos otra categoría |

> Si solo eliges una categoría (ej. solo `android,ios`) el menú muestra únicamente
> el catálogo general de 23 paquetes, sin sección de específicos.

---

## Dependencias externas

Al crear un proyecto puedes seleccionar qué paquetes incluir. El CLI tiene dos métodos:

### 1. Catálogo interactivo (`-i`)

En modo interactivo se muestra un menú numerado por categorías. Si seleccionaste
**2 o más categorías de plataforma**, aparece una sección adicional al final con paquetes
específicos por plataforma (ver [Plataformas objetivo](#plataformas-objetivo)).

**Catálogo general (23 paquetes, siempre visible):**

```
  Dependencias externas
  GetX ya está incluido. Selecciona paquetes adicionales:

  Almacenamiento local
    1. get_storage              ^2.1.1    Storage ligero compatible con GetX
    2. shared_preferences       ^2.3.2    Key-value storage simple
    3. hive_flutter             ^1.1.0    Base de datos NoSQL local
    4. flutter_secure_storage   ^9.2.2    Almacenamiento seguro (keychain/keystore)

  Red & API
    5. dio                      ^5.7.0    Cliente HTTP avanzado con interceptores
    6. connectivity_plus        ^6.1.0    Detectar conexión a internet

  UI & Medios
    7. flutter_svg              ^2.0.10+1 Imágenes SVG
    8. cached_network_image     ^3.4.1    Imágenes de red con caché
    9. shimmer                  ^3.0.0    Efecto skeleton/shimmer
   10. lottie                   ^3.1.0    Animaciones Lottie
   11. image_picker             ^1.1.2    Galería y cámara

  Utilidades
   12. intl                     ^0.19.0   Formatos de fecha/número/moneda
   13. equatable                ^2.0.5    Comparación de objetos por valor
   14. logger                   ^2.4.0    Logs con colores y niveles
   15. flutter_dotenv           ^5.2.1    Variables de entorno desde .env
   16. permission_handler       ^11.3.1   Solicitar permisos en runtime
   17. url_launcher             ^6.3.1    Abrir URLs, emails, llamadas

  Firebase
   18. firebase_core            ^3.6.0    Base para todos los servicios Firebase
   19. firebase_auth            ^5.3.1    Autenticación Firebase
   20. cloud_firestore          ^5.4.4    Base de datos en tiempo real
   21. firebase_messaging       ^15.1.3   Notificaciones push (FCM)
   22. firebase_storage         ^12.3.2   Almacenamiento de archivos

  Serialización JSON
   23. json_annotation          ^4.9.0    Genera fromJson/toJson automáticamente
       ↳ incluye dev: json_serializable, build_runner

Ingresa los números separados por comas (Enter para ninguna): 5,8,18,19
```

Después del menú numerado, se pregunta por **paquetes que no están en la lista**:

```
Paquetes personalizados que no están en la lista:
  • Con versión  → se escriben en pubspec.yaml   (ej: flutter_map:^7.0.1)
  • Solo nombre  → se agregan con flutter pub add (ej: pusher_channels)
> flutter_map:^7.0.1, pusher_channels
```

### 2. Flag `--deps`

Acepta nombres del catálogo y paquetes personalizados en el mismo flag:

```bash
# Del catálogo (usa la versión del catálogo)
cleanarch create project mi_app --deps dio,lottie,firebase_core

# Con versión específica (se escribe en pubspec.yaml)
cleanarch create project mi_app --deps "flutter_map:^7.0.1"

# Solo nombre fuera del catálogo (usa flutter pub add → versión más reciente)
cleanarch create project mi_app --deps pusher_channels

# Mezclado
cleanarch create project mi_app --deps "dio,flutter_map:^7.0.1,pusher_channels"
```

### Comportamiento según el tipo de entrada

| Entrada | Resultado |
|---------|-----------|
| `dio` (en catálogo) | Escribe `dio: ^5.7.0` en `pubspec.yaml` |
| `flutter_map:^7.0.1` (versión manual) | Escribe `flutter_map: ^7.0.1` en `pubspec.yaml` |
| `pusher_channels` (sin versión, fuera de catálogo) | Ejecuta `flutter pub add pusher_channels` → resuelve la última versión compatible |
| `json_annotation` (catálogo con dev deps) | Escribe en `dependencies` + agrega `json_serializable` y `build_runner` en `dev_dependencies` |

### Diferencia entre `flutter pub get` y `flutter pub add`

| Comando | Qué hace |
|---------|----------|
| `flutter pub get` | Instala los paquetes ya listados en `pubspec.yaml` |
| `flutter pub add nombre` | Añade un paquete nuevo a `pubspec.yaml` **y** lo instala con la versión más reciente compatible |

---

## Estructura del proyecto generado

```
mi_app/
├── lib/
│   ├── main.dart                             ← Entrada de la app + GetMaterialApp
│   └── app/
│       ├── core/
│       │   ├── bindings/
│       │   │   └── initial_binding.dart      ← Servicios globales (ApiClient, etc.)
│       │   ├── constants/
│       │   │   ├── app_constants.dart
│       │   │   ├── app_colors.dart
│       │   │   └── app_text_styles.dart
│       │   ├── database/                     ← Solo si --datasource local|both
│       │   │   ├── app_database.dart         ← Configuración del ORM (Drift, Floor, etc.)
│       │   │   └── tables/                   ← create table → *_table.dart / *_dao.dart
│       │   ├── errors/
│       │   │   └── failures.dart             ← ServerFailure, NetworkFailure, etc.
│       │   ├── network/
│       │   │   └── api_client.dart           ← Cliente HTTP (GetConnect / Dio)
│       │   ├── services/
│       │   │   ├── database_service.dart     ← Solo si --datasource local|both
│       │   │   └── settings_service.dart     ← Solo si se usa doble storage
│       │   ├── theme/
│       │   │   └── app_theme.dart
│       │   └── utils/
│       ├── data/
│       │   ├── models/
│       │   ├── providers/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── modules/                          ← create module
│       ├── features/                         ← create feature
│       ├── screens/                          ← create screen (global)
│       ├── controllers/                      ← create controller (global)
│       ├── widgets/                          ← create widget --global
│       ├── routes/
│       │   ├── app_pages.dart                ← Rutas con inyección automática
│       │   └── app_routes.dart               ← Constantes de rutas
│       └── translations/
│           └── app_translations.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── docs/
│   └── DATABASE.md                           ← Solo si --datasource local|both (guía del ORM)
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

---

## Capas de Clean Architecture

```
╔══════════════════════════════════════╗
║         PRESENTATION                 ║  ← Lo que ve el usuario
║   (Controllers, Bindings, Views)     ║
╠══════════════════════════════════════╣
║              DOMAIN                  ║  ← Las reglas del negocio
║   (Entities, Repositories, UseCases) ║
╠══════════════════════════════════════╣
║               DATA                   ║  ← Los datos reales
║   (Models, Providers, RepoImpl)      ║
╚══════════════════════════════════════╝
```

- Cambias de REST a GraphQL → solo cambia `Data`.
- Rediseñas la UI → solo cambia `Presentation`.
- Cada capa se prueba por separado.

### 1. Domain — El corazón del negocio

```dart
// Entidad: objeto de negocio puro, sin imports externos
class ProductoEntity {
  final String id;
  final String nombre;
  final double precio;
  const ProductoEntity({required this.id, required this.nombre, required this.precio});
}

// Repositorio: contrato (interfaz) — define qué se puede hacer
abstract class ProductoRepository {
  Future<List<ProductoEntity>> getAll();
  Future<ProductoEntity?> getById(String id);
}

// UseCase: una acción = un archivo
class GetAllProductosUseCase {
  final ProductoRepository _repository;
  GetAllProductosUseCase(this._repository);
  Future<List<ProductoEntity>> call() => _repository.getAll();
}
```

### 2. Data — La fuente de datos

```dart
// Model: traduce JSON ↔ Entidad
class ProductoModel extends ProductoEntity {
  factory ProductoModel.fromJson(Map<String, dynamic> json) => ProductoModel(
    id: json['id'] as String,
    nombre: json['name'] as String,   // campo diferente en el servidor
    precio: json['price'] as double,
  );
  Map<String, dynamic> toJson() => {'id': id, 'name': nombre, 'price': precio};
}

// Provider: llamadas HTTP, devuelve datos crudos
class ProductoProvider {
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final response = await Get.find<ApiClient>().get('/productos');
    return List<Map<String, dynamic>>.from(response.body as List);
  }
}

// RepositoryImpl: une Provider + Model, implementa el contrato
class ProductoRepositoryImpl implements ProductoRepository {
  final ProductoProvider _provider;
  ProductoRepositoryImpl(this._provider);

  @override
  Future<List<ProductoEntity>> getAll() async {
    final data = await _provider.fetchAll();
    return data.map((json) => ProductoModel.fromJson(json)).toList();
  }
}
```

### 3. Presentation — Lo que ve el usuario

```dart
// Controller: estado reactivo y lógica de pantalla
class ProductoController extends GetxController {
  final GetAllProductosUseCase _getAllProductos;
  final RxList<ProductoEntity> items = <ProductoEntity>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() { super.onInit(); fetchAll(); }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try { items.value = await _getAllProductos(); }
    finally { isLoading.value = false; }
  }
}

// Binding: registra las dependencias antes de mostrar la pantalla
class ProductoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductoProvider>(() => ProductoProvider());
    Get.lazyPut<ProductoRepository>(() => ProductoRepositoryImpl(Get.find()));
    Get.lazyPut(() => GetAllProductosUseCase(Get.find()));
    Get.lazyPut<ProductoController>(() => ProductoController(Get.find()));
  }
}

// View: UI reactiva
class ProductoView extends GetView<ProductoController> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Productos')),
    body: Obx(() => controller.isLoading.value
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          itemCount: controller.items.length,
          itemBuilder: (_, i) => ListTile(title: Text(controller.items[i].nombre)),
        ),
    ),
  );
}
```

### 4. Core — Servicios globales

| Archivo | Descripción |
|---------|-------------|
| `core/network/api_client.dart` | Cliente HTTP global (GetConnect / Dio) con URL base, headers y manejo de errores 401 |
| `core/bindings/initial_binding.dart` | Servicios permanentes registrados antes de la primera pantalla |
| `core/services/database_service.dart` | Acceso a los DAOs / colecciones del ORM (solo con `--datasource local\|both`) |
| `core/services/settings_service.dart` | Wrapper de storage key-value (solo con doble storage) |
| `core/database/app_database.dart` | Inicialización y registro del ORM elegido (Drift, Floor, Isar, Sqflite, ObjectBox) |
| `core/theme/app_theme.dart` | Tema claro y oscuro (Material 3) |
| `core/constants/app_colors.dart` | Paleta de colores centralizada |
| `core/constants/app_text_styles.dart` | Estilos de texto reutilizables |
| `core/constants/app_constants.dart` | Constantes globales (nombre app, storage keys) |
| `core/errors/failures.dart` | Tipos de error tipados: `ServerFailure`, `NetworkFailure`, `CacheFailure` |

### 5. Routes — La navegación

```dart
Get.toNamed(Routes.producto);
Get.toNamed(Routes.detalle, arguments: {'id': '123'});
Get.back();
Get.offAllNamed(Routes.home);
```

---

## Flujo de datos completo

```
1. GetX ejecuta ProductoBinding.dependencies()
      → Crea: ProductoProvider → ProductoRepositoryImpl → GetAllProductosUseCase → ProductoController

2. GetX muestra ProductoView
      → ProductoView accede a `controller` (inyectado automáticamente por GetView)

3. GetxController.onInit() se ejecuta
      → Llama: controller.fetchAll()

4. fetchAll() ejecuta el UseCase
      → items = await _getAllProductos()

5. UseCase llama al Repository por su contrato
      → _repository.getAll()

6. RepositoryImpl llama al Provider
      → _provider.fetchAll()

7. Provider hace la llamada HTTP via ApiClient
      → GET /productos → JSON crudo

8. RepositoryImpl convierte JSON → Entidades
      → ProductoModel.fromJson(json)

9. items.value = [entidades]
      → Obx() detecta el cambio y redibuja solo el ListView
```

---

## Diferencias: Module vs Feature vs Screen

| | `module` | `feature` | `screen` |
|--|---------|-----------|---------|
| **Capas** | Domain + Data + Presentation | Solo Presentation | Solo Presentation |
| **Genera** | Entity, Repository, UseCases, Model, Provider, RepositoryImpl, Controller, Binding, View | Controller, Binding, View | Controller, Binding, Screen |
| **Ruta** | Hijo de home con `children` propios | Hijo de home (sin children) | Hijo del módulo padre o de home |
| **Cuándo usarlo** | CRUD con datos propios (Productos, Órdenes) | Pantalla sin datos propios (Dashboard, Splash) | Sub-pantalla (Detalle, Formulario) |
| **Ubicación** | `modules/` + `domain/` + `data/` | `features/<nombre>/` | `screens/<nombre>/` o `modules/<mod>/screens/` |
| **Tests** | `create test <nombre>` → 4 archivos | `create test <nombre> --feature` → 2 archivos | — |

---

## Estructura del CLI

```
clean_arch_cli/
├── bin/
│   └── main.dart
├── bricks/                                    ← Fuente de verdad de los templates
│   ├── module/                                ← brick de módulo (9 archivos)
│   │   ├── brick.yaml
│   │   ├── __brick__/lib/app/...              ← archivos .dart.mustache
│   │   └── hooks/pre_gen.dart                 ← computa plural, is_rest, is_local…
│   ├── feature/                               ← brick de feature (3 archivos)
│   ├── screen/                                ← brick de screen (3 archivos)
│   │   └── hooks/pre_gen.dart                 ← resuelve import_path según módulo padre
│   ├── controller/                            ← brick de controller standalone
│   ├── test_module/                           ← brick de tests para módulo (4 archivos)
│   │   └── hooks/pre_gen.dart                 ← computa plural para nombres de tests
│   └── test_feature/                          ← brick de tests para feature (2 archivos)
├── lib/
│   ├── clean_arch_cli.dart
│   └── src/
│       ├── runner.dart                        ← CompletionCommandRunner + banner
│       ├── version.dart                       ← const cliVersion (fuente de verdad)
│       ├── commands/
│       │   ├── create_command.dart
│       │   ├── create_project_command.dart    ← cleanarch create project
│       │   ├── create_module_command.dart     ← cleanarch create module
│       │   ├── create_feature_command.dart    ← cleanarch create feature
│       │   ├── create_screen_command.dart     ← cleanarch create screen | page
│       │   ├── create_controller_command.dart ← cleanarch create controller | ctrl
│       │   ├── create_widget_command.dart     ← cleanarch create widget
│       │   ├── create_table_command.dart      ← cleanarch create table | tbl
│       │   ├── create_test_command.dart       ← cleanarch create test
│       │   ├── update_command.dart            ← cleanarch update
│       │   └── storage_lib_menu.dart          ← menú interactivo de storage
│       ├── generators/
│       │   ├── mason_target.dart              ← GeneratorTarget con dry-run y overwrite
│       │   ├── file_writer.dart               ← Escribe archivos (project_generator)
│       │   ├── project_generator.dart         ← Proyecto completo
│       │   ├── module_generator.dart          ← Módulo (3 capas) vía Mason
│       │   ├── feature_generator.dart         ← Feature ligero vía Mason
│       │   ├── screen_generator.dart          ← Sub-pantalla vía Mason
│       │   ├── controller_generator.dart      ← Controller standalone vía Mason
│       │   ├── widget_generator.dart          ← Widget reutilizable vía Mason
│       │   ├── table_generator.dart           ← Tabla ORM + inyección en AppDatabase y DatabaseService
│       │   ├── route_injector.dart            ← Inyección automática de rutas
│       │   └── test_generator.dart            ← Tests (unit + widget) vía Mason
│       ├── bundles/                           ← Generados por tool/generate_bundles.dart
│       │   ├── module_bundle.dart
│       │   ├── feature_bundle.dart
│       │   ├── screen_bundle.dart
│       │   ├── controller_bundle.dart
│       │   ├── widget_bundle.dart
│       │   ├── test_module_bundle.dart
│       │   └── test_feature_bundle.dart
│       ├── templates/
│       │   ├── module_templates.dart          ← providers, packages por ORM
│       │   ├── project_templates.dart         ← main.dart, pubspec, app.dart, etc.
│       │   ├── service_templates.dart         ← AppDatabase y DatabaseService por ORM
│       │   ├── table_templates.dart           ← tabla/colección/entidad + DAO por ORM
│       │   └── database_doc_templates.dart    ← docs/DATABASE.md por ORM
│       └── utils/
│           ├── console.dart                   ← Output ANSI con colores y modo quiet
│           ├── string_ext.dart                ← toSnakeCase, toPascalCase, toPlural…
│           ├── project_utils.dart             ← Lee package_name del pubspec.yaml
│           └── flutter_packages.dart          ← Catálogo de paquetes (incluye ORMs)
├── tool/
│   └── generate_bundles.dart                  ← Regenera lib/src/bundles/ desde bricks/
├── pubspec.yaml
└── analysis_options.yaml
```

> **Nota sobre templates:** Los archivos generados usan siempre imports del tipo
> `package:<nombre_app>/...` (nunca imports relativos `../`), cumpliendo la regla
> `always_use_package_imports` del análisis estático de Dart.

---

## Archivos generados por capa

| Archivo | Capa | Propósito |
|---------|------|-----------|
| `*_entity.dart` | Domain | Objeto de negocio puro. Sin dependencias externas. |
| `*_repository.dart` | Domain | Contrato (interfaz) con las operaciones disponibles. |
| `get_all_*_usecase.dart` | Domain | Caso de uso: obtener lista completa. |
| `get_*_by_id_usecase.dart` | Domain | Caso de uso: buscar por ID. |
| `*_model.dart` | Data | Extiende Entity. Traduce JSON ↔ Entidad. |
| `*_provider.dart` | Data | Llamadas HTTP. Devuelve datos crudos. |
| `*_repository_impl.dart` | Data | Implementa el contrato del Domain. |
| `*_controller.dart` | Presentation | Estado reactivo (.obs) y acciones de la pantalla. |
| `*_binding.dart` | Presentation | Inyección de dependencias antes de mostrar la pantalla. |
| `*_view.dart` | Presentation | UI reactiva con `GetView` + `Obx`. |
| `*_screen.dart` | Presentation | Sub-pantalla secundaria (detalle, formulario, etc.). |
| `*_widget.dart` | Presentation | Widget reutilizable (Stateless o Stateful). |
| `*_table.dart` / `*_collection.dart` / `*_entity.dart` | Database | Esquema de tabla para el ORM del proyecto. |
| `*_dao.dart` | Database | Acceso a datos: CRUD listo para usar (Drift, Floor, Sqflite). |
| `app_database.dart` | Core/Database | Inicialización y registro del ORM (generado con `create project`). |
| `database_service.dart` | Core/Services | Expone los DAOs / colecciones del ORM al resto de la app. |
| `app_pages.dart` | Routes | Registro de rutas con inyección automática. |
| `app_routes.dart` | Routes | Constantes de paths de navegación. |
| `api_client.dart` | Core/Network | Cliente HTTP global con interceptores. |
| `initial_binding.dart` | Core/Bindings | Servicios globales permanentes. |
| `app_theme.dart` | Core/Theme | Tema claro y oscuro con Material 3. |
| `app_colors.dart` | Core/Constants | Paleta de colores centralizada. |
| `app_text_styles.dart` | Core/Constants | Estilos de texto reutilizables. |
| `app_constants.dart` | Core/Constants | Constantes globales. |
| `failures.dart` | Core/Errors | Tipos de error tipados. |
| `app_translations.dart` | Translations | Textos en es_MX / en_US. |

---

## Licencia

MIT © [RamonChenoDev](https://github.com/RamonChenoDev)
