// Templates para cada capa de un módulo en Clean Architecture + GetX

// ═══════════════════════════════════════════════════════════════════════════════
// DOMAIN → ENTITY
// ═══════════════════════════════════════════════════════════════════════════════
String entityTemplate(String name, String pascal) => '''
// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Domain  →  Entity (Entidad)                                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué es una Entidad?
//   Piénsala como el "molde" de tu objeto de negocio.
//   Si tu app maneja productos, esta clase describe QUÉ ES un producto:
//   tiene id, nombre, precio, etc.
//
// Regla de oro:
//   Esta clase NO sabe nada de internet, bases de datos ni pantallas.
//   Solo describe el objeto. Nada más.
//
//   ✅ Sí puedes poner:   propiedades, constructores, equals/hashCode
//   ❌ No pongas:         llamadas a API, widgets de Flutter, lógica de GetX
//
// ¿Por qué importa?
//   Si mañana cambias de REST a GraphQL, o de MySQL a Firebase,
//   esta clase NO cambia. El negocio sigue siendo el mismo.
//
// TODO: Agrega aquí las propiedades de tu $pascal.
//   Ejemplo:
//     final String nombre;
//     final double precio;
//     final int stock;
class ${pascal}Entity {
  final String id;

  const ${pascal}Entity({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ${pascal}Entity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA → MODEL
// ═══════════════════════════════════════════════════════════════════════════════
String modelTemplate(
  String name,
  String pascal,
  String packageName, {
  String storageLib = '',
  bool useJsonAnnotation = false,
  bool tableExists = true,
}) {
  final normLib = normalizeStorageLib(storageLib.split(':').first.trim());
  final isDrift = normLib == 'drift';
  final isOtherOrm = isStorageLibInjected(normLib) && normLib != 'drift' && normLib != 'sqflite';

  // El import de app_database.dart solo se agrega cuando la tabla existe,
  // ya que HomeData es generada por build_runner a partir de la tabla.
  final driftImport = isDrift && tableExists
      ? "\nimport 'package:$packageName/app/core/database/app_database.dart';"
      : '';

  // ── Factory fromDrift (solo Drift) ────────────────────────────────────────
  // Si la tabla no existe aún (módulo sin tabla propia, ej. dashboard),
  // se genera como comentario para que el código compile sin errores.
  final driftFactory = isDrift ? (tableExists ? '''

  // ── Drift ──────────────────────────────────────────────────────────────────
  //
  // Convierte una fila Drift (${pascal}Data) → ${pascal}Model directo, sin Map.
  // ${pascal}Data es generada por build_runner a partir de ${pascal}Table.
  //
  // Requiere: dart run build_runner build --delete-conflicting-outputs
  //
  // TODO: mapea los campos de tu tabla:
  //   factory ${pascal}Model.fromDrift(${pascal}Data row) {
  //     return ${pascal}Model(
  //       id:     row.id.toString(),
  //       nombre: row.nombre,
  //       activo: row.activo,
  //     );
  //   }
  factory ${pascal}Model.fromDrift(${pascal}Data row) {
    return ${pascal}Model(
      id: row.id.toString(),
      // TODO: agrega los campos de tu tabla:
      // nombre: row.nombre,
    );
  }''' : '''

  // ── Drift (sin tabla propia) ───────────────────────────────────────────────
  //
  // Este módulo no tiene tabla propia — obtiene datos de otras tablas.
  // Si en el futuro necesitas leer filas de Drift, crea la tabla con:
  //   cleanarch create table $name
  // y descomenta el factory:
  //
  // import 'package:$packageName/app/core/database/app_database.dart';
  //
  // factory ${pascal}Model.fromDrift(${pascal}Data row) {
  //   return ${pascal}Model(
  //     id: row.id.toString(),
  //     // TODO: mapea los campos de tu tabla
  //   );
  // }''') : '';

  // ── Factory fromOrm (Isar / ObjectBox / Floor) ────────────────────────────
  final ormFactory = isOtherOrm ? (tableExists ? '''

  // ── ORM ────────────────────────────────────────────────────────────────────
  //
  // Convierte un objeto del ORM → ${pascal}Model directo, sin Map.
  //
  // TODO: reemplaza `dynamic` con el tipo generado por tu ORM.
  // Ejemplo Isar / ObjectBox / Floor:
  //   factory ${pascal}Model.fromOrm(${pascal}OrmObject obj) {
  //     return ${pascal}Model(id: obj.id.toString(), nombre: obj.nombre);
  //   }
  factory ${pascal}Model.fromOrm(dynamic obj) {
    return ${pascal}Model(
      id: obj.id.toString(),
      // TODO: mapea los campos del objeto ORM:
      // nombre: obj.nombre,
    );
  }''' : '''

  // ── ORM (sin tabla propia) ─────────────────────────────────────────────────
  //
  // Este módulo no tiene tabla propia — obtiene datos de otras tablas.
  // Si necesitas tu propia colección, crea la tabla con:
  //   cleanarch create table $name
  // y descomenta el factory:
  //
  // factory ${pascal}Model.fromOrm(${pascal}OrmObject obj) {
  //   return ${pascal}Model(id: obj.id.toString());
  // }''') : '';

  // ── Versión con json_annotation (@JsonSerializable) ─────────────────────
  if (useJsonAnnotation) {
    return '''
import 'package:json_annotation/json_annotation.dart';
import 'package:$packageName/app/domain/entities/${name}_entity.dart';$driftImport

part '${name}_model.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Model (Modelo) — @JsonSerializable                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// fromJson / toJson son generados automáticamente por build_runner.
//
// Después de agregar campos, regenera con:
//   dart run build_runner build --delete-conflicting-outputs
//
// TODO: agrega aquí los campos de tu ${pascal}.
//   Ejemplo:
//     final String nombre;
//     final double precio;
//     const ${pascal}Model({required super.id, required this.nombre, required this.precio});
@JsonSerializable()
class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({required super.id});

  // Generado automáticamente por build_runner — no editar
  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>
      _\$${pascal}ModelFromJson(json);

  // Generado automáticamente por build_runner — no editar
  Map<String, dynamic> toJson() => _\$${pascal}ModelToJson(this);

  // Convierte una Entidad → Modelo (útil al guardar datos)
  factory ${pascal}Model.fromEntity(${pascal}Entity entity) {
    return ${pascal}Model(id: entity.id);
  }$driftFactory$ormFactory
}
''';
  }

  // ── Versión manual (sin json_annotation) ────────────────────────────────
  return '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';$driftImport

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Model (Modelo)                                          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué es un Modelo?
//   Es la versión "traductora" de tu Entidad.
//   Sabe hablar el idioma de la API (JSON) y convertirlo
//   a un objeto que tu app puede usar.
//
// Analogía sencilla:
//   La Entidad es el "concepto" de un producto.
//   El Modelo es el "formulario de importación" que traduce
//   lo que llega del servidor a ese concepto.
//
// ¿Por qué extiende ${pascal}Entity y no es una clase aparte?
//   Porque el Modelo ES un ${pascal}Entity, solo que con superpoderes
//   de serialización. Así evitas duplicar propiedades.
//
// TODO: Agrega aquí los campos de tu ${pascal}.
//   Ejemplo de fromJson:
//     return ${pascal}Model(
//       id:     json['id']     as String,
//       nombre: json['nombre'] as String,
//       precio: json['precio'] as double,
//     );
class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({required super.id});

  // Convierte el JSON que llega de la API → objeto $pascal
  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(id: json['id'] as String);
  }

  // Convierte el objeto $pascal → JSON para enviar a la API
  Map<String, dynamic> toJson() => {
    'id': id,
    // TODO: agrega todos los campos que necesita tu API
  };

  // Convierte una Entidad → Modelo (útil al guardar datos)
  factory ${pascal}Model.fromEntity(${pascal}Entity entity) {
    return ${pascal}Model(id: entity.id);
  }$driftFactory$ormFactory
}
''';
}

// ═══════════════════════════════════════════════════════════════════════════════
// DOMAIN → REPOSITORY INTERFACE
// ═══════════════════════════════════════════════════════════════════════════════
String repositoryInterfaceTemplate(
    String name, String pascal, String plural, String pluralPascal,
    String packageName) => '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Domain  →  Repository (Contrato / Interfaz)                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué es esto?
//   Es una LISTA DE PROMESAS. Le dice al resto de la app:
//   "Existen estas operaciones para $pascal: obtener todos, buscar por id,
//    guardar y eliminar."
//   Pero NO dice cómo se hacen. Eso es trabajo de RepositoryImpl (capa Data).
//
// Analogía sencilla:
//   Imagina un control remoto de TV. Tiene botones: encender, subir volumen,
//   cambiar canal. No sabes si adentro usa Bluetooth o infrarrojo.
//   Este archivo es el "control remoto": define los botones disponibles.
//   RepositoryImpl es el "mecanismo interno".
//
// ¿Por qué separarlo así?
//   Porque si mañana cambias de una API REST a Firebase,
//   solo cambias RepositoryImpl. El resto de la app no se entera.
//
// TODO: Agrega más métodos si tu negocio los necesita.
//   Ejemplo:
//     Future<List<${pascal}Entity>> buscarPorNombre(String nombre);
//     Future<void> actualizar(${pascal}Entity entity);
abstract class ${pascal}Repository {
  // Trae todos los registros de $pascal
  Future<List<${pascal}Entity>> getAll();

  // Busca un $pascal por su id. Si no existe, devuelve null
  Future<${pascal}Entity?> getById(String id);

  // Guarda un $pascal (crea nuevo o actualiza si ya existe)
  Future<void> save(${pascal}Entity entity);

  // Elimina el $pascal con ese id
  Future<void> delete(String id);
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA → REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// datasource: 'rest' | 'local' | 'both'
/// storageLib: cualquier nombre de paquete
String repositoryImplTemplate(
  String name,
  String pascal,
  String plural,
  String pluralPascal, {
  String datasource = 'rest',
  String storageLib = 'get_storage',
  required String packageName,
}) {
  final normStorage = normalizeStorageLib(storageLib);
  final sync = datasource == 'local' && isStorageLibSync(normStorage);
  if (sync) { return _repositoryImplSyncTemplate(name, pascal, plural, pluralPascal, packageName); }
  if (datasource == 'both') { return _repositoryImplBothTemplate(name, pascal, plural, pluralPascal, packageName); }
  return _repositoryImplAsyncTemplate(name, pascal, plural, pluralPascal, packageName, storageLib: storageLib);
}

String _repositoryImplAsyncTemplate(
  String name,
  String pascal,
  String plural,
  String pluralPascal,
  String packageName, {
  String storageLib = '',
}) {
  final normLib = normalizeStorageLib(storageLib.split(':').first.trim());
  final isOrm = isStorageLibInjected(normLib);

  // ── Flujo ORM: provider retorna HomeModel directamente ──────────────────
  if (isOrm) {
    return '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';
import 'package:$packageName/app/data/providers/${name}_provider.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  RepositoryImpl  (datasource local ORM)                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Flujo de datos (sin conversión Map):
//   Base de datos
//       ↓  (${pascal}Data / objeto ORM)
//   ${pascal}Provider          ← llama al DAO de DatabaseService
//       ↓  (${pascal}Model)    ← fromDrift / fromOrm convierte directo
//   Tu Controller / UseCase    ← trabaja con ${pascal}Model (que ES ${pascal}Entity)
//
// ${pascal}Model extiende ${pascal}Entity, así que el repositorio devuelve
// los modelos tal cual — sin conversión adicional.
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}Provider _provider;

  ${pascal}RepositoryImpl(this._provider);

  @override
  Future<List<${pascal}Entity>> getAll() async {
    // ${pascal}Model extiende ${pascal}Entity → no se necesita conversión
    return _provider.fetchAll();
  }

  @override
  Future<${pascal}Entity?> getById(String id) async {
    return _provider.fetchById(id);
  }

  @override
  Future<void> save(${pascal}Entity entity) async {
    // HomeModel extends HomeEntity — en runtime siempre es ${pascal}Model.
    await _provider.save(entity as ${pascal}Model);
  }

  @override
  Future<void> delete(String id) => _provider.delete(id);
}
''';
  }

  // ── Flujo REST / key-value: provider retorna Map<String, dynamic> ────────
  return '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';
