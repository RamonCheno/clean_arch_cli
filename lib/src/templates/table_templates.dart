// ══════════════════════════════════════════════════════════════════════════════
// Templates para create table
// Soporta: Drift, Isar, Sqflite, ObjectBox, Floor
// ══════════════════════════════════════════════════════════════════════════════

// ── Drift — Tabla ─────────────────────────────────────────────────────────────

String driftTableTemplate(String snake, String pascal) => '''
import 'package:drift/drift.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  $pascal — Tabla Drift                                                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Tipos de columna disponibles:
//   integer()    → int           text()       → String
//   boolean()    → bool          dateTime()   → DateTime
//   real()       → double        blob()       → Uint8List
//
// Modificadores comunes:
//   .autoIncrement()                        → PK autoincremental
//   .nullable()                             → permite NULL
//   .withDefault(const Constant(valor))     → valor por defecto
//   .references(OtraTabla, #campoId)        → clave foránea (FK)
//
// Regenera después de modificar:
//   dart run build_runner build --delete-conflicting-outputs
class $pascal extends Table {
  IntColumn get id => integer().autoIncrement()();
  // TODO: define tus columnas aquí
  // Ejemplos:
  //   TextColumn     get nombre    => text()();
  //   BoolColumn     get activo    => boolean().withDefault(const Constant(true))();
  //   DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  //   IntColumn      get otraId    => integer().nullable().references(OtraTabla, #id)();
}
''';

// ── Drift — DAO ───────────────────────────────────────────────────────────────

String driftDaoTemplate(
  String snake,
  String pascal,
  String camel,
  String packageName,
) =>
    '''
import 'package:drift/drift.dart';
import 'package:$packageName/app/core/database/app_database.dart';
import 'package:$packageName/app/core/database/tables/${snake}_table.dart';

part '${snake}_dao.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ${pascal}Dao — Queries para la tabla $pascal                           │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Drift genera dos clases por cada tabla:
//   $pascal          → definición de la tabla (columnas, PK, etc.)
//   ${pascal}Data    → fila de datos (lo que devuelven las queries)
//   ${pascal}Companion → usado para insertar / actualizar
@DriftAccessor(tables: [$pascal])
class ${pascal}Dao extends DatabaseAccessor<AppDatabase>
    with _\$${pascal}DaoMixin {
  ${pascal}Dao(super.db);

  // ── Lecturas ──────────────────────────────────────────────────────────────

  /// Devuelve todos los registros una sola vez.
  Future<List<${pascal}Data>> getAll() => select($camel).get();

  /// Stream reactivo — se actualiza automáticamente al cambiar la tabla.
  Stream<List<${pascal}Data>> watchAll() => select($camel).watch();

  /// Busca por ID. Devuelve null si no existe.
  Future<${pascal}Data?> getById(int id) =>
      (select($camel)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Escrituras ────────────────────────────────────────────────────────────

  /// Inserta un nuevo registro. Devuelve el ID generado.
  Future<int> insert(${pascal}Companion entry) =>
      into($camel).insert(entry);

  /// Actualiza un registro existente. Devuelve true si se modificó.
  Future<bool> updateRow(${pascal}Companion entry) =>
      (update($camel)..where((t) => t.id.equals(entry.id.value)))
          .write(entry)
          .then((n) => n > 0);

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina por ID. Devuelve true si se eliminó algo.
  Future<bool> deleteById(int id) =>
      (delete($camel)..where((t) => t.id.equals(id)))
          .go()
          .then((n) => n > 0);
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// Isar
// ══════════════════════════════════════════════════════════════════════════════

// ── Isar — Colección ──────────────────────────────────────────────────────────

String isarCollectionTemplate(String snake, String pascal) => '''
import 'package:isar/isar.dart';

