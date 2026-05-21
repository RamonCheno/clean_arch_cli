# CONTEXT — CleanArch CLI (Sesión de desarrollo)

> Este archivo resume todo el contexto de desarrollo del proyecto `clean_arch_cli`.
> Léelo al inicio de una nueva sesión para retomar el trabajo sin perder contexto.

---

## ¿Qué es este proyecto?

`clean_arch_cli` es una CLI escrita en **Dart** que genera automáticamente la estructura de
carpetas y archivos boilerplate para proyectos Flutter siguiendo **Clean Architecture + GetX**.

- Comando principal: `cleanarch`
- Versión actual: `1.1.0`
- Autor: RamonChenoDev
- Ejecutable compilado: `bin/cleanarch.exe` (AOT, no requiere Dart instalado)

---

## Estado actual del proyecto

Todo está implementado y funcional. El ejecutable `bin/cleanarch.exe` está compilado y listo.

---

## Estructura de archivos del CLI

```
clean_arch_cli/
├── bin/
│   ├── main.dart                          ← Entrada: llama a CleanArchRunner
│   └── cleanarch.exe                      ← Ejecutable compilado (distribuir esto)
├── lib/
│   ├── clean_arch_cli.dart
│   └── src/
│       ├── runner.dart                    ← CommandRunner + banner ASCII + _printHelp()
│       ├── commands/
│       │   ├── create_command.dart        ← Comando padre "create"
│       │   ├── create_project_command.dart
│       │   ├── create_module_command.dart
│       │   ├── create_feature_command.dart
│       │   ├── create_screen_command.dart    ← alias: page
│       │   ├── create_controller_command.dart ← alias: ctrl
│       │   └── create_test_command.dart
│       ├── generators/
│       │   ├── file_writer.dart           ← Escribe archivos (overwrite: true/false)
│       │   ├── project_generator.dart     ← Proyecto completo + flutter create
│       │   ├── module_generator.dart      ← Módulo 3 capas
│       │   ├── feature_generator.dart     ← Feature ligero (solo Presentation)
│       │   ├── screen_generator.dart      ← Sub-pantalla
│       │   ├── controller_generator.dart  ← Controller standalone
│       │   ├── route_injector.dart        ← Inyección automática en app_pages/app_routes
│       │   └── test_generator.dart        ← Tests con mockito
│       ├── templates/
│       │   ├── project_templates.dart     ← pubspec, main, theme, core, routes...
│       │   ├── module_templates.dart      ← entity, repo, usecase, model, provider, controller...
│       │   ├── screen_templates.dart      ← screen, binding, controller de pantalla
│       │   └── test_templates.dart        ← unit tests y widget tests con mockito
│       └── utils/
│           ├── console.dart              ← Output ANSI (header, step, success, error, warning)
│           ├── string_ext.dart           ← toSnakeCase, toPascalCase, toPlural, isValidIdentifier
│           └── flutter_packages.dart     ← Catálogo de paquetes Flutter
├── pubspec.yaml
├── analysis_options.yaml
├── README.md                             ← Documentación completa para usuarios
└── CONTEXT.md                            ← Este archivo
```

---

## Comandos disponibles

| Comando | Alias | Descripción |
|---------|-------|-------------|
| `cleanarch create project <nombre>` | — | Proyecto Flutter completo con Clean Architecture |
| `cleanarch create module <nombre>` | — | Módulo completo (Domain + Data + Presentation) |
| `cleanarch create feature <nombre>` | — | Feature ligero (solo Presentation) |
| `cleanarch create screen <nombre>` | `page` | Sub-pantalla dentro de un módulo |
| `cleanarch create controller <nombre>` | `ctrl` | Solo un GetxController |
| `cleanarch create test <nombre>` | — | Archivos de prueba con mockito |
| `cleanarch --help` | `-h` | Muestra ayuda personalizada completa |
| `cleanarch --version` | `-v` | Muestra la versión |

---

## Detalle de cada comando

### `create project`

Opciones:
- `--org` / `-o` → Bundle ID (default: `dev.ramonchenodev`)
- `--output` / `-d` → Carpeta de salida (default: `.`)
- `--modules` / `-m` → Módulos iniciales separados por coma (default: `home`)
- `--platforms` / `-l` → Plataformas (default: `mobile` = android,ios)
  - Atajos: `mobile` = android,ios | `all` = todas las plataformas
  - Valores: `android`, `ios`, `web`, `windows`, `linux`, `macos`
- `--deps` → Paquetes a incluir (del catálogo o con versión manual)
- `--interactive` / `-i` → Modo interactivo (pregunta todo por consola)

Internamente hace:
1. `flutter create --org <org> --platforms <platforms> <name>` (Process.runSync)
2. Sobreescribe main.dart, pubspec.yaml con templates de Clean Architecture
3. Genera core, routes, translations, assets
4. Genera los módulos indicados
5. Si hay `_pubAddNames`, ejecuta `flutter pub add` para cada uno