import 'package:$packageName/app/data/providers/${name}_provider.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  RepositoryImpl (Implementación del Repositorio)         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace este archivo?
//   Cumple las "promesas" que declaró ${pascal}Repository.
//   Aquí sí se explica el CÓMO: llama al Provider para obtener datos
//   del servidor y los convierte en Entidades que usa la app.
//
// Flujo de datos (de afuera hacia adentro):
//   API / Base de datos
//       ↓  (JSON crudo)
//   ${pascal}Provider        ← hace la llamada HTTP / storage
//       ↓  (Map<String, dynamic>)
//   ${pascal}Model.fromJson  ← convierte JSON → objeto tipado
//       ↓  (${pascal}Entity)
//   Tu Controller / UseCase  ← trabaja con objetos limpios
//
// Analogía sencilla:
//   El Provider es el mesero que trae la orden de la cocina (API).
//   Este RepositoryImpl es el cocinero que toma los ingredientes crudos
//   (JSON) y los convierte en el platillo terminado (Entidad).
//
// TODO: Si necesitas combinar API + cache local, hazlo aquí.
//   Ejemplo offline-first:
//     final cached = await _localProvider.get(id);
//     if (cached != null) return cached;
//     return await _remoteProvider.fetchById(id);
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}Provider _provider;

  ${pascal}RepositoryImpl(this._provider);

  @override
  Future<List<${pascal}Entity>> getAll() async {
    // 1. Pide los datos crudos al Provider
    final data = await _provider.fetchAll();
    // 2. Convierte cada Map<String,dynamic> en una Entidad lista para usar
    return data.map((json) => ${pascal}Model.fromJson(json)).toList();
  }

  @override
  Future<${pascal}Entity?> getById(String id) async {
    final json = await _provider.fetchById(id);
    if (json == null) { return null; }
    return ${pascal}Model.fromJson(json);
  }

  @override
  Future<void> save(${pascal}Entity entity) async {
    // HomeModel extends HomeEntity — en runtime siempre es ${pascal}Model.
    await _provider.save((entity as ${pascal}Model).toJson());
  }

  @override
  Future<void> delete(String id) => _provider.delete(id);
}
''';
}

String _repositoryImplSyncTemplate(
    String name, String pascal, String plural, String pluralPascal,
    String packageName) => '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';
import 'package:$packageName/app/data/providers/${name}_provider.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  RepositoryImpl  (datasource local síncrono)             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// El Provider de este módulo es síncrono (GetStorage / Hive), por lo que
// no se usa await al llamarlo. Los métodos del Repository siguen siendo
// async para respetar el contrato de la interfaz.
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}Provider _provider;

  ${pascal}RepositoryImpl(this._provider);

  @override
  Future<List<${pascal}Entity>> getAll() async {
    final data = _provider.fetchAll();
    return data.map((json) => ${pascal}Model.fromJson(json)).toList();
  }

  @override
  Future<${pascal}Entity?> getById(String id) async {
    final json = _provider.fetchById(id);
    if (json == null) { return null; }
    return ${pascal}Model.fromJson(json);
  }

  @override
  Future<void> save(${pascal}Entity entity) async {
    // HomeModel extends HomeEntity — en runtime siempre es ${pascal}Model.
    _provider.save((entity as ${pascal}Model).toJson());
  }

  @override
  Future<void> delete(String id) async {
    _provider.delete(id);
  }
}
''';

