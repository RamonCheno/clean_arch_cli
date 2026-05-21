import 'package:clean_arch_cli/src/templates/module_templates.dart' show normalizeStorageLib, normalizeHttpLib;

// ── Nombres de clase y archivo por propósito ─────────────────────────────────

String serviceClassName(String purpose) {
  switch (purpose) {
    case 'settings': return 'SettingsService';
    case 'cache':    return 'CacheService';
    case 'secure':   return 'SecureService';
    default:         return 'DatabaseService';
  }
}

String serviceFileName(String purpose) {
  switch (purpose) {
    case 'settings': return 'settings_service.dart';
    case 'cache':    return 'cache_service.dart';
    case 'secure':   return 'secure_service.dart';
    default:         return 'database_service.dart';
  }
}

// ── Selector principal ────────────────────────────────────────────────────────

/// Genera el template del servicio según la librería y el propósito.
/// [purpose] puede ser: 'database' | 'settings' | 'cache' | 'secure'
String storageServiceTemplate(String lib, {String purpose = 'database', String packageName = 'your_app'}) {
  final norm = normalizeStorageLib(lib);
  switch (purpose) {
    case 'settings': return _settingsServiceTemplate(norm);
    case 'cache':    return _cacheServiceTemplate(norm);
    case 'secure':   return _secureServiceTemplate(norm);
    default:         return _databaseServiceTemplate(norm, packageName: packageName);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATABASE SERVICE — CRUD completo por colección
// ═══════════════════════════════════════════════════════════════════════════════

String _databaseServiceTemplate(String lib, {String packageName = 'your_app'}) {
  switch (lib) {
    case 'hive':           return _dbHive(packageName);
    case 'shared_prefs':   return _dbSharedPrefs(packageName);
    case 'secure_storage': return _dbSecureStorage(packageName);
    case 'sqflite':        return _dbSqflite(packageName);
    case 'isar':           return _dbIsar(packageName);
    case 'drift':          return _dbDrift(packageName);
    case 'get_storage':    return _dbGetStorage(packageName);
    case 'objectbox':      return _dbObjectBox(packageName);
    case 'floor':          return _dbFloor(packageName);
    default:               return _dbGeneric(lib, packageName);
  }
}

String _dbGetStorage(String packageName) => '''
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:$packageName/app/core/database/app_database.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (GetStorage)             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Todos los Providers acceden a datos vía Get.find<DatabaseService>().
// La inicialización de GetStorage la hace AppDatabase.init() en main().
class DatabaseService extends GetxService {
  // El contenedor por defecto, listo tras AppDatabase.init() en main().
  GetStorage get _box => AppDatabase.container();

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    return (_box.read<List>(collection) ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    final list = await getAll(collection);
    return list.where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> save(String collection, Map<String, dynamic> data) async {
    final list = await getAll(collection);
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) { list[idx] = data; } else { list.add(data); }
    _box.write(collection, list);
  }

  Future<void> delete(String collection, String id) async {
    final list = await getAll(collection);
    list.removeWhere((e) => e['id'] == id);
    _box.write(collection, list);
  }
}
''';

String _dbHive(String packageName) => '''
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:$packageName/app/core/database/app_database.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (Hive)                   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Hive.initFlutter() lo hace AppDatabase.init() en main().
// Las cajas se abren automáticamente al primer acceso (lazy open).
class DatabaseService extends GetxService {
  // Abre la caja si no estaba abierta; Hive la mantiene en memoria tras eso.
  Future<Box<Map>> _box(String collection) async {
    if (!Hive.isBoxOpen(collection)) {
      await Hive.openBox<Map>(collection);
    }
    return Hive.box<Map>(collection);
  }

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    return (await _box(collection))
        .values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    final raw = (await _box(collection))
        .values
        .where((e) => e['id'] == id)
        .firstOrNull;
    return raw != null ? Map<String, dynamic>.from(raw) : null;
  }

  Future<void> save(String collection, Map<String, dynamic> data) async {
    await (await _box(collection)).put(data['id'] as String, data);
  }

  Future<void> delete(String collection, String id) async {
    await (await _box(collection)).delete(id);
  }
}
''';

String _dbSharedPrefs(String packageName) => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:$packageName/app/core/database/app_database.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (SharedPreferences)      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// AppDatabase.init() carga la instancia de SharedPreferences en main().
// Cada colección se serializa como JSON bajo su propia clave.
class DatabaseService extends GetxService {
  // Acceso directo a la instancia cargada por AppDatabase.init() en main().
  SharedPreferences get _prefs => AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final raw = _prefs.getString(collection);
    if (raw == null) { return []; }
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    return (await getAll(collection)).where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> save(String collection, Map<String, dynamic> data) async {
    final list = await getAll(collection);
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) { list[idx] = data; } else { list.add(data); }
    _prefs.setString(collection, jsonEncode(list));
  }

  Future<void> delete(String collection, String id) async {
    final list = await getAll(collection);
    list.removeWhere((e) => e['id'] == id);
    _prefs.setString(collection, jsonEncode(list));
  }
}
''';

String _dbSecureStorage(String packageName) => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:$packageName/app/core/database/app_database.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (FlutterSecureStorage)   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Datos cifrados con Keychain (iOS) / Keystore (Android).
// No requiere init — AppDatabase.instance provee la instancia configurada.
class DatabaseService extends GetxService {
  FlutterSecureStorage get _storage => AppDatabase.instance;

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final raw = await _storage.read(key: collection);
    if (raw == null) { return []; }
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    return (await getAll(collection)).where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> save(String collection, Map<String, dynamic> data) async {
    final list = await getAll(collection);
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) { list[idx] = data; } else { list.add(data); }
    await _storage.write(key: collection, value: jsonEncode(list));
  }

  Future<void> delete(String collection, String id) async {
    final list = await getAll(collection);
    list.removeWhere((e) => e['id'] == id);
    await _storage.write(key: collection, value: jsonEncode(list));
  }
}
''';

String _dbSqflite(String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/database/app_database.dart';
// cleanarch:dao_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (sqflite)                │
// └─────────────────────────────────────────────────────────────────────────┘
//
// AppDatabase.database abre la base de datos la primera vez (lazy singleton).
// Los DAOs se agregan automáticamente con:
//   cleanarch create table <nombre>
//
// O manualmente:
//   import 'package:$packageName/app/core/database/daos/tarea_dao.dart';
//   final TareaDao tarea = TareaDao();
class DatabaseService extends GetxService {
  // cleanarch:dao_getter
}
''';

String _dbIsar(String packageName) => '''
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:$packageName/app/core/database/app_database.dart';
// cleanarch:collection_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (Isar)                   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Isar trabaja con colecciones tipadas (code-gen).
// Las colecciones se agregan automáticamente con:
//   cleanarch create table <nombre>
//
// O manualmente:
//   import 'package:$packageName/app/core/database/collections/tarea_collection.dart';
//   IsarCollection<Tarea> get tarea => AppDatabase.instance.collection<Tarea>();
class DatabaseService extends GetxService {
  // Accede a la instancia inicializada por AppDatabase.init() en main().
  Isar get _isar => AppDatabase.instance;

  // cleanarch:collection_getter
}
''';

String _dbDrift(String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/database/app_database.dart';
// cleanarch:dao_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (Drift)                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Drift genera código a partir de tus tablas (@DriftDatabase).
// Corre: dart run build_runner build --delete-conflicting-outputs
//
// Los DAOs se agregan automáticamente con:
//   cleanarch create table <nombre>
//
// O manualmente:
//   import 'package:$packageName/app/core/database/daos/tarea_dao.dart';
//   TareaDao get tarea => _db.tareaDao;
class DatabaseService extends GetxService {
  // La conexión Drift es lazy: se abre en la primera consulta.
  final AppDatabase _db = AppDatabase();

  // cleanarch:dao_getter
}
''';

/// Template genérico para librerías de almacenamiento no reconocidas.
/// Genera stubs con TODO para que el usuario los implemente.
String _dbGeneric(String lib, String packageName) => '''
import 'package:get/get.dart';
// TODO: importa tu librería de almacenamiento
// import 'package:$lib/$lib.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global ($lib)                   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// cleanarch no tiene un template específico para "$lib".
// Implementa los métodos CRUD usando el API de tu librería.
//
// Pasos:
//   1. Agrega la inicialización de $lib en AppDatabase (core/database/app_database.dart)
//   2. Implementa cada método aquí usando el API de $lib
//   3. Si tu librería es async al abrir, usa Get.putAsync en initial_binding.dart
class DatabaseService extends GetxService {
  // TODO: declara e inicializa tu instancia de $lib aquí.
  // Ejemplo: final _db = MiBaseDeDatos();

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    // TODO: retorna todos los registros de la colección usando $lib
    throw UnimplementedError('Implementa getAll para $lib');
  }

  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    // TODO: retorna el registro con ese id, o null si no existe
    throw UnimplementedError('Implementa getById para $lib');
  }

  Future<void> save(String collection, Map<String, dynamic> data) async {
    // TODO: inserta o actualiza el registro
    throw UnimplementedError('Implementa save para $lib');
  }

  Future<void> delete(String collection, String id) async {
    // TODO: elimina el registro con ese id
    throw UnimplementedError('Implementa delete para $lib');
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS SERVICE — clave-valor para configuración de usuario
// ═══════════════════════════════════════════════════════════════════════════════

String _settingsServiceTemplate(String lib) {
  switch (lib) {
    case 'hive':           return _settingsHive();
    case 'secure_storage': return _settingsSecureStorage();
    case 'shared_prefs':   return _settingsSharedPrefs();
    default:               return _settingsGetStorage();
  }
}

String _settingsGetStorage() => '''
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  SettingsService — Persistencia de configuración global (GetStorage)    │
// └─────────────────────────────────────────────────────────────────────────┘
class SettingsService extends GetxService {
  final _box = GetStorage('settings');

  T? get<T>(String key) => _box.read<T>(key);

  void set(String key, dynamic value) => _box.write(key, value);

  void remove(String key) => _box.remove(key);

  bool has(String key) => _box.hasData(key);
}
''';

String _settingsSharedPrefs() => '''
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  SettingsService — Persistencia de configuración global (SharedPrefs)   │
// └─────────────────────────────────────────────────────────────────────────┘
class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  @override
  Future<void> onInit() async {
    _prefs = await SharedPreferences.getInstance();
    super.onInit();
  }

  // API uniforme: get/set/remove/has
  Object? get(String key) => _prefs.get(key);

  Future<void> set(String key, dynamic value) async {
    if (value is String)      await _prefs.setString(key, value);
    else if (value is bool)   await _prefs.setBool(key, value);
    else if (value is int)    await _prefs.setInt(key, value);
    else if (value is double) await _prefs.setDouble(key, value);
    else                      await _prefs.setString(key, value.toString());
  }

  Future<void> remove(String key) => _prefs.remove(key);
  bool has(String key) => _prefs.containsKey(key);
}
''';

String _settingsHive() => '''
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  SettingsService — Persistencia de configuración global (Hive)          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Abre la caja en main():
//   await Hive.openBox('settings');
class SettingsService extends GetxService {
  Box get _box => Hive.box('settings');

  T? get<T>(String key) => _box.get(key) as T?;

  Future<void> set(String key, dynamic value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);

  bool has(String key) => _box.containsKey(key);
}
''';

String _settingsSecureStorage() => '''
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  SettingsService — Configuración segura global (FlutterSecureStorage)   │
// └─────────────────────────────────────────────────────────────────────────┘
class SettingsService extends GetxService {
  final _storage = const FlutterSecureStorage();

  // API uniforme: get/set/remove/has (valores como String por ser SecureStorage)
  Future<Object?> get(String key) => _storage.read(key: key);

  Future<void> set(String key, dynamic value) =>
      _storage.write(key: key, value: value.toString());

  Future<void> remove(String key) => _storage.delete(key: key);

  Future<bool> has(String key) => _storage.containsKey(key: key);
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// CACHE SERVICE — datos temporales
// ═══════════════════════════════════════════════════════════════════════════════

String _cacheServiceTemplate(String lib) {
  switch (lib) {
    case 'hive':         return _cacheHive();
    case 'shared_prefs': return _cacheSharedPrefs();
    default:             return _cacheGetStorage();
  }
}

String _cacheGetStorage() => '''
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CacheService — Caché temporal global (GetStorage)                      │
// └─────────────────────────────────────────────────────────────────────────┘
class CacheService extends GetxService {
  final _box = GetStorage('cache');

  T? read<T>(String key) => _box.read<T>(key);

  void write(String key, dynamic value) => _box.write(key, value);

  void remove(String key) => _box.remove(key);

  void clear() => _box.erase();

  bool has(String key) => _box.hasData(key);
}
''';

String _cacheHive() => '''
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CacheService — Caché temporal global (Hive)                            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Abre la caja en main():
//   await Hive.openBox('cache');
class CacheService extends GetxService {
  Box get _box => Hive.box('cache');

  T? read<T>(String key) => _box.get(key) as T?;

  Future<void> write(String key, dynamic value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);

  Future<int> clear() => _box.clear();
}
''';

String _cacheSharedPrefs() => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CacheService — Caché temporal global (SharedPreferences)               │
// └─────────────────────────────────────────────────────────────────────────┘
class CacheService extends GetxService {
  late SharedPreferences _prefs;

  @override
  Future<void> onInit() async {
    _prefs = await SharedPreferences.getInstance();
    super.onInit();
  }

  String? read(String key) => _prefs.getString(key);

  Future<void> write(String key, dynamic value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// SECURE SERVICE — datos sensibles / tokens
// ═══════════════════════════════════════════════════════════════════════════════

String _secureServiceTemplate(String lib) => '''
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  SecureService — Datos sensibles globales (FlutterSecureStorage)        │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Úsalo para: tokens JWT, contraseñas, datos personales sensibles.
class SecureService extends GetxService {
  final _storage = const FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> has(String key) => _storage.containsKey(key: key);
}
''';

// ── InitialBinding con servicios ─────────────────────────────────────────────

/// Genera las líneas de registro de servicios para el InitialBinding.
/// Retorna una lista de (import, registrationLine) por cada servicio.
List<({String import, String registration, String comment})>
    serviceBindingEntries(String storageLib, {String packageName = 'your_app'}) {
  final entries = <({String import, String registration, String comment})>[];

  if (storageLib.isEmpty) { return entries; }

  void addEntry(String purpose, String lib) {
    final className = serviceClassName(purpose);
    final fileName = serviceFileName(purpose);
    final norm = normalizeStorageLib(lib);
    // Libs que requieren Get.putAsync porque su onInit() es async:
    //   sqflite       → DatabaseService.onInit() abre la BD con openDatabase()
    //   shared_prefs  → SettingsService.onInit() llama SharedPreferences.getInstance()
    // El resto (drift, isar, get_storage, hive, secure_storage) son síncronos
    // o se inicializan en main() antes de que corra el binding.
    final needsAsync =
        norm == 'sqflite' || norm == 'shared_preferences';
    final registration = needsAsync
        ? '    Get.putAsync<$className>(() async => $className(), permanent: true);'
        : '    Get.put<$className>($className(), permanent: true);';

    entries.add((
      import: "import 'package:$packageName/app/core/services/$fileName';",
      registration: registration,
      comment: '    // $className — ${_purposeLabel(purpose)} via $lib',
    ));
  }

  if (storageLib.contains(',') && storageLib.contains(':')) {
    final parts = storageLib.split(',');
    for (final part in parts) {
      final chunks = part.split(':');
      if (chunks.length == 2) {
        addEntry(chunks[1].trim(), chunks[0].trim());
      }
    }
  } else {
    final lib = storageLib.split(':').first.trim();
    addEntry('database', lib);
  }

  return entries;
}

String _purposeLabel(String purpose) {
  switch (purpose) {
    case 'settings': return 'configuración persistente';
    case 'cache':    return 'caché temporal';
    case 'secure':   return 'datos sensibles';
    default:         return 'base de datos principal';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// API SERVICE — llamadas HTTP globales
// ═══════════════════════════════════════════════════════════════════════════════

/// Genera el template de ApiService según la librería HTTP elegida.
String apiServiceTemplate(String httpLib, {String packageName = 'your_app'}) {
  switch (normalizeHttpLib(httpLib)) {
    case 'dio':  return _apiServiceDio(packageName);
    case 'http': return _apiServiceHttp();
    default:     return _apiServiceGetConnect(packageName);
  }
}

/// Genera la entrada de ApiService para el InitialBinding.
({String import, String registration, String comment})
    apiServiceBindingEntry(String httpLib, {String packageName = 'your_app'}) {
  return (
    import: "import 'package:$packageName/app/core/services/api_service.dart';",
    registration: '    Get.put<ApiService>(ApiService(), permanent: true);',
    comment: '    // ApiService — llamadas HTTP via ${normalizeHttpLib(httpLib)}',
  );
}

String _apiServiceGetConnect(String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/network/api_client.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ApiService — Llamadas HTTP globales (GetConnect / ApiClient)           │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Servicio global de red. Todos los Providers REST lo usan
// vía Get.find<ApiService>() — ninguno conoce ApiClient directamente.
// Cambia la URL base en: core/network/api_client.dart
class ApiService extends GetxService {
  final ApiClient _client = Get.find();

  Future<List<Map<String, dynamic>>> getAll(String endpoint) async {
    final res = await _client.get(endpoint);
    return List<Map<String, dynamic>>.from(res.body as List);
  }

  Future<Map<String, dynamic>?> getById(String endpoint, String id) async {
    final res = await _client.get('\$endpoint/\$id');
    if (res.statusCode == 404) return null;
    return res.body as Map<String, dynamic>;
  }

  Future<void> post(String endpoint, Map<String, dynamic> data) =>
      _client.post(endpoint, body: data);

  Future<void> put(String endpoint, String id, Map<String, dynamic> data) =>
      _client.put('\$endpoint/\$id', body: data);

  Future<void> delete(String endpoint, String id) =>
      _client.delete('\$endpoint/\$id');
}
''';

String _apiServiceDio(String packageName) => '''
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:$packageName/app/core/network/api_client.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ApiService — Llamadas HTTP globales (Dio)                              │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Obtiene la instancia de Dio desde ApiClient (registrado en InitialBinding).
// Cambia la URL base e interceptores en: core/network/api_client.dart
class ApiService extends GetxService {
  late final Dio _dio;

  @override
  void onInit() {
    _dio = Get.find<ApiClient>().dio;
    super.onInit();
  }

  Future<List<Map<String, dynamic>>> getAll(String endpoint) async {
    final res = await _dio.get<List<dynamic>>(endpoint);
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<Map<String, dynamic>?> getById(String endpoint, String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('\$endpoint/\$id');
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) { return null; }
      rethrow;
    }
  }

  Future<void> post(String endpoint, Map<String, dynamic> data) =>
      _dio.post<void>(endpoint, data: data);

  Future<void> put(String endpoint, String id, Map<String, dynamic> data) =>
      _dio.put<void>('\$endpoint/\$id', data: data);

  Future<void> delete(String endpoint, String id) =>
      _dio.delete<void>('\$endpoint/\$id');
}
''';

String _apiServiceHttp() => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ApiService — Llamadas HTTP globales (package:http)                     │
// └─────────────────────────────────────────────────────────────────────────┘
//
// TODO: cambia _baseUrl a la URL base de tu API.
class ApiService extends GetxService {
  static const _baseUrl = 'https://api.tuapp.com';

  Future<List<Map<String, dynamic>>> getAll(String endpoint) async {
    final res = await http.get(Uri.parse('\$_baseUrl\$endpoint'));
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<Map<String, dynamic>?> getById(String endpoint, String id) async {
    final res = await http.get(Uri.parse('\$_baseUrl\$endpoint/\$id'));
    if (res.statusCode == 404) return null;
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> post(String endpoint, Map<String, dynamic> data) async {
    _check(await http.post(
      Uri.parse('\$_baseUrl\$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ));
  }

  Future<void> put(String endpoint, String id, Map<String, dynamic> data) async {
    _check(await http.put(
      Uri.parse('\$_baseUrl\$endpoint/\$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ));
  }

  Future<void> delete(String endpoint, String id) async {
    _check(await http.delete(Uri.parse('\$_baseUrl\$endpoint/\$id')));
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP \${res.statusCode}: \${res.body}');
    }
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// APP DATABASE — clase de configuración central de la base de datos
// ═══════════════════════════════════════════════════════════════════════════════

/// Genera `lib/app/core/database/app_database.dart` según el storage lib elegido.
String appDatabaseTemplate(String storageLib) {
  final norm = normalizeStorageLib(storageLib);
  switch (norm) {
    case 'drift':          return _appDatabaseDrift();
    case 'sqflite':        return _appDatabaseSqflite();
    case 'isar':           return _appDatabaseIsar();
    case 'hive':           return _appDatabaseHive();
    case 'shared_prefs':   return _appDatabaseSharedPrefs();
    case 'secure_storage': return _appDatabaseSecureStorage();
    case 'get_storage':    return _appDatabaseGetStorage();
    case 'objectbox':      return _appDatabaseObjectBox();
    case 'floor':          return _appDatabaseFloor();
    default:               return _appDatabaseGeneric(norm);
  }
}

/// Devuelve `true` si la lib es soportada nativamente por el CLI.
bool isKnownStorageLib(String storageLib) {
  final norm = normalizeStorageLib(storageLib.split(',').first.split(':').first.trim());
  const known = {'get_storage', 'hive', 'shared_prefs', 'secure_storage', 'sqflite', 'isar', 'drift', 'objectbox', 'floor'};
  return known.contains(norm);
}

String _appDatabaseDrift() => '''
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
// cleanarch:table_import
// cleanarch:dao_import

part 'app_database.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Base de datos principal (Drift + SQLite)                 │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Para agregar tablas usa el CLI:
//   cleanarch create table <nombre>
//
// O manualmente:
//   1. Crea la tabla en database/tables/<nombre>_table.dart
//   2. Crea el DAO en database/daos/<nombre>_dao.dart
//   3. Agrégalos a @DriftDatabase(tables: [...], daos: [...])
//   4. Regenera: dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(tables: [], daos: [])
class AppDatabase extends _\$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Migraciones — incrementa schemaVersion y agrega pasos aquí
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  // inDatabaseFolder resuelve la carpeta estándar de sqflite internamente.
  // Solo pasa el nombre del archivo, no una ruta absoluta.
  return LazyDatabase(() async {
    return SqfliteQueryExecutor.inDatabaseFolder(path: 'app.db');
  });
}
''';

String _appDatabaseSqflite() => '''
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Base de datos principal (sqflite)                        │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Uso:
//   final db = await AppDatabase.database;
//   await db.insert('mi_tabla', { 'id': '1', 'nombre': 'Ejemplo' });
//
// Registra en InitialBinding antes de usarlo:
//   final db = await AppDatabase.database;
//   Get.put(DatabaseService(db), permanent: true);
class AppDatabase {
  AppDatabase._();
  static Database? _instance;

  static Future<Database> get database async {
    if (_instance != null) { return _instance!; }
    _instance = await _init();
    return _instance!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'app.db'),
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Crea las tablas — agrega una sentencia CREATE TABLE por cada tabla.
  // Usa el CLI: cleanarch create table <nombre>
  static Future<void> _onCreate(Database db, int version) async {
    // cleanarch:table_create
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // cleanarch:table_upgrade
    // Ejemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE tarea ADD COLUMN descripcion TEXT');
    // }
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
''';

String _appDatabaseIsar() => '''
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
// cleanarch:collection_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Base de datos principal (Isar)                           │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Para agregar colecciones usa el CLI:
//   cleanarch create table <nombre>
//
// O manualmente:
//   1. Crea la colección en database/collections/<nombre>_collection.dart
//   2. Agrégala a la lista de schemas en init()
//   3. Regenera: dart run build_runner build --delete-conflicting-outputs
class AppDatabase {
  AppDatabase._();
  static Isar? _isar;

  static Isar get instance {
    assert(_isar != null && _isar!.isOpen, 'Llama AppDatabase.init() primero');
    return _isar!;
  }

  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) { return; }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        // cleanarch:schema
      ],
      directory: dir.path,
    );
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
''';

String _appDatabaseHive() => '''
import 'package:hive_flutter/hive_flutter.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Configuración central de Hive                            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Llama AppDatabase.init() en main() antes de runApp():
//   await AppDatabase.init();
//
// Luego abre las cajas que necesites por módulo o aquí centralmente.
class AppDatabase {
  AppDatabase._();

  static Future<void> init() async {
    await Hive.initFlutter();
    // Registra tus adapters generados:
    // Hive.registerAdapter(ProductoAdapter());

    // Abre las cajas de tus módulos:
    // await Hive.openBox<Map>('productos');
    // await Hive.openBox<Map>('usuarios');
  }

  /// Acceso a una caja genérica de Map.
  static Box<Map> box(String collection) => Hive.box<Map>(collection);

  /// Acceso tipado a una caja con TypeAdapter.
  static Box<T> typedBox<T>(String collection) => Hive.box<T>(collection);

  static Future<void> closeAll() => Hive.close();
}
''';

String _appDatabaseGetStorage() => '''
import 'package:get_storage/get_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Configuración central de GetStorage                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Llama AppDatabase.init() en main() antes de runApp():
//   await AppDatabase.init();
class AppDatabase {
  AppDatabase._();

  /// Inicializa GetStorage. Llama una sola vez antes de runApp().
  static Future<void> init() async {
    await GetStorage.init();
    // Inicializa contenedores adicionales si los necesitas:
    // await GetStorage.init('settings');
    // await GetStorage.init('cache');
  }

  /// Acceso al contenedor por nombre (por defecto: GetStorage.defaultContainer).
  static GetStorage container([String name = GetStorage.defaultContainer]) =>
      GetStorage(name);
}
''';

String _appDatabaseSharedPrefs() => '''
import 'package:shared_preferences/shared_preferences.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Configuración central de SharedPreferences               │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Inicializa en main() antes de runApp():
//   await AppDatabase.init();
class AppDatabase {
  AppDatabase._();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Instancia de SharedPreferences. Requiere llamar init() primero.
  static SharedPreferences get instance {
    assert(_prefs != null, 'AppDatabase.init() debe llamarse antes de usar instance');
    return _prefs!;
  }
}
''';

String _appDatabaseSecureStorage() => '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Configuración central de FlutterSecureStorage            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// No requiere inicialización especial.
// Úsalo para datos sensibles: tokens, credenciales, datos personales.
class AppDatabase {
  AppDatabase._();

  /// Instancia compartida con opciones de seguridad optimizadas por plataforma.
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// OBJECTBOX — AppDatabase y DatabaseService
// ══════════════════════════════════════════════════════════════════════════════

String _appDatabaseObjectBox() => '''
import 'package:objectbox/objectbox.dart';
import 'objectbox.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Base de datos principal (ObjectBox)                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Para agregar entidades usa el CLI:
//   cleanarch create table <nombre>
//
// O manualmente:
//   1. Crea la entidad en database/entities/<nombre>_entity.dart con @Entity()
//   2. Regenera: dart run build_runner build --delete-conflicting-outputs
//   ObjectBox descubre automáticamente todas las clases @Entity().
class AppDatabase {
  AppDatabase._();
  static Store? _instance;

  static Store get instance {
    assert(_instance != null, 'Llama AppDatabase.init() en main() primero');
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) { return; }
    _instance = await openStore();
  }

  static void close() {
    _instance?.close();
    _instance = null;
  }
}
''';

String _dbObjectBox(String packageName) => '''
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:\$packageName/app/core/database/app_database.dart';
// cleanarch:entity_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (ObjectBox)              │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ObjectBox descubre todas las entidades @Entity() automáticamente.
// Las entidades se agregan con:
//   cleanarch create table <nombre>
//
// O manualmente:
//   import 'package:\$packageName/app/core/database/entities/tarea_entity.dart';
//   Box<Tarea> get tarea => AppDatabase.instance.box<Tarea>();
class DatabaseService extends GetxService {
  // cleanarch:collection_getter
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// FLOOR — AppDatabase y DatabaseService
// ══════════════════════════════════════════════════════════════════════════════

String _appDatabaseFloor() => '''
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
// cleanarch:entity_import
// cleanarch:dao_import

part 'app_database.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Base de datos principal (Floor)                          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Para agregar entidades y DAOs usa el CLI:
//   cleanarch create table <nombre>
//
// O manualmente:
//   1. Crea la entidad en database/entities/<nombre>_entity.dart
//   2. Crea el DAO en database/daos/<nombre>_dao.dart
//   3. Agrégalos a @Database(entities: [...]) y declara el getter del DAO
//   4. Regenera: dart run build_runner build --delete-conflicting-outputs
@Database(version: 1, entities: [
  // cleanarch:entity
])
abstract class AppFloorDatabase extends FloorDatabase {
  // cleanarch:floor_dao_getter
}

class AppDatabase {
  AppDatabase._();
  static AppFloorDatabase? _instance;

  static AppFloorDatabase get instance {
    assert(_instance != null, 'Llama AppDatabase.init() en main() primero');
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) { return; }
    _instance = await \$FloorAppFloorDatabase
        .databaseBuilder('app.db')
        .build();
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
''';

String _dbFloor(String packageName) => '''
import 'package:get/get.dart';
import 'package:\$packageName/app/core/database/app_database.dart';
// cleanarch:dao_import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DatabaseService — Almacenamiento local global (Floor)                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Floor genera código a partir de tus entidades y DAOs (@Database).
// Corre: dart run build_runner build --delete-conflicting-outputs
//
// Los DAOs se agregan automáticamente con:
//   cleanarch create table <nombre>
//
// O manualmente:
//   import 'package:\$packageName/app/core/database/daos/tarea_dao.dart';
//   TareaDao get tarea => AppDatabase.instance.tareaDao;
class DatabaseService extends GetxService {
  // cleanarch:dao_getter
}
''';

/// Template genérico para librerías de almacenamiento no reconocidas.
String _appDatabaseGeneric(String lib) => '''
// TODO: importa tu librería de almacenamiento
// import 'package:$lib/$lib.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppDatabase — Configuración central de base de datos ($lib)            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// cleanarch no tiene un template específico para "$lib".
// Implementa esta clase como punto de entrada a tu base de datos.
//
// Pasos sugeridos:
//   1. Agrega el import de tu librería arriba
//   2. Implementa init() con la lógica de apertura de tu BD
//   3. Expón el acceso a la instancia con getters o métodos estáticos
//   4. Llama AppDatabase.init() en main() si es necesario
class AppDatabase {
  AppDatabase._();

  static Future<void> init() async {
    // TODO: inicializa tu librería de almacenamiento aquí
    // Ejemplo: await MiLibreria.open(...);
  }

  // TODO: expón el acceso a tu instancia de BD
  // static MiTipoDB get instance => _instance!;
}
''';