part '${snake}_collection.g.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  $pascal — Colección Isar                                               │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Isar genera el schema y los índices automáticamente.
//
// Tipos de campo comunes:
//   late String nombre;         → texto requerido
//   String? descripcion;        → texto nullable
//   bool activo = true;         → booleano con defecto
//   int contador = 0;           → entero
//   double precio = 0.0;        → decimal
//   DateTime creadaEn = ...;    → fecha/hora
//   List<String> etiquetas = []; → lista
//
// Índices para búsquedas rápidas:
//   @Index() late String nombre;              → índice simple
//   @Index(unique: true) late String email;   → índice único
//   @Index(composite: [CompositeIndex('tipo')]) late String nombre;
//
// Regenera después de modificar:
//   dart run build_runner build --delete-conflicting-outputs
@collection
class $pascal {
  Id id = Isar.autoIncrement;
  // TODO: define tus campos aquí
  // Ejemplos:
  //   late String titulo;
  //   String? descripcion;
  //   bool completada = false;
  //   DateTime creadaEn = DateTime.now();
  //   @Index() late String nombre;
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// Sqflite
// ══════════════════════════════════════════════════════════════════════════════

// ── Sqflite — Modelo ──────────────────────────────────────────────────────────

String sqfliteModelTemplate(String snake, String pascal) => '''
// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ${pascal}Model — Modelo de datos para la tabla $snake                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// fromMap() convierte una fila de SQLite a este modelo.
// toMap()   convierte este modelo a un Map para insertar/actualizar.
//
// Después de agregar columnas:
//   1. Agrega el campo en la clase
//   2. Agrega la columna en AppDatabase._onCreate (SQL)
//   3. Si la tabla ya existe, agrega migración en _onUpgrade
class ${pascal}Model {
  final int? id;
  // TODO: agrega tus campos aquí
  // Ejemplos:
  //   final String titulo;
  //   final String? descripcion;
  //   final bool activo;
  //   final DateTime creadaEn;

  const ${pascal}Model({
    this.id,
    // TODO: agrega los campos al constructor
  });

  factory ${pascal}Model.fromMap(Map<String, dynamic> map) {
    return ${pascal}Model(
      id: map['id'] as int?,
      // TODO: mapea los campos
      // titulo: map['titulo'] as String,
      // descripcion: map['descripcion'] as String?,
      // activo: (map['activo'] as int) == 1,
      // creadaEn: DateTime.fromMillisecondsSinceEpoch(map['creada_en'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      // TODO: agrega los campos
      // 'titulo': titulo,
      // 'descripcion': descripcion,
      // 'activo': activo ? 1 : 0,
      // 'creada_en': creadaEn.millisecondsSinceEpoch,
    };
  }

  ${pascal}Model copyWith({int? id}) {
    return ${pascal}Model(
      id: id ?? this.id,
      // TODO: copia los campos
    );
  }

  @override
  String toString() => '${pascal}Model(id: \$id)';
}
''';

// ── Sqflite — DAO ─────────────────────────────────────────────────────────────

String sqfliteDaoTemplate(String snake, String pascal, String packageName) => '''
import 'package:sqflite/sqflite.dart';
import 'package:$packageName/app/core/database/app_database.dart';
import '../models/${snake}_model.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ${pascal}Dao — Queries SQL para la tabla $snake                        │
// └─────────────────────────────────────────────────────────────────────────┘
class ${pascal}Dao {
  static const _table = '$snake';

  /// Acceso lazy a la base de datos (se abre en la primera consulta).
  Future<Database> get _db => AppDatabase.database;

  // ── Lecturas ──────────────────────────────────────────────────────────────

  Future<List<${pascal}Model>> getAll() async {
    final db = await _db;
    final maps = await db.query(_table, orderBy: 'id DESC');
    return maps.map(${pascal}Model.fromMap).toList();
  }

  Future<${pascal}Model?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : ${pascal}Model.fromMap(maps.first);
  }

  // ── Escrituras ────────────────────────────────────────────────────────────

  /// Inserta un nuevo registro. Devuelve el ID generado.
  Future<int> insert(${pascal}Model model) async {
    final db = await _db;
    return db.insert(
      _table,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza un registro existente. Devuelve true si se modificó.
  Future<bool> updateRow(${pascal}Model model) async {
    final db = await _db;
    final n = await db.update(
      _table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
    return n > 0;
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina por ID. Devuelve true si se eliminó algo.
  Future<bool> deleteById(int id) async {
    final db = await _db;
    final n = await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    return n > 0;
  }

  // ── Queries personalizadas ────────────────────────────────────────────────
  // Ejemplo con filtro:
  //   Future<List<${pascal}Model>> getActivos() async {
  //     final db = await _db;
  //     final maps = await db.query(_table, where: 'activo = 1');
  //     return maps.map(${pascal}Model.fromMap).toList();
  //   }
  //
  // Ejemplo con rawQuery:
  //   Future<int> contar() async {
  //     final db = await _db;
  //     final result = await db.rawQuery('SELECT COUNT(*) FROM \$_table');
  //     return Sqflite.firstIntValue(result) ?? 0;
  //   }
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// ObjectBox
// ══════════════════════════════════════════════════════════════════════════════

// ── ObjectBox — Entidad ───────────────────────────────────────────────────────

String objectBoxEntityTemplate(String snake, String pascal) => '''
import 'package:objectbox/objectbox.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  $pascal — Entidad ObjectBox                                            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ObjectBox descubre automáticamente todas las clases @Entity().
// No es necesario registrarlas manualmente en AppDatabase.
//
// Tipos de campo comunes:
//   int id = 0;               → PK autoincremental (requerido)
//   late String nombre;       → texto requerido
//   String? descripcion;      → texto nullable
//   bool activo = true;       → booleano
//   double precio = 0.0;      → decimal
//   DateTime creadaEn = ...;  → fecha/hora
//
// Índices para búsquedas rápidas:
//   @Index() late String nombre;
//   @Unique() late String email;
//
// Relaciones:
//   final categoria = ToOne<Categoria>();        → FK a uno
//   final etiquetas = ToMany<Etiqueta>();        → FK a muchos
//
// Regenera después de modificar:
//   dart run build_runner build --delete-conflicting-outputs
@Entity()
class $pascal {
  int id;
  // TODO: define tus campos aquí
  // Ejemplos:
  //   late String titulo;
  //   String? descripcion;
  //   bool completada = false;
  //   DateTime creadaEn = DateTime.now();
  //   @Index() late String nombre;