String _repositoryImplBothTemplate(
    String name, String pascal, String plural, String pluralPascal,
    String packageName) => '''
import 'package:get_storage/get_storage.dart';
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';
import 'package:$packageName/app/data/providers/${name}_provider.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  RepositoryImpl  (offline-first: REST + caché local)     │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Estrategia offline-first:
//   1. Intenta obtener datos del servidor (Provider REST).
//   2. Si tiene éxito, actualiza el caché local (GetStorage).
//   3. Si falla la red, devuelve los datos en caché.
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}Provider _provider;
  final _cache = GetStorage();
  static const _cacheKey = '${plural}_cache';

  ${pascal}RepositoryImpl(this._provider);

  @override
  Future<List<${pascal}Entity>> getAll() async {
    try {
      final data = await _provider.fetchAll();
      _cache.write(_cacheKey, data);
      return data.map((json) => ${pascal}Model.fromJson(json)).toList();
    } catch (_) {
      final cached = _cache.read<List>(_cacheKey) ?? [];
      return cached
          .cast<Map<String, dynamic>>()
          .map((json) => ${pascal}Model.fromJson(json))
          .toList();
    }
  }

  @override
  Future<${pascal}Entity?> getById(String id) async {
    try {
      final json = await _provider.fetchById(id);
      if (json == null) { return null; }
      return ${pascal}Model.fromJson(json);
    } catch (_) {
      final cached = _cache.read<List>(_cacheKey) ?? [];
      final match = cached
          .cast<Map<String, dynamic>>()
          .where((e) => e['id'] == id)
          .firstOrNull;
      return match != null ? ${pascal}Model.fromJson(match) : null;
    }
  }

  @override
  Future<void> save(${pascal}Entity entity) async {
    // HomeModel extends HomeEntity — en runtime siempre es ${pascal}Model.
    await _provider.save((entity as ${pascal}Model).toJson());
    // Invalida el caché para que el próximo getAll() refresque
    _cache.remove(_cacheKey);
  }

  @override
  Future<void> delete(String id) async {
    await _provider.delete(id);
    _cache.remove(_cacheKey);
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA → PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Normaliza aliases comunes al nombre canónico del paquete.
String normalizeStorageLib(String lib) {
  switch (lib.toLowerCase().trim()) {
    case 'hive_flutter':
    case 'hive':           return 'hive';
    case 'shared_preferences':
    case 'shared_prefs':   return 'shared_prefs';
    case 'flutter_secure_storage':
    case 'secure_storage': return 'secure_storage';
    case 'get_storage':    return 'get_storage';
    case 'sqflite':        return 'sqflite';
    case 'isar':           return 'isar';
    case 'drift':          return 'drift';
    case 'objectbox':      return 'objectbox';
    case 'floor':          return 'floor';
    default:               return lib.toLowerCase().trim();
  }
}

String normalizeHttpLib(String lib) {
  switch (lib.toLowerCase().trim()) {
    case 'getconnect':
    case 'get_connect': return 'get_connect';
    case 'dio':         return 'dio';
    case 'http':        return 'http';
    default:            return lib.toLowerCase().trim();
  }
}

/// Devuelve true si la storageLib es síncrona (no usa await en sus métodos).
/// Solo GetStorage es verdaderamente síncrono; Hive usa await al escribir.
bool isStorageLibSync(String storageLib) =>
    storageLib == 'get_storage';

/// Devuelve true si la storageLib requiere inyección de DB por constructor.
bool isStorageLibInjected(String storageLib) =>
    storageLib == 'sqflite' || storageLib == 'isar' || storageLib == 'drift' ||
    storageLib == 'objectbox' || storageLib == 'floor';

/// Selector de template de Provider según datasource y librería elegida.
/// storageLib puede ser "lib" (simple) o "lib1:purpose1,lib2:purpose2" (dual).
String providerTemplate(
  String name,
  String pascal,
  String plural, {
  String datasource = 'rest',
  String httpLib = 'get_connect',
  String storageLib = 'get_storage',
  required String packageName,
}) {
  final normHttp = normalizeHttpLib(httpLib);

  if (datasource == 'local' || datasource == 'both') {
    if (datasource == 'local') {
      // Dual: "lib1:purpose1,lib2:purpose2" → provider usa dos servicios globales
      if (storageLib.contains(',') && storageLib.contains(':')) {
        final parts = storageLib.split(',');
        if (parts.length == 2) {
          final p1 = parts[0].split(':');
          final p2 = parts[1].split(':');
          if (p1.length == 2 && p2.length == 2) {
            return _providerViaServicesTemplate(
              name, pascal, plural,
              lib1: p1[0].trim(), purpose1: p1[1].trim(),
              lib2: p2[0].trim(), purpose2: p2[1].trim(),
              packageName: packageName,
            );
          }
        }
      }
      // Simple: provider usa DatabaseService global
      return _providerViaDatabaseServiceTemplate(name, pascal, plural, packageName, storageLib);
    }
  }

  // 'rest' o 'both': provider remoto
  switch (normHttp) {
    case 'dio':  return _providerDioTemplate(name, pascal, plural, packageName);
    case 'http': return _providerHttpTemplate(name, pascal, plural, packageName);
    default:     return _providerGetConnectTemplate(name, pascal, plural, packageName);
  }
}

// ── LOCAL: Provider vía DatabaseService global ───────────────────────────────
String _providerViaDatabaseServiceTemplate(
    String name, String pascal, String plural, String packageName,
    [String storageLib = '']) {
  final normLib = normalizeStorageLib(storageLib.split(':').first.trim());

  // ORMs tipados (Drift, Isar, ObjectBox, Floor, Sqflite): exponen DAOs tipados
  if (isStorageLibInjected(normLib)) {
    // Accessor del DAO en DatabaseService (camelCase del nombre del módulo)
    final camel = pascal[0].toLowerCase() + pascal.substring(1);

    // ── Drift: implementación real con fromDrift ────────────────────────────
    if (normLib == 'drift') {
      return '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/database_service.dart';
import 'package:$packageName/app/core/database/app_database.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (local via DatabaseService — Drift)           │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Retorna ${pascal}Model directamente sin pasar por Map<String, dynamic>.
// ${pascal}Model.fromDrift() convierte la fila Drift (${pascal}Data) al modelo.
//
// ⚠ Requiere que la tabla exista antes de compilar:
//   cleanarch create table $name
//   dart run build_runner build --delete-conflicting-outputs
class ${pascal}Provider {
  final _databaseSvc = Get.find<DatabaseService>();

  // ── Lecturas ────────────────────────────────────────────────────────────

  Future<List<${pascal}Model>> fetchAll() async {
    final rows = await _databaseSvc.$camel.getAll();
    return rows.map(${pascal}Model.fromDrift).toList();
  }

  Future<${pascal}Model?> fetchById(String id) async {
    final row = await _databaseSvc.$camel.getById(int.tryParse(id) ?? 0);
    return row == null ? null : ${pascal}Model.fromDrift(row);
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  Future<void> save(${pascal}Model model) async {
    // TODO: construye el Companion con los campos de tu tabla y llama al DAO.
    //
    // Ejemplo:
    //   final entry = ${pascal}Companion(
    //     nombre:   Value(model.nombre),
    //     activo:   Value(model.activo),
    //   );
    //   if (model.id.isNotEmpty) {
    //     await _databaseSvc.$camel.updateRow(
    //       entry.copyWith(id: Value(int.parse(model.id))),
    //     );
    //   } else {
    //     await _databaseSvc.$camel.insert(entry);
    //   }
    throw UnimplementedError('Implementa save() con ${pascal}Companion');
  }

  // ── Eliminación ─────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _databaseSvc.$camel.deleteById(int.tryParse(id) ?? 0);
  }
}
''';
    }

    // ── Otros ORMs (Isar, ObjectBox, Floor, Sqflite): stubs tipados ──────────
    final camelForOrm = pascal[0].toLowerCase() + pascal.substring(1);
    return '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/database_service.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (local via DatabaseService — $normLib)
