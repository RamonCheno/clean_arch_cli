# Sesión de desarrollo — clean_arch_cli

## Servicios globales (mayor cambio)

Se reemplazó la arquitectura donde cada provider conocía directamente su librería, por un sistema de **servicios globales** en `core/services/`:

| Archivo generado | Propósito |
|---|---|
| `api_service.dart` | Envuelve Dio / GetConnect / http |
| `database_service.dart` | Envuelve Hive / GetStorage / SQLite / etc. |
| `settings_service.dart` | Si se elige segunda lib de persistencia |
| `cache_service.dart` | Si se elige lib de caché |
| `secure_service.dart` | Si se elige lib de datos sensibles |

Los providers ahora son thin wrappers que solo usan `Get.find<DatabaseService>()` — para cambiar de librería basta con modificar el servicio, no cada módulo.

### Estructura generada

```
core/services/
├── api_service.dart        ← HTTP global (Dio / GetConnect / http)
├── database_service.dart   ← Storage global (Hive / GetStorage / etc.)
└── settings_service.dart   ← si se eligió segunda lib de persistencia
```

`InitialBinding` registra los servicios automáticamente:
```dart
Get.put<ApiService>(ApiService(), permanent: true);
Get.put<DatabaseService>(DatabaseService(), permanent: true);
```

Todos los providers son thin wrappers:
```dart
// REST provider
class ProductoProvider {
  final ApiService _api = Get.find();
  Future<List<Map>> fetchAll() => _api.getAll('/productos');
}

// Local provider
class ProductoProvider {
  final DatabaseService _db = Get.find();
  Future<List<Map>> fetchAll() => _db.getAll('productos');
}
```

---

## Selección dual de librerías de storage

- El menú de storage acepta 1 o 2 opciones separadas por coma (`1,3`)
- Si se eligen 2, pregunta el propósito de cada una (database / cache / settings / secure)
- Retorna formato `"lib1:purpose1,lib2:purpose2"` que fluye por todo el pipeline

---

## Menú de paquetes

- **"Otro"** ahora aparece como el **último número** de la lista, no como paso separado
- Agregar paquetes nuevos a `flutter_packages.dart` empuja "Otro" automáticamente
- `sqflite`, `isar` y `drift` agregados a `FlutterPackages.all` con versiones correctas

---

## Correcciones de bugs

| Bug | Fix |
|---|---|
| `build_runner` duplicado en pubspec | Se filtran claves ya presentes en la plantilla |
| `shared_preferences` / `drift` no se agregaban con datasource dual | Se parsea el formato `lib:purpose` antes del switch |
| Error al ejecutar `flutter pub add` sin mostrar causa | Se imprime stderr/stdout del proceso |
| `_storageLibMenu()` duplicado en dos commands | Extraído a `storage_lib_menu.dart` compartido |
| Templates de provider con `_prefs`/`_prefs2` inconsistentes | Eliminado `_providerDualTemplate` y helpers obsoletos |
| API no uniforme entre `SettingsService` implementations | Todos exponen `get/set/remove/has` |

---

## Archivos modificados / creados

| Archivo | Acción |
|---|---|
| `lib/src/templates/module_templates.dart` | Providers usan servicios globales |
| `lib/src/templates/service_templates.dart` | **NUEVO** — templates de ApiService, DatabaseService, SettingsService, CacheService, SecureService |
| `lib/src/templates/project_templates.dart` | `initialBindingTemplate()` registra servicios dinámicamente |
| `lib/src/generators/project_generator.dart` | Genera archivos de servicio en `core/services/` |
| `lib/src/generators/module_generator.dart` | Genera servicio si no existe al crear módulo |
| `lib/src/commands/create_module_command.dart` | Usa `storageLibMenu()` compartido |
| `lib/src/commands/create_project_command.dart` | Usa `storageLibMenu()` compartido; "Otro" en menú de paquetes |
| `lib/src/commands/storage_lib_menu.dart` | **NUEVO** — menú compartido de selección de storage (1 o 2 libs) |
| `lib/src/utils/flutter_packages.dart` | Agregados sqflite, isar, drift con versiones |