**IMPORTANTE:** `ProjectGenerator` usa `FileWriter(overwrite: true)` para poder
sobreescribir los archivos que genera `flutter create`.

### `create module`

Opciones:
- `--path` / `-p` → Ruta raíz del proyecto Flutter (default: `.`)
- `--overwrite` / `-f` → Sobreescribir archivos existentes

Genera (para módulo `producto`):
```
lib/app/domain/entities/producto_entity.dart
lib/app/domain/repositories/producto_repository.dart
lib/app/domain/usecases/get_all_productos_usecase.dart
lib/app/domain/usecases/get_producto_by_id_usecase.dart
lib/app/data/models/producto_model.dart
lib/app/data/providers/producto_provider.dart
lib/app/data/repositories/producto_repository_impl.dart
lib/app/modules/producto/controllers/producto_controller.dart
lib/app/modules/producto/bindings/producto_binding.dart
lib/app/modules/producto/views/producto_view.dart
lib/app/modules/producto/widgets/  (.gitkeep)
```

Inyecta automáticamente en `app_routes.dart` y `app_pages.dart`.

### `create feature`

Opciones:
- `--path` / `-p`
- `--overwrite` / `-f`

Genera (para feature `dashboard`):
```
lib/app/features/dashboard/controllers/dashboard_controller.dart
lib/app/features/dashboard/bindings/dashboard_binding.dart
lib/app/features/dashboard/views/dashboard_view.dart
lib/app/features/dashboard/widgets/  (.gitkeep)
```

### `create screen`

Opciones:
- `--path` / `-p`
- `--module` / `-m` → Módulo padre (si omites, va como hijo de home)
- `--overwrite` / `-f`

Con `--module producto`:
```
lib/app/modules/producto/screens/detalle/controllers/detalle_controller.dart
lib/app/modules/producto/screens/detalle/bindings/detalle_binding.dart
lib/app/modules/producto/screens/detalle/views/detalle_screen.dart
```

Inyecta en `children` del módulo padre (`// cleanarch:inject:producto`).

### `create controller`

Opciones:
- `--path` / `-p`
- `--module` / `-m`
- `--overwrite` / `-f`

El sufijo "Controller" en el nombre se elimina automáticamente para evitar duplicados
(`ProductoController` → genera `ProductoController`, no `ProductoControllerController`).

### `create test`

Opciones:
- `--type` / `-t` → `all` (default), `controller`, `usecase`, `repository`, `widget`
- `--path` / `-p`
- `--feature` / `-f` → Flag para indicar que es un feature (no módulo)

Para un módulo genera 4 archivos:
```
test/app/modules/producto/controllers/producto_controller_test.dart
test/app/modules/producto/views/producto_view_test.dart
test/app/domain/usecases/get_all_productos_usecase_test.dart
test/app/data/repositories/producto_repository_impl_test.dart
```

Para un feature genera 2 archivos:
```
test/app/features/dashboard/controllers/dashboard_controller_test.dart
test/app/features/dashboard/views/dashboard_view_test.dart
```

Usa `mockito` con `@GenerateMocks`. Después de generar hay que correr:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
```

---

## Inyección automática de rutas

El `route_injector.dart` busca marcadores especiales en los archivos de rutas:

| Marcador | Archivo | Qué inserta |
|----------|---------|-------------|
| `// cleanarch:route` | `app_routes.dart` | `static const nombre = '/nombre';` |
| `// cleanarch:import` | `app_pages.dart` | Imports de View y Binding |
| `// cleanarch:inject` | `app_pages.dart` | GetPage del módulo/feature (hijo de home) |
| `// cleanarch:inject:nombre` | `app_pages.dart` | GetPage de screen (hijo del módulo `nombre`) |

⚠️ Si se borra un marcador, el CLI avisa y pide hacerlo manualmente.

---

## Catálogo de paquetes (`flutter_packages.dart`)

### Paquetes generales (23, siempre visibles):
- **Almacenamiento local:** get_storage, shared_preferences, hive_flutter, flutter_secure_storage
- **Red & API:** dio, connectivity_plus
- **UI & Medios:** flutter_svg, cached_network_image, shimmer, lottie, image_picker
- **Utilidades:** intl, equatable, logger, flutter_dotenv, permission_handler, url_launcher
- **Firebase:** firebase_core, firebase_auth, cloud_firestore, firebase_messaging, firebase_storage
- **Serialización JSON:** json_annotation (+ dev: json_serializable, build_runner)