// └─────────────────────────────────────────────────────────────────────────┘
//
// DatabaseService con $normLib expone DAOs tipados.
//
// Paso 1 — Asegúrate de tener la tabla/colección creada.
// Paso 2 — Implementa fromOrm() en ${pascal}Model con el tipo correcto.
// Paso 3 — Reemplaza los TODOs con las llamadas al DAO.
class ${pascal}Provider {
  final _databaseSvc = Get.find<DatabaseService>();

  // ── Lecturas ────────────────────────────────────────────────────────────

  Future<List<${pascal}Model>> fetchAll() async {
    // TODO: usa _databaseSvc.$camelForOrm.getAll() y mapea con fromOrm()
    // final objs = await _databaseSvc.$camelForOrm.getAll();
    // return objs.map(${pascal}Model.fromOrm).toList();
    return [];
  }

  Future<${pascal}Model?> fetchById(String id) async {
    // TODO: usa _databaseSvc.$camelForOrm.getById(...)
    return null;
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  Future<void> save(${pascal}Model model) async {
    // TODO: implementa con el DAO correspondiente
  }

  // ── Eliminación ─────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    // TODO: usa _databaseSvc.$camelForOrm.deleteById(...)
  }
}
''';
  }

  // Key-value: delega al servicio global correspondiente
  switch (normLib) {
    case 'get_storage':
      return _providerGetStorageTemplate(name, pascal, plural, packageName);
    case 'hive':
      return _providerHiveTemplate(name, pascal, plural, packageName);
    case 'shared_prefs':
      return _providerSharedPrefsTemplate(name, pascal, plural, packageName);
    case 'secure_storage':
      return _providerSecureStorageTemplate(name, pascal, plural, packageName);
    default:
      return _providerGenericLocalTemplate(name, pascal, plural, packageName);
  }
}

// ── LOCAL: Provider vía dos servicios globales (dual) ────────────────────────
String _providerViaServicesTemplate(
  String name,
  String pascal,
  String plural, {
  String lib1 = '',
  required String purpose1,
  String lib2 = '',
  required String purpose2,
  required String packageName,
}) {
  final class1 = _serviceClassNameFromPurpose(purpose1);
  final class2 = _serviceClassNameFromPurpose(purpose2);
  final file1 = _serviceFileNameFromPurpose(purpose1);
  final file2 = _serviceFileNameFromPurpose(purpose2);
  final methods1 = _serviceProviderMethods(class1, purpose1, plural, name: name, lib: lib1);
  final methods2 = _serviceProviderMethods(class2, purpose2, plural, name: name, lib: lib2);

  return '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/$file1';
import 'package:$packageName/app/core/services/$file2';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (dual: $class1 + $class2)  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Combina dos servicios globales, cada uno con su propósito:
//   • $class1 → $purpose1
//   • $class2 → $purpose2
class ${pascal}Provider {
  final $class1 _${purpose1}Svc = Get.find();
  final $class2 _${purpose2}Svc = Get.find();

$methods1
$methods2}
''';
}

String _serviceClassNameFromPurpose(String purpose) {
  switch (purpose) {
    case 'settings': return 'SettingsService';
    case 'cache':    return 'CacheService';
    case 'secure':   return 'SecureService';
    default:         return 'DatabaseService';
  }
}

String _serviceFileNameFromPurpose(String purpose) {
  switch (purpose) {
    case 'settings': return 'settings_service.dart';
    case 'cache':    return 'cache_service.dart';
    case 'secure':   return 'secure_service.dart';
    default:         return 'database_service.dart';
  }
}

String _serviceProviderMethods(String className, String purpose, String plural,
    {String name = '', String lib = ''}) {
  final svc = '_${purpose}Svc';
  final normLib = normalizeStorageLib(lib);
  switch (purpose) {
    case 'database':
      if (isStorageLibInjected(normLib)) {
        // ORM tipado: expone DAOs, no API genérica
        return '''
  // ── CRUD ($className) ─────────────────────────────────────────────────
  //
  // $normLib expone DAOs tipados, no una API key-value.
  //
  // Paso 1 — Crea la tabla con el CLI:
  //   cleanarch create table $name
  //
  // Paso 2 — Reemplaza los TODOs con el DAO generado, ej:
  //   Future<List<${name.isEmpty ? 'Data' : name.substring(0, 1).toUpperCase() + name.substring(1)}Data>> fetchAll() => $svc.$name.getAll();
  //   Future<void> save(${name.isEmpty ? '' : name.substring(0, 1).toUpperCase() + name.substring(1)}Companion entry) async => $svc.$name.insert(entry);
  //   Future<bool> deleteById(int id) => $svc.$name.deleteById(id);
  //
  // Consulta docs/DATABASE.md para más ejemplos.
  Future<List<Map<String, dynamic>>> fetchAll() async => [];
  Future<Map<String, dynamic>?> fetchById(String id) async => null;
  Future<void> save(Map<String, dynamic> data) async {
    // TODO: $svc.$name.insert(/* Companion */);
  }
  Future<void> delete(String id) async {
    // TODO: $svc.$name.deleteById(int.parse(id));
  }
''';
      }
      // Key-value: API genérica disponible
      return '''
  // ── CRUD ($className) ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAll() => $svc.getAll('$plural');
  Future<Map<String, dynamic>?> fetchById(String id) => $svc.getById('$plural', id);
  Future<void> save(Map<String, dynamic> data) => $svc.save('$plural', data);
  Future<void> delete(String id) => $svc.delete('$plural', id);
''';
    case 'settings':
      return '''
  // ── Settings ($className) ─────────────────────────────────────────────
  Object? getSetting(String key) => $svc.get(key);
  Future<void> saveSetting(String key, dynamic value) => $svc.set(key, value);
  Future<void> removeSetting(String key) => $svc.remove(key);
  bool hasSetting(String key) => $svc.has(key);
''';
    case 'cache':
      return '''
  // ── Cache ($className) ───────────────────────────────────────────────
  Future<void> writeCache(String key, dynamic value) async => $svc.write(key, value);
  Future<dynamic> readCache(String key) async => $svc.read(key);
  Future<void> clearCache() async => $svc.clear();
''';
    case 'secure':
      return '''
  // ── Secure ($className) ──────────────────────────────────────────────
  Future<String?> readSecure(String key) => $svc.read(key);
  Future<void> writeSecure(String key, String value) => $svc.write(key, value);
  Future<void> deleteSecure(String key) => $svc.delete(key);
''';
    default:
      return '''
  // TODO: implementa métodos para $purpose usando $className
''';
  }
}