  $pascal({this.id = 0});
}
''';

// ══════════════════════════════════════════════════════════════════════════════
// Floor
// ══════════════════════════════════════════════════════════════════════════════

// ── Floor — Entidad ───────────────────────────────────────────────────────────

String floorEntityTemplate(String snake, String pascal) => '''
import 'package:floor/floor.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  $pascal — Entidad Floor                                                │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Floor genera la tabla SQL a partir de esta clase.
//
// Tipos soportados: int, double, String, bool, Uint8List
// Para otros tipos, implementa un TypeConverter.
//
// Columnas con nombre personalizado:
//   @ColumnInfo(name: 'created_at') final DateTime creadaEn;
//
// Índices:
//   Agrégalos en la anotación @entity a nivel de clase:
//   @Entity(tableName: '$snake', indices: [Index(value: ['nombre'])])
//
// Regenera después de modificar:
//   dart run build_runner build --delete-conflicting-outputs
@entity
class $pascal {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  // TODO: define tus campos aquí
  // Ejemplos:
  //   final String titulo;
  //   final String? descripcion;
  //   @ColumnInfo(name: 'completada') final bool completada;
  //   @ColumnInfo(name: 'creada_en') final DateTime creadaEn;

  const $pascal({
    this.id,
    // TODO: agrega los campos al constructor
  });
}
''';

// ── Floor — DAO ───────────────────────────────────────────────────────────────

String floorDaoTemplate(String snake, String pascal, String camel, String packageName) => '''
import 'package:floor/floor.dart';
import '../entities/${snake}_entity.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ${pascal}Dao — Queries SQL para la entidad $pascal (Floor)             │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Floor genera la implementación a partir de las anotaciones.
// Regenera: dart run build_runner build --delete-conflicting-outputs
@dao
abstract class ${pascal}Dao {
  // ── Lecturas ──────────────────────────────────────────────────────────────

  @Query('SELECT * FROM $pascal')
  Future<List<$pascal>> getAll();

  @Query('SELECT * FROM $pascal')
  Stream<List<$pascal>> watchAll();

  @Query('SELECT * FROM $pascal WHERE id = :id')
  Future<$pascal?> getById(int id);

  // ── Escrituras ────────────────────────────────────────────────────────────

  @insert
  Future<int> insert($pascal entity);

  @update
  Future<void> updateRow($pascal entity);

  // ── Eliminación ───────────────────────────────────────────────────────────

  @delete
  Future<void> deleteRow($pascal entity);

  @Query('DELETE FROM $pascal WHERE id = :id')
  Future<void> deleteById(int id);

  // ── Queries personalizadas ────────────────────────────────────────────────
  // Ejemplo:
  //   @Query('SELECT * FROM $pascal WHERE activo = 1')
  //   Future<List<$pascal>> getActivos();
}
''';