### Paquetes por plataforma (se muestran solo si 2+ categorías seleccionadas):
- **Móvil** (android/ios): geolocator, flutter_local_notifications, camera, share_plus, sensors_plus, local_auth
- **Escritorio** (windows/linux/macos): window_manager, file_picker, desktop_drop, system_tray, hotkey_manager, launch_at_startup
- **Web:** url_strategy, web, flutter_web_plugins

### Métodos del catálogo:
- `FlutterPackages.all` → lista general
- `FlutterPackages.mobile` / `.desktop` / `.web` → listas por plataforma
- `FlutterPackages.byName(name)` → busca en todos los catálogos
- `FlutterPackages.platformSectionsFor(platforms)` → devuelve secciones relevantes

---

## Selección de plataformas (flujo interactivo)

Menú interactivo con 7 opciones:
1. Android + iOS (default)
2. Android solamente
3. iOS solamente
4. Android + iOS + Web
5. Escritorio (Windows, Linux, macOS)
6. Multi-plataforma (todas)
7. Personalizado

Atajos por flag: `mobile` → android,ios | `all` → todas

---

## `--help` personalizado

`runner.dart` intercepta `--help`, `-h` y args vacíos para mostrar ayuda propia
(en lugar del output genérico del paquete `args`). Imprime:
- Banner ASCII en cyan
- Versión en amarillo
- Todos los comandos agrupados por categoría
- Alias de cada comando
- Ejemplos con colores
- Lista de `cleanarch help create <comando>`

---

## Cómo compilar el ejecutable

```bash
cd clean_arch_cli
dart pub get
dart compile exe bin/main.dart -o bin/cleanarch.exe
bin/cleanarch.exe --help
```

El `.exe` es autocontenido (~10 MB). Los usuarios no necesitan Dart instalado.

## Cómo distribuir a usuarios (sin Dart)

1. Entregar `bin/cleanarch.exe`
2. Usuario crea carpeta `C:\tools\cleanarch\` y pone el exe ahí
3. Agrega esa carpeta al PATH de Windows
4. Abre terminal nueva → `cleanarch --help`

## Cómo activar globalmente (con Dart)

```bash
dart pub global activate --source path "ruta\al\clean_arch_cli"
# Agregar al PATH: C:\Users\<Usuario>\AppData\Local\Pub\Cache\bin
cleanarch --help
```

---

## Decisiones técnicas importantes

| Decisión | Razón |
|----------|-------|
| `FileWriter(overwrite: true)` en `ProjectGenerator` | `flutter create` genera `main.dart` y `pubspec.yaml`; si no se sobreescribe, los templates de Clean Architecture se saltarían |
| `_menuPackages` como variable de instancia en `CreateProjectCommand` | El menú puede tener hasta 38 paquetes (23 generales + hasta 15 de plataforma); se necesita una lista combinada para mapear número → paquete correctamente |
| Marcadores `// cleanarch:*` en archivos de rutas | Permiten inyección quirúrgica sin sobreescribir el archivo completo; el usuario puede editar libremente el resto del archivo |
| `platformSectionsFor` solo muestra cuando hay 2+ categorías | Evitar saturar al usuario cuando solo eligió móvil (caso más común) |
| `_printHelp()` personalizado en lugar del help de `args` | El paquete `args` solo mostraría `create` como único comando; se necesita listar todos los subcomandos directamente |

---

## Archivos clave para modificar funcionalidades

| Si quieres... | Modifica... |
|---------------|-------------|
| Agregar un nuevo comando | `lib/src/commands/create_<nombre>_command.dart` + registrar en `create_command.dart` + agregar en `_printHelp()` de `runner.dart` |
| Agregar un paquete al catálogo | `lib/src/utils/flutter_packages.dart` → lista `all`, `mobile`, `desktop` o `web` |
| Cambiar los templates generados | `lib/src/templates/project_templates.dart` o `module_templates.dart` |
| Cambiar cómo se inyectan rutas | `lib/src/generators/route_injector.dart` |
| Cambiar el banner o versión | `lib/src/runner.dart` → constantes `_version`, `_printBanner()` |
| Agregar nueva plataforma | `flutter_packages.dart` + `_resolvePlatforms()` + `_selectPlatformsInteractively()` en `create_project_command.dart` |

---

## Comandos útiles para el desarrollador

```bash
# Instalar dependencias
dart pub get

# Compilar ejecutable
dart compile exe bin/main.dart -o bin/cleanarch.exe

# Probar sin compilar (más rápido durante desarrollo)
dart run bin/main.dart --help
dart run bin/main.dart create module prueba --path D:\Proyectos\mi_app

# Probar el ejecutable compilado
bin/cleanarch.exe --help
bin/cleanarch.exe create project test_app --platforms android,ios -i

# Activar globalmente para pruebas
dart pub global activate --source path .
cleanarch --help
```

---

*Generado el 2026-05-11 — Sesión de desarrollo CleanArch CLI v1.1.0*