// ── REST: vía ApiService global ───────────────────────────────────────────────
String _providerGetConnectTemplate(String name, String pascal, String plural, String packageName) =>
    _providerViaApiServiceTemplate(name, pascal, plural, packageName);

String _providerDioTemplate(String name, String pascal, String plural, String packageName) =>
    _providerViaApiServiceTemplate(name, pascal, plural, packageName);

String _providerViaApiServiceTemplate(
    String name, String pascal, String plural, String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/api_service.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (REST via ApiService global)                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Este provider NO conoce la librería HTTP directamente.
// Delega todas las llamadas al ApiService registrado en InitialBinding.
// Para cambiar de GetConnect a Dio o http, solo modifica api_service.dart.
//
// TODO: ajusta el endpoint '/$plural' al path real de tu API.
class ${pascal}Provider {
  final ApiService _api = Get.find();
  static const _endpoint = '/$plural';

  Future<List<Map<String, dynamic>>> fetchAll() => _api.getAll(_endpoint);

  Future<Map<String, dynamic>?> fetchById(String id) =>
      _api.getById(_endpoint, id);

  Future<void> save(Map<String, dynamic> data) => _api.post(_endpoint, data);

  Future<void> update(String id, Map<String, dynamic> data) =>
      _api.put(_endpoint, id, data);

  Future<void> delete(String id) => _api.delete(_endpoint, id);
}
''';

// ── LOCAL: GetStorage ────────────────────────────────────────────────────────
String _providerGetStorageTemplate(String name, String pascal, String plural, String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/settings_service.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via SettingsService → GetStorage)      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Usa el SettingsService global en lugar de instanciar GetStorage directamente.
// Esto permite que el almacenamiento sea reutilizable en toda la aplicación.
// GetStorage es síncrono — todos los métodos son síncronos.
class ${pascal}Provider {
  final _settingsSvc = Get.find<SettingsService>();
  static const _key = '$plural';

  List<Map<String, dynamic>> fetchAll() {
    final raw = _settingsSvc.get<List>(_key) ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic>? fetchById(String id) =>
      fetchAll().where((e) => e['id'] == id).firstOrNull;

  void save(Map<String, dynamic> data) {
    final list = fetchAll();
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    _settingsSvc.set(_key, list);
  }

  void delete(String id) {
    final list = fetchAll()..removeWhere((e) => e['id'] == id);
    _settingsSvc.set(_key, list);
  }
}
''';

// ── LOCAL: Hive ──────────────────────────────────────────────────────────────
String _providerHiveTemplate(String name, String pascal, String plural, String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/settings_service.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via SettingsService → Hive)            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Usa el SettingsService global en lugar de acceder a Hive directamente.
// Esto permite que el almacenamiento sea reutilizable en toda la aplicación.
class ${pascal}Provider {
  final _settingsSvc = Get.find<SettingsService>();
  static const _key = '$plural';

  List<Map<String, dynamic>> fetchAll() {
    final raw = _settingsSvc.get<List>(_key) ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic>? fetchById(String id) =>
      fetchAll().where((e) => e['id'] == id).firstOrNull;

  Future<void> save(Map<String, dynamic> data) async {
    final list = fetchAll();
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    await _settingsSvc.set(_key, list);
  }

  Future<void> delete(String id) async {
    final list = fetchAll()..removeWhere((e) => e['id'] == id);
    await _settingsSvc.set(_key, list);
  }
}
''';

// ── LOCAL: SharedPreferences ─────────────────────────────────────────────────
String _providerSharedPrefsTemplate(String name, String pascal, String plural, String packageName) => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/settings_service.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via SettingsService → SharedPrefs)     │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Usa el SettingsService global en lugar de instanciar SharedPreferences.
// Esto permite que el almacenamiento sea reutilizable en toda la aplicación.
// Los datos se serializan a JSON para almacenar listas.
class ${pascal}Provider {
  final _settingsSvc = Get.find<SettingsService>();
  static const _key = '$plural';

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final raw = _settingsSvc.get<String>(_key);
    if (raw == null) { return []; }
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    final list = await fetchAll();
    return list.where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> save(Map<String, dynamic> data) async {
    final list = await fetchAll();
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    await _settingsSvc.set(_key, jsonEncode(list));
  }

  Future<void> delete(String id) async {
    final list = (await fetchAll())..removeWhere((e) => e['id'] == id);
    await _settingsSvc.set(_key, jsonEncode(list));
  }
}
''';

// ── LOCAL: FlutterSecureStorage ──────────────────────────────────────────────
String _providerSecureStorageTemplate(String name, String pascal, String plural, String packageName) => '''
import 'dart:convert';
import 'package:get/get.dart';
import 'package:$packageName/app/core/services/secure_service.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via SecureService → FlutterSecureStorage) │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Usa el SecureService global en lugar de instanciar FlutterSecureStorage.
// Esto permite que el almacenamiento seguro sea reutilizable en toda la app.
// FlutterSecureStorage cifra con Keychain (iOS) / Keystore (Android).
class ${pascal}Provider {
  final _secureSvc = Get.find<SecureService>();
  static const _key = '$plural';

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final raw = await _secureSvc.get(_key) as String?;
    if (raw == null) { return []; }
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    final list = await fetchAll();
    return list.where((e) => e['id'] == id).firstOrNull;
  }

  Future<void> save(Map<String, dynamic> data) async {
    final list = await fetchAll();
    final idx = list.indexWhere((e) => e['id'] == data['id']);
    if (idx >= 0) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    await _secureSvc.set(_key, jsonEncode(list));
  }

  Future<void> delete(String id) async {
    final list = (await fetchAll())..removeWhere((e) => e['id'] == id);
    await _secureSvc.set(_key, jsonEncode(list));
  }
}
''';

// ── REST: http (dart:http) ───────────────────────────────────────────────────
String _providerHttpTemplate(String name, String pascal, String plural, String packageName) => '''
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (REST via package:http)                       │
// └─────────────────────────────────────────────────────────────────────────┘
//
// TODO: Cambia _baseUrl a la URL base de tu API.
class ${pascal}Provider {
  static const _baseUrl = 'https://api.tuapp.com';

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final res = await http.get(Uri.parse('\$_baseUrl/$plural'));
    _checkStatus(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    final res = await http.get(Uri.parse('\$_baseUrl/$plural/\$id'));
    if (res.statusCode == 404) return null;
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> save(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('\$_baseUrl/$plural'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _checkStatus(res);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('\$_baseUrl/$plural/\$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _checkStatus(res);
  }

  Future<void> delete(String id) async {
    final res = await http.delete(Uri.parse('\$_baseUrl/$plural/\$id'));
    _checkStatus(res);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP \${res.statusCode}: \${res.body}');
    }
  }
}
''';

// ── LOCAL: sqflite (legacy — mantenido para referencia, no se llama directamente) ──
// ignore: unused_element
String _providerSqfliteTemplate(String name, String pascal, String plural) => '''
import 'package:sqflite/sqflite.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via sqflite)                           │
// └─────────────────────────────────────────────────────────────────────────┘
//
// sqflite usa SQL. La instancia de Database se abre una sola vez
// y se inyecta desde el Binding (registrada en InitialBinding).
//
// Inicialización en InitialBinding:
//   Get.putAsync<Database>(() async {
//     final path = join(await getDatabasesPath(), '$name.db');
//     return openDatabase(path, version: 1, onCreate: (db, v) async {
//       await db.execute(
//         'CREATE TABLE $plural (id TEXT PRIMARY KEY, /* tus campos */)',
//       );
//     });
//   });
class ${pascal}Provider {
  final Database _db;

  ${pascal}Provider(this._db);

  Future<List<Map<String, dynamic>>> fetchAll() =>
      _db.query('$plural');

  Future<Map<String, dynamic>?> fetchById(String id) async {
    final rows = await _db.query(
      '$plural',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> save(Map<String, dynamic> data) =>
      _db.insert('$plural', data,
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> update(String id, Map<String, dynamic> data) =>
      _db.update('$plural', data,
          where: 'id = ?', whereArgs: [id]);

  Future<void> delete(String id) =>
      _db.delete('$plural', where: 'id = ?', whereArgs: [id]);
}
''';

// ── LOCAL: Isar (legacy — mantenido para referencia, no se llama directamente) ──
// ignore: unused_element
String _providerIsarTemplate(String name, String pascal, String plural, String packageName) => '''
import 'package:isar/isar.dart';
import 'package:get/get.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via Isar)                              │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Isar trabaja con colecciones tipadas. Anota ${pascal}Model con @collection
// y genera el schema con: dart run build_runner build
//
// Inicialización en InitialBinding:
//   Get.putAsync<Isar>(() => Isar.open([${pascal}ModelSchema]));
//
// ${pascal}Model debe tener anotaciones de Isar:
//   @collection
//   class ${pascal}Model extends ${pascal}Entity { ... }
class ${pascal}Provider {
  final Isar _isar;

  ${pascal}Provider(this._isar);

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final items = await _isar.${pascal.toLowerCase()}Models.where().findAll();
    return items.map((e) => e.toJson()).toList();
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    // TODO: ajusta el filtro al campo id de tu modelo Isar
    final item = await _isar.${pascal.toLowerCase()}Models
        .filter()
        .idEqualTo(id)
        .findFirst();
    return item?.toJson();
  }

  Future<void> save(Map<String, dynamic> data) async {
    final model = ${pascal}Model.fromJson(data);
    await _isar.writeTxn(() => _isar.${pascal.toLowerCase()}Models.put(model));
  }

  Future<void> delete(String id) async {
    // TODO: ajusta al id interno de Isar (int) si es distinto al id de negocio
    await _isar.writeTxn(() async {
      final item = await _isar.${pascal.toLowerCase()}Models
          .filter()
          .idEqualTo(id)
          .findFirst();
      if (item != null) await _isar.${pascal.toLowerCase()}Models.delete(item.isarId!);
    });
  }
}
''';

// ── LOCAL: Drift (legacy — mantenido para referencia, no se llama directamente) ──
// ignore: unused_element
String _providerDriftTemplate(String name, String pascal, String plural, String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/data/models/${name}_model.dart';
// TODO: importa tu AppDatabase generada por Drift
// import '../../core/database/app_database.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via Drift)                             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Drift genera código a partir de tus definiciones de tabla.
// Corre: dart run build_runner build
//
// Inicialización en InitialBinding:
//   Get.lazyPut<AppDatabase>(() => AppDatabase());
//
// TODO: Reemplaza AppDatabase y ${pascal}Table con los nombres reales de tu schema.
class ${pascal}Provider {
  // TODO: reemplaza AppDatabase con tu clase de base de datos Drift
  final dynamic _db;

  ${pascal}Provider(this._db);

  Future<List<Map<String, dynamic>>> fetchAll() async {
    // TODO: usa el DAO o la query generada por Drift
    // final rows = await _db.select(_db.${plural}).get();
    // return rows.map((r) => r.toJson()).toList();
    throw UnimplementedError('Implementa fetchAll con tu schema Drift');
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    // TODO: final row = await (_db.select(_db.${plural})..where((t) => t.id.equals(id))).getSingleOrNull();
    throw UnimplementedError('Implementa fetchById con tu schema Drift');
  }

  Future<void> save(Map<String, dynamic> data) async {
    // TODO: await _db.into(_db.${plural}).insertOnConflictUpdate(${pascal}Companion(...));
    throw UnimplementedError('Implementa save con tu schema Drift');
  }

  Future<void> delete(String id) async {
    // TODO: await (_db.delete(_db.${plural})..where((t) => t.id.equals(id))).go();
    throw UnimplementedError('Implementa delete con tu schema Drift');
  }
}
''';

// ── LOCAL: Genérico con paquete especificado ─────────────────────────────────
String _providerGenericLocalTemplate(
    String name, String pascal, String plural, String packageName) => '''
// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Data  →  Provider  (Local via $packageName)                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Template CRUD genérico para '$packageName'.
// Implementa cada método usando el API de tu librería.
//
// TODO: Agrega el import de $packageName
// import 'package:$packageName/$packageName.dart';
class ${pascal}Provider {
  // TODO: declara e inicializa tu instancia de $packageName aquí,
  //   o recíbela por constructor si la registras en el Binding.

  Future<List<Map<String, dynamic>>> fetchAll() async {
    // TODO: retorna todos los registros de $plural usando $packageName
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    // TODO: retorna el registro con ese id, o null si no existe
    throw UnimplementedError();
  }

  Future<void> save(Map<String, dynamic> data) async {
    // TODO: inserta o actualiza el registro
    throw UnimplementedError();
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    // TODO: actualiza solo el registro con ese id
    throw UnimplementedError();
  }

  Future<void> delete(String id) async {
    // TODO: elimina el registro con ese id
    throw UnimplementedError();
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// DOMAIN → USE CASE (getAll)
// ═══════════════════════════════════════════════════════════════════════════════
String useCaseGetAllTemplate(
    String name, String pascal, String plural, String pluralPascal,
    String packageName) => '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Domain  →  UseCase (Caso de Uso)                                 │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué es un Caso de Uso?
//   Es una ACCIÓN específica que puede hacer tu app.
//   Este caso de uso hace exactamente UNA cosa:
//   "Obtener todos los $plural".
//
// ¿Por qué no llamar al Repository directo desde el Controller?
//   Podrías hacerlo, pero si pones la lógica aquí:
//   ✅ Puedes agregar reglas de negocio sin tocar la UI ni los datos.
//   ✅ Puedes testear esta acción sola, sin levantar pantallas ni servidores.
//   ✅ Si dos pantallas necesitan la misma acción, comparten este archivo.
//
// Analogía sencilla:
//   Un Caso de Uso es como un botón de una máquina dispensadora:
//   presionas "dar $pascal" y no sabes si viene de la API, del cache
//   o de la base de datos. Solo recibes el resultado.
//
// ¿Cómo se llama desde el Controller?
//   final items = await _getAll$pluralPascal();   // llama a call() automáticamente
//
// TODO: Si necesitas filtros o paginación, agrégalos al método call().
//   Ejemplo: Future<List<${pascal}Entity>> call({int pagina = 1})
class GetAll${pluralPascal}UseCase {
  // Depende del contrato (interfaz), no de la implementación concreta
  final ${pascal}Repository _repository;

  GetAll${pluralPascal}UseCase(this._repository);

  Future<List<${pascal}Entity>> call() => _repository.getAll();
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// DOMAIN → USE CASE (getById)
// ═══════════════════════════════════════════════════════════════════════════════
String useCaseGetByIdTemplate(String name, String pascal, String packageName) => '''
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Domain  →  UseCase (Caso de Uso)                                 │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace este Caso de Uso?
//   Una sola cosa: buscar un $pascal por su id.
//   Lo usa la pantalla de detalle cuando el usuario toca un elemento
//   de la lista y quiere ver toda su información.
//
// ¿Devuelve null?
//   Sí. Si el $pascal no existe en el servidor, devuelve null.
//   El Controller decide qué mostrar en ese caso (mensaje de error, etc.)
//
// ¿Cómo se llama desde el Controller?
//   final item = await _get${pascal}ById(elIdQueQuieres);
class Get${pascal}ByIdUseCase {
  final ${pascal}Repository _repository;

  Get${pascal}ByIdUseCase(this._repository);

  // Devuelve el $pascal con ese id, o null si no existe
  Future<${pascal}Entity?> call(String id) => _repository.getById(id);
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// PRESENTATION → CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════════
String controllerTemplate(
    String name, String pascal, String plural, String pluralPascal,
    String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/domain/entities/${name}_entity.dart';
import 'package:$packageName/app/domain/usecases/get_all_${plural}_usecase.dart';
import 'package:$packageName/app/domain/usecases/get_${name}_by_id_usecase.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Presentation  →  Controller                                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace el Controller?
//   Es el "cerebro" de la pantalla. Guarda el estado (¿está cargando?
//   ¿hubo error? ¿qué datos hay?) y le dice a la Vista qué mostrar.
//
// ¿Qué NO debe hacer el Controller?
//   ❌ Contener lógica de negocio (eso va en los UseCases)
//   ❌ Importar widgets de Flutter (eso va en la View)
//   ❌ Llamar directamente al Provider o al Repository
//
// Variables con .obs (observables):
//   Son variables "mágicas" de GetX. Cuando cambia su valor,
//   todos los widgets que las escuchan se actualizan solos en pantalla.
//   No necesitas llamar setState() ni nada parecido.
//
// Ciclo de vida (orden en que GetX llama a cada método):
//   1. Constructor  → recibe las dependencias del Binding
//   2. onInit()     → se ejecuta al crear el controller (carga inicial)
//   3. onReady()    → se ejecuta cuando la pantalla ya se ve en la app
//   4. onClose()    → se ejecuta al salir de la pantalla (limpieza)
//
// ¿Cómo accedo al controller desde la Vista?
//   Si la Vista extiende GetView<${pascal}Controller>,
//   solo escribe `controller.items` o `controller.fetchAll()`.
class ${pascal}Controller extends GetxController {
  // ── Dependencias (vienen del Binding, no las instancies aquí) ──────────
  final GetAll${pluralPascal}UseCase _getAll$pluralPascal;
  final Get${pascal}ByIdUseCase _get${pascal}ById;

  ${pascal}Controller(
    this._getAll$pluralPascal,
    this._get${pascal}ById,
  );

  // ── Estado observable ───────────────────────────────────────────────────
  // Lista de registros que se muestra en pantalla.
  // Al escribir .obs GetX la convierte en reactiva: la Vista se actualiza sola.
  final RxList<${pascal}Entity> items = <${pascal}Entity>[].obs;

  // El registro seleccionado (para pantalla de detalle)
  final Rx<${pascal}Entity?> selected = Rx<${pascal}Entity?>(null);

  // true = mostrar indicador de carga, false = mostrar los datos
  final RxBool isLoading = false.obs;

  // Si hay un error, guarda el mensaje aquí para mostrarlo en pantalla
  final RxString errorMessage = ''.obs;

  // ── Ciclo de vida ───────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchAll(); // Carga los datos en cuanto se abre la pantalla
  }

  // ── Acciones que puede llamar la Vista ──────────────────────────────────

  // Carga (o recarga) todos los $plural
  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      items.value = await _getAll$pluralPascal();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Carga un $pascal específico por su id (para pantalla de detalle)
  Future<void> fetchById(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      selected.value = await _get${pascal}ById(id);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// PRESENTATION → BINDING
// ═══════════════════════════════════════════════════════════════════════════════
String bindingTemplate(
  String name,
  String pascal,
  String plural,
  String pluralPascal, {
  String storageLib = 'get_storage',
  required String packageName,
}) {
  // El provider siempre se instancia sin argumentos:
  // los servicios globales (DatabaseService, SettingsService…) ya están
  // registrados en InitialBinding y el provider los obtiene con Get.find().
  final providerLine =
      '    // 1. Fuente de datos — los servicios de storage están en InitialBinding\n'
      '    Get.lazyPut<${pascal}Provider>(() => ${pascal}Provider());';
  return '''
import 'package:get/get.dart';
import 'package:$packageName/app/data/providers/${name}_provider.dart';
import 'package:$packageName/app/data/repositories/${name}_repository_impl.dart';
import 'package:$packageName/app/domain/repositories/${name}_repository.dart';
import 'package:$packageName/app/domain/usecases/get_all_${plural}_usecase.dart';
import 'package:$packageName/app/domain/usecases/get_${name}_by_id_usecase.dart';
import 'package:$packageName/app/modules/${name}/controllers/${name}_controller.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Presentation  →  Binding (Inyección de dependencias)             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace el Binding?
//   Es el "armador" del módulo. Antes de que se abra la pantalla,
//   GetX ejecuta este archivo para construir y conectar todas las piezas:
//   Provider → RepositoryImpl → UseCases → Controller.
//
// ¿Qué es lazyPut?
//   lazyPut registra la clase pero NO la crea todavía.
//   La crea solo cuando alguien la pida por primera vez (Get.find<X>()).
//
// Orden importante (de abajo hacia arriba en dependencias):
//   Primero registra lo que otros necesitan, luego los que dependen de ellos.
class ${pascal}Binding extends Bindings {
  @override
  void dependencies() {
$providerLine

    // 2. Repositorio (necesita al Provider para funcionar)
    Get.lazyPut<${pascal}Repository>(
      () => ${pascal}RepositoryImpl(Get.find()),
    );

    // 3. Casos de uso (necesitan al Repositorio para funcionar)
    Get.lazyPut(() => GetAll${pluralPascal}UseCase(Get.find()));
    Get.lazyPut(() => Get${pascal}ByIdUseCase(Get.find()));

    // 4. Controller (necesita los Casos de Uso para funcionar)
    Get.lazyPut<${pascal}Controller>(
      () => ${pascal}Controller(Get.find(), Get.find()),
    );
  }
}
''';
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTAINER → VIEW SHELL (sin controller, sin binding)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Módulo contenedor: agrupa sub-screens bajo un mismo namespace de rutas.
// No tiene datos propios ni lógica propia — solo existe como raíz de children.
//
// Ejemplo:
//   modules/tasks/ → contenedor
//     screens/list_task/   ← sub-screen real
//     screens/add_task/    ← sub-screen real
//     screens/update_task/ ← sub-screen real
//
// Si necesitas un layout compartido (AppBar, BottomNav), conviértelo en un
// Scaffold con Navigator anidado en lugar del SizedBox.shrink() actual.
String containerViewTemplate(String name, String pascal) => '''
import 'package:flutter/material.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  Módulo contenedor: $pascal                                             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Esta vista es un marcador de posición para el módulo contenedor "$name".
// No se navega directamente a ella — sirve como raíz del grupo de rutas:
//
//   GetPage(
//     name: Routes.$name,
//     page: () => const ${pascal}View(),
//     children: [
//       GetPage(name: Routes.addTask, ...),
//       GetPage(name: Routes.listTask, ...),
//     ],
//   )
//
// TODO (opcional): reemplaza SizedBox por un Scaffold con Navigator anidado
//   si quieres un layout compartido entre sub-pantallas.
class ${pascal}View extends StatelessWidget {
  const ${pascal}View({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// PRESENTATION ONLY → CONTROLLER (sin UseCases)
// ═══════════════════════════════════════════════════════════════════════════════
String controllerPresentationOnlyTemplate(
    String name, String pascal, String packageName) => '''
import 'package:get/get.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Presentation  →  Controller  (sin capa de datos propia)          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Este módulo no tiene provider ni repositorio propio.
// Si necesita datos, inyecta los UseCases de otros módulos aquí.
//
// Ejemplo — consumir datos del módulo "task":
//   final GetAllTasksUseCase _getAllTasks;
//   ${pascal}Controller(this._getAllTasks);
//
// TODO: agrega los UseCases que necesites desde otros módulos.
class ${pascal}Controller extends GetxController {
  // ── Estado observable ───────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Ciclo de vida ───────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // TODO: carga los datos que necesites al iniciar
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// PRESENTATION ONLY → BINDING (sin Provider / Repository)
// ═══════════════════════════════════════════════════════════════════════════════
String bindingPresentationOnlyTemplate(
    String name, String pascal, String packageName) => '''
import 'package:get/get.dart';
import 'package:$packageName/app/modules/$name/controllers/${name}_controller.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Presentation  →  Binding  (sin capa de datos propia)             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Si ${pascal}Controller necesita UseCases de otros módulos, agrégalos aquí:
//
//   Get.lazyPut(() => GetAllTasksUseCase(Get.find()));
//   Get.lazyPut<${pascal}Controller>(
//     () => ${pascal}Controller(Get.find()),
//   );
class ${pascal}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<${pascal}Controller>(() => ${pascal}Controller());
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// PRESENTATION → VIEW
// ═══════════════════════════════════════════════════════════════════════════════
String viewTemplate(String name, String pascal, String packageName) => '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$packageName/app/modules/${name}/controllers/${name}_controller.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  CAPA: Presentation  →  View (Vista / Pantalla)                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace la View?
//   Es la pantalla que ve el usuario.
//   Su único trabajo es mostrar lo que el Controller le dice
//   y avisar al Controller cuando el usuario hace algo (toca un botón, etc.)
//
// Reglas simples:
//   ✅ Muestra datos del controller con `controller.items`
//   ✅ Llama métodos del controller cuando el usuario interactúa
//   ❌ NO tiene lógica de negocio (cálculos, reglas, llamadas a API)
//   ❌ NO llama a repositorios ni providers directamente
//
// ¿Qué es GetView<${pascal}Controller>?
//   Es un widget especial de GetX que ya tiene el controller listo
//   en una propiedad llamada `controller`. Equivale a poner
//   Get.find<${pascal}Controller>() pero más cómodo.
//
// ¿Qué es Obx()?
//   Es un widget "escucha". Todo lo que está dentro de Obx()
//   se vuelve a dibujar automáticamente cuando cambia
//   cualquier variable .obs del controller que se lea adentro.
//   Solo se redibuja ese pedazo, no toda la pantalla.
//
// TODO: Reemplaza el ListView.builder de ejemplo con tu diseño real.
class ${pascal}View extends GetView<${pascal}Controller> {
  const ${pascal}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: Obx(() {
        // Estado 1: Cargando → muestra un spinner
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Estado 2: Error → muestra el mensaje y un botón de reintento
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.fetchAll,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Estado 3: Lista vacía
        if (controller.items.isEmpty) {
          return const Center(child: Text('Sin registros'));
        }

        // Estado 4: Lista con datos → muéstralos
        return ListView.builder(
          itemCount: controller.items.length,
          itemBuilder: (_, i) {
            final item = controller.items[i];
            // TODO: personaliza este ListTile con los campos de tu Entidad
            return ListTile(
              title: Text(item.id),
              onTap: () => controller.fetchById(item.id),
            );
          },
        );
      }),
    );
  }
}
''';

// ═══════════════════════════════════════════════════════════════════════════════
// STORAGE PACKAGE REQUIREMENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Paquetes runtime requeridos para una storageLib dada.
/// Soporta formato simple ("drift") y dual ("hive:database,get_storage:settings").
Map<String, String> storageRuntimePackages(String storageLib) {
  final result = <String, String>{};
  for (final lib in _parseStorageLibNames(storageLib)) {
    result.addAll(_runtimePackagesForLib(normalizeStorageLib(lib)));
  }
  return result;
}

/// Paquetes dev requeridos para una storageLib dada (code-gen: drift, isar).
Map<String, String> storageDevPackages(String storageLib) {
  final result = <String, String>{};
  for (final lib in _parseStorageLibNames(storageLib)) {
    result.addAll(_devPackagesForLib(normalizeStorageLib(lib)));
  }
  return result;
}

List<String> _parseStorageLibNames(String storageLib) {
  if (storageLib.contains(',') && storageLib.contains(':')) {
    return storageLib.split(',').map((p) => p.split(':').first.trim()).toList();
  }
  return [storageLib.split(':').first.trim()];
}

Map<String, String> _runtimePackagesForLib(String lib) {
  switch (lib) {
    case 'get_storage':    return {'get_storage': '^2.1.1'};
    case 'hive':           return {'hive_flutter': '^1.1.0'};
    case 'shared_prefs':   return {'shared_preferences': '^2.3.2'};
    case 'secure_storage': return {'flutter_secure_storage': '^9.2.2'};
    case 'sqflite':        return {'sqflite': '^2.4.1'};
    case 'isar':           return {'isar': '^3.1.0+1', 'isar_flutter_libs': '^3.1.0+1'};
    case 'drift':          return {'drift': '^2.22.1', 'path_provider': '^2.1.4'};
    case 'objectbox': return {'objectbox': '^4.0.0', 'objectbox_flutter_libs': '^4.0.0'};
    case 'floor':     return {'floor': '^1.5.0'};
    default:               return {lib: 'any'};
  }
}

Map<String, String> _devPackagesForLib(String lib) {
  switch (lib) {
    case 'isar':  return {'isar_generator': '^3.1.0+1', 'build_runner': '^2.4.12'};
    case 'drift': return {'drift_dev': '^2.22.1', 'build_runner': '^2.4.12'};
    case 'objectbox': return {'objectbox_generator': '^4.0.0', 'build_runner': '^2.4.12'};
    case 'floor':     return {'floor_generator': '^1.5.0', 'build_runner': '^2.4.12'};
    default:      return {};
  }
}

/// Paquetes companion que deben agregarse via `flutter pub add` (sin versión
/// fija) para evitar conflictos de resolución con el paquete principal.
List<String> storageCompanionPackages(String storageLib) {
  final result = <String>[];
  for (final lib in _parseStorageLibNames(storageLib)) {
    result.addAll(_companionPackagesForLib(normalizeStorageLib(lib)));
  }
  return result;
}

List<String> _companionPackagesForLib(String lib) {
  switch (lib) {
    case 'drift': return ['drift_sqflite'];
    default:      return [];
  }
}
