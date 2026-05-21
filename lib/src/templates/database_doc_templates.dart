// ══════════════════════════════════════════════════════════════════════════════
// Documentación DATABASE.md por ORM
// Se genera en docs/DATABASE.md al crear el proyecto.
// ══════════════════════════════════════════════════════════════════════════════

String databaseDocTemplate(String storageLib, String appName) {
  final lib = _resolveLib(storageLib);
  switch (lib) {
    case 'drift':      return _docDrift(appName);
    case 'isar':       return _docIsar(appName);
    case 'sqflite':    return _docSqflite(appName);
    case 'objectbox':  return _docObjectBox(appName);
    case 'floor':      return _docFloor(appName);
    default:           return _docGeneric(lib, appName);
  }
}

String _resolveLib(String storageLib) {
  // Dual storage: "drift:database,shared_preferences:settings" → usa el de purpose=database
  if (storageLib.contains(',') && storageLib.contains(':')) {
    for (final part in storageLib.split(',')) {
      final chunks = part.split(':');
      if (chunks.length == 2 && chunks[1].trim() == 'database') {
        return chunks[0].trim().toLowerCase();
      }
    }
    return storageLib.split(',').first.split(':').first.trim().toLowerCase();
  }
  return storageLib.split(':').first.trim().toLowerCase();
}

// ══════════════════════════════════════════════════════════════════════════════
// Drift
// ══════════════════════════════════════════════════════════════════════════════

String _docDrift(String appName) => '''
# Base de datos — Drift

> ORM SQLite con code-gen y soporte reactivo (streams).

## Índice

- [Crear una tabla](#crear-una-tabla)
- [CRUD básico](#crud-básico)
- [Streams reactivos](#streams-reactivos)
- [Relaciones](#relaciones)
- [Queries avanzadas](#queries-avanzadas)
- [Transacciones](#transacciones)
- [Migraciones](#migraciones)

---

## Crear una tabla

```bash
cleanarch create table nombre_tabla
dart run build_runner build --delete-conflicting-outputs
```

Genera:
```
lib/app/core/database/
├── tables/nombre_tabla_table.dart   ← define las columnas
└── daos/nombre_tabla_dao.dart       ← CRUD generado
```

### Ejemplo de tabla completa

```dart
// tables/tarea_table.dart
class Tarea extends Table {
  IntColumn    get id          => integer().autoIncrement()();
  TextColumn   get titulo      => text()();
  TextColumn   get descripcion => text().nullable()();
  BoolColumn   get completada  => boolean().withDefault(const Constant(false))();
  DateTimeColumn get creadaEn  => dateTime().withDefault(currentDateAndTime)();
  IntColumn    get categoriaId => integer().nullable().references(Categoria, #id)();
}
```

---

## CRUD básico

```dart
final db = Get.find<DatabaseService>();

// Insertar — devuelve el ID generado
final id = await db.tarea.insert(
  TareaCompanion(
    titulo:      Value('Comprar leche'),
    descripcion: Value('En el supermercado'),
  ),
);

// Leer todos
final tareas = await db.tarea.getAll();

// Leer por ID
final tarea = await db.tarea.getById(1);

// Actualizar — solo los campos con Value() se modifican
await db.tarea.updateRow(
  TareaCompanion(
    id:         Value(1),
    completada: Value(true),
  ),
);

// Eliminar
await db.tarea.deleteById(1);
```

---

## Streams reactivos

```dart
// En el Controller — se actualiza automáticamente al cambiar la tabla
@override
void onInit() {
  super.onInit();
  db.tarea.watchAll().listen((lista) => tareas.value = lista);
}
```

---

## Relaciones

### Definir FK en la tabla

```dart
class Tarea extends Table {
  IntColumn get categoriaId =>
      integer().nullable().references(Categoria, #id)();
}
```

### Query JOIN en el DAO

```dart
// En tarea_dao.dart
class TareaConCategoria {
  final TareaData tarea;
  final CategoriaData? categoria;
  const TareaConCategoria(this.tarea, this.categoria);
}

@DriftAccessor(tables: [Tarea, Categoria])
class TareaDao extends DatabaseAccessor<AppDatabase>
    with _\$TareaDaoMixin {

  Future<List<TareaConCategoria>> getAllConCategoria() {
    final query = select(tarea).join([
      leftOuterJoin(categoria,
          categoria.id.equalsExp(tarea.categoriaId)),
    ]);
    return query.map((row) => TareaConCategoria(
      row.readTable(tarea),
      row.readTableOrNull(categoria),
    )).get();
  }

  Stream<List<TareaConCategoria>> watchAllConCategoria() {
    return (select(tarea).join([
      leftOuterJoin(categoria,
          categoria.id.equalsExp(tarea.categoriaId)),
    ])).watch().map((rows) => rows.map((row) => TareaConCategoria(
      row.readTable(tarea),
      row.readTableOrNull(categoria),
    )).toList());
  }
}
```

---

## Queries avanzadas

```dart
// Filtrar — solo completadas
Future<List<TareaData>> getCompletadas() =>
    (select(tarea)..where((t) => t.completada.equals(true))).get();

// Buscar por texto
Future<List<TareaData>> buscar(String texto) =>
    (select(tarea)..where((t) => t.titulo.contains(texto))).get();

// Ordenar por fecha descendente
Future<List<TareaData>> getOrdenadas() =>
    (select(tarea)..orderBy([(t) => OrderingTerm.desc(t.creadaEn)])).get();

// Paginación
Future<List<TareaData>> getPagina(int pagina, {int porPagina = 20}) =>
    (select(tarea)
          ..orderBy([(t) => OrderingTerm.desc(t.creadaEn)])
          ..limit(porPagina, offset: pagina * porPagina))
        .get();

// Contar registros
Future<int> contar() async {
  final count = tarea.id.count();
  final query = selectOnly(tarea)..addColumns([count]);
  return (await query.getSingle()).read(count) ?? 0;
}
```

---

## Transacciones

```dart
// Operaciones atómicas
Future<void> insertarTareaConCategoria(
  TareaCompanion nuevaTarea,
  CategoriaCompanion nuevaCategoria,
) async {
  await transaction(() async {
    final catId = await into(categoria).insert(nuevaCategoria);
    await into(tarea).insert(
      nuevaTarea.copyWith(categoriaId: Value(catId)),
    );
  });
}
```

---

## Migraciones

```dart
// En app_database.dart
@override
int get schemaVersion => 2; // incrementar al cambiar schema

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(tarea, tarea.descripcion);
    }
  },
);
```
''';

// ══════════════════════════════════════════════════════════════════════════════
// Isar
// ══════════════════════════════════════════════════════════════════════════════

String _docIsar(String appName) => '''
# Base de datos — Isar

> Base de datos NoSQL local con code-gen, queries tipadas y streams reactivos.

## Índice

- [Crear una colección](#crear-una-colección)
- [CRUD básico](#crud-básico)
- [Streams reactivos](#streams-reactivos)
- [Índices y búsquedas](#índices-y-búsquedas)
- [Relaciones (Links)](#relaciones-links)
- [Queries avanzadas](#queries-avanzadas)
- [Transacciones](#transacciones)

---

## Crear una colección

```bash
cleanarch create table nombre_coleccion
dart run build_runner build --delete-conflicting-outputs
```

Genera:
```
lib/app/core/database/
└── collections/nombre_coleccion_collection.dart
```

### Ejemplo de colección completa

```dart
// collections/tarea_collection.dart
@collection
class Tarea {
  Id id = Isar.autoIncrement;

  @Index()                    // índice para búsqueda rápida
  late String titulo;

  String? descripcion;
  bool completada = false;
  DateTime creadaEn = DateTime.now();

  final categoria = IsarLink<Categoria>(); // FK a uno
}
```

---

## CRUD básico

```dart
final db = Get.find<DatabaseService>();

// Insertar — la transacción de escritura es obligatoria
int id = 0;
await db.tarea.isar.writeTxn(() async {
  id = await db.tarea.put(Tarea()..titulo = 'Comprar leche');
});

// Leer todos
final tareas = await db.tarea.where().findAll();

// Leer por ID
final tarea = await db.tarea.get(id);

// Actualizar (put con id existente)
tarea!.completada = true;
await db.tarea.isar.writeTxn(() async {
  await db.tarea.put(tarea);
});

// Eliminar
await db.tarea.isar.writeTxn(() async {
  await db.tarea.delete(id);
});
```

> **Nota:** Para acceder a `isar` desde DatabaseService agrega:
> ```dart
> Isar get _isar => AppDatabase.instance;
> IsarCollection<Tarea> get tarea => _isar.collection<Tarea>();
> ```

---

## Streams reactivos

```dart
// En el Controller — escucha cambios automáticos
@override
void onInit() {
  super.onInit();
  db.tarea
    .where()
    .watch(fireImmediately: true)
    .listen((lista) => tareas.value = lista);
}
```

---

## Índices y búsquedas

```dart
// Requiere @Index() en el campo de la colección

// Búsqueda por prefijo (rápido con índice)
final resultados = await db.tarea
    .where()
    .tituloStartsWith('Com')
    .findAll();

// Filtro combinado
final pendientes = await db.tarea
    .filter()
    .completadaEqualTo(false)
    .sortByCreadaEnDesc()
    .findAll();

// Texto que contiene
final busqueda = await db.tarea
    .filter()
    .tituloContains('leche', caseSensitive: false)
    .findAll();
```

---

## Relaciones (Links)

```dart
// ToOne — tarea pertenece a una categoría
final cat = await db.categoria.get(1);
await AppDatabase.instance.writeTxn(() async {
  nuevaTarea.categoria.value = cat;
  await db.tarea.put(nuevaTarea);
  await nuevaTarea.categoria.save();
});

// Leer relación
final tarea = await db.tarea.get(1);
await tarea!.categoria.load();
print(tarea.categoria.value?.nombre);

// ToMany — tarea tiene varias etiquetas
@collection
class Tarea {
  Id id = Isar.autoIncrement;
  final etiquetas = IsarLinks<Etiqueta>();
}

await tarea.etiquetas.load();
final lista = tarea.etiquetas.toList();
```

---

## Queries avanzadas

```dart
// Paginación
final pagina = await db.tarea
    .where()
    .offset(pagina * 20)
    .limit(20)
    .findAll();

// Contar
final total = await db.tarea.count();

// Agregaciones con filter()
final pendientes = await db.tarea
    .filter()
    .completadaEqualTo(false)
    .count();
```

---

## Transacciones

```dart
// Múltiples escrituras atómicas
await AppDatabase.instance.writeTxn(() async {
  final catId = await db.categoria.put(Categoria()..nombre = 'Trabajo');
  final tarea = Tarea()
    ..titulo = 'Reunión'
    ..categoria.value = await db.categoria.get(catId);
  await db.tarea.put(tarea);
  await tarea.categoria.save();
});
```
''';

// ══════════════════════════════════════════════════════════════════════════════
// Sqflite
// ══════════════════════════════════════════════════════════════════════════════

String _docSqflite(String appName) => '''
# Base de datos — Sqflite

> Base de datos SQLite relacional. Control total del SQL.

## Índice

- [Crear una tabla](#crear-una-tabla)
- [CRUD básico](#crud-básico)
- [Relaciones y JOINs](#relaciones-y-joins)
- [Queries avanzadas](#queries-avanzadas)
- [Transacciones](#transacciones)
- [Migraciones](#migraciones)

---

## Crear una tabla

```bash
cleanarch create table nombre_tabla
```

Genera:
```
lib/app/core/database/
├── models/nombre_tabla_model.dart   ← modelo Dart (fromMap/toMap)
└── daos/nombre_tabla_dao.dart       ← CRUD con SQL
```

Luego define el SQL en `AppDatabase._onCreate`:
```dart
static Future<void> _onCreate(Database db, int version) async {
  await db.execute(\'\'\'
    CREATE TABLE IF NOT EXISTS tarea (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo      TEXT    NOT NULL,
      descripcion TEXT,
      completada  INTEGER NOT NULL DEFAULT 0,
      creada_en   INTEGER NOT NULL,
      categoria_id INTEGER REFERENCES categoria(id) ON DELETE SET NULL
    )
  \'\'\');
}
```

---

## CRUD básico

```dart
final db = Get.find<DatabaseService>();

// Insertar — devuelve el ID generado
final id = await db.tarea.insert(
  TareaModel(
    titulo:    'Comprar leche',
    completada: false,
    creadaEn:  DateTime.now(),
  ),
);

// Leer todos
final tareas = await db.tarea.getAll();

// Leer por ID
final tarea = await db.tarea.getById(1);

// Actualizar
await db.tarea.updateRow(
  tarea!.copyWith(completada: true),
);

// Eliminar
await db.tarea.deleteById(1);
```

---

## Relaciones y JOINs

```dart
// En tarea_dao.dart — agregar query con JOIN
Future<List<Map<String, dynamic>>> getAllConCategoria() async {
  final db = await _db;
  return db.rawQuery(\'\'\'
    SELECT t.*, c.nombre AS categoria_nombre
    FROM   tarea t
    LEFT JOIN categoria c ON t.categoria_id = c.id
    ORDER BY t.id DESC
  \'\'\');
}
```

---

## Queries avanzadas

```dart
// En tarea_dao.dart

// Filtrar por campo
Future<List<TareaModel>> getPendientes() async {
  final db = await _db;
  final maps = await db.query(_table,
      where: 'completada = ?', whereArgs: [0]);
  return maps.map(TareaModel.fromMap).toList();
}

// Búsqueda por texto
Future<List<TareaModel>> buscar(String texto) async {
  final db = await _db;
  final maps = await db.query(_table,
      where: 'titulo LIKE ?', whereArgs: ['%\$texto%']);
  return maps.map(TareaModel.fromMap).toList();
}

// Paginación
Future<List<TareaModel>> getPagina(int pagina,
    {int porPagina = 20}) async {
  final db = await _db;
  final maps = await db.query(_table,
      orderBy: 'id DESC',
      limit:   porPagina,
      offset:  pagina * porPagina);
  return maps.map(TareaModel.fromMap).toList();
}

// Contar registros
Future<int> contar() async {
  final db = await _db;
  final result = await db.rawQuery(
      'SELECT COUNT(*) FROM \$_table');
  return Sqflite.firstIntValue(result) ?? 0;
}
```

---

## Transacciones

```dart
// En tarea_dao.dart
Future<void> insertarConCategoria(
    TareaModel tarea, CategoriaModel categoria) async {
  final db = await _db;
  await db.transaction((txn) async {
    final catId = await txn.insert('categoria', categoria.toMap());
    await txn.insert(
      _table,
      tarea.copyWith(categoriaId: catId).toMap(),
    );
  });
}
```

---

## Migraciones

```dart
// En app_database.dart — incrementar versión
return openDatabase(
  p.join(dbPath, 'app.db'),
  version: 2,
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
);

static Future<void> _onUpgrade(
    Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(
        'ALTER TABLE tarea ADD COLUMN descripcion TEXT');
  }
}
```
''';

// ══════════════════════════════════════════════════════════════════════════════
// ObjectBox
// ══════════════════════════════════════════════════════════════════════════════

String _docObjectBox(String appName) => '''
# Base de datos — ObjectBox

> Base de datos NoSQL de alto rendimiento con code-gen y soporte ACID.

## Índice

- [Crear una entidad](#crear-una-entidad)
- [CRUD básico](#crud-básico)
- [Streams reactivos](#streams-reactivos)
- [Índices y búsquedas](#índices-y-búsquedas)
- [Relaciones](#relaciones)
- [Queries avanzadas](#queries-avanzadas)

---

## Crear una entidad

```bash
cleanarch create table nombre_entidad
dart run build_runner build --delete-conflicting-outputs
```

Genera:
```
lib/app/core/database/
└── entities/nombre_entidad_entity.dart
```

ObjectBox descubre automáticamente todas las clases `@Entity()` — no hay registro manual.

### Ejemplo de entidad completa

```dart
@Entity()
class Tarea {
  int id;
  @Index() late String titulo;  // índice para búsqueda rápida
  String? descripcion;
  bool completada = false;
  DateTime creadaEn = DateTime.now();

  final categoria = ToOne<Categoria>(); // FK a uno

  Tarea({this.id = 0});
}
```

---

## CRUD básico

```dart
final db = Get.find<DatabaseService>();

// Insertar — devuelve el ID generado (síncrono)
final id = db.tarea.put(
  Tarea()..titulo = 'Comprar leche',
);

// Leer todos
final tareas = db.tarea.getAll();

// Leer por ID
final tarea = db.tarea.get(id);

// Actualizar (put con id existente)
tarea!.completada = true;
db.tarea.put(tarea);

// Eliminar
db.tarea.remove(id);

// Eliminar múltiples
db.tarea.removeMany([1, 2, 3]);
```

> ObjectBox es **síncrono** en la mayoría de operaciones. No necesitas `await`.

---

## Streams reactivos

```dart
// En el Controller — escucha cambios automáticos
@override
void onInit() {
  super.onInit();
  db.tarea
    .query()
    .watch(triggerImmediately: true)
    .listen((query) => tareas.value = query.find());
}
```

---

## Índices y búsquedas

```dart
// Requiere @Index() en el campo de la entidad

// Buscar por campo exacto
final query = db.tarea
    .query(Tarea_.completada.equals(false))
    .build();
final pendientes = query.find();
query.close(); // liberar recursos

// Texto que contiene
final resultados = db.tarea
    .query(Tarea_.titulo.contains('leche', caseSensitive: false))
    .build()
    .find();

// Ordenar
final ordenadas = (db.tarea.query()
    ..order(Tarea_.creadaEn, flags: Order.descending))
    .build()
    .find();
```

---

## Relaciones

```dart
// ToOne — tarea pertenece a una categoría
@Entity()
class Tarea {
  int id;
  late String titulo;
  final categoria = ToOne<Categoria>();
  Tarea({this.id = 0});
}

// Guardar con relación (síncrono)
final cat = db.categoria.get(1)!;
final tarea = Tarea()..titulo = 'Reunión';
tarea.categoria.target = cat;
db.tarea.put(tarea);

// Leer relación (acceso directo, lazy loading)
final t = db.tarea.get(1)!;
print(t.categoria.target?.nombre);

// ToMany — categoria tiene muchas tareas
@Entity()
class Categoria {
  int id;
  late String nombre;
  @Backlink('categoria')
  final tareas = ToMany<Tarea>();
  Categoria({this.id = 0});
}

// Leer backlink
final cat = db.categoria.get(1)!;
cat.tareas.applyToDb();
print(cat.tareas.length);
```

---

## Queries avanzadas

```dart
// Paginación
final pagina = (db.tarea.query()
    ..order(Tarea_.id, flags: Order.descending)
    ..offset = pagina * 20
    ..limit  = 20)
    .build()
    .find();

// Contar
final total = db.tarea.count();

// Contar con filtro
final pendientes = db.tarea
    .query(Tarea_.completada.equals(false))
    .build()
    .count();

// Múltiples condiciones
final query = db.tarea
    .query(Tarea_.completada.equals(false)
        .and(Tarea_.creadaEn.greaterThan(
            DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch)))
    .build();
```
''';

// ══════════════════════════════════════════════════════════════════════════════
// Floor
// ══════════════════════════════════════════════════════════════════════════════

String _docFloor(String appName) => '''
# Base de datos — Floor

> ORM SQLite inspirado en Room (Android) con code-gen y DAOs abstractos.

## Índice

- [Crear una tabla](#crear-una-tabla)
- [CRUD básico](#crud-básico)
- [Streams reactivos](#streams-reactivos)
- [Relaciones y FK](#relaciones-y-fk)
- [Queries avanzadas](#queries-avanzadas)
- [Migraciones](#migraciones)

---

## Crear una tabla

```bash
cleanarch create table nombre_tabla
dart run build_runner build --delete-conflicting-outputs
```

Genera:
```
lib/app/core/database/
├── entities/nombre_tabla_entity.dart  ← @entity class
└── daos/nombre_tabla_dao.dart         ← @dao abstract class
```

### Ejemplo de entidad completa

```dart
@entity
class Tarea {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String titulo;

  @ColumnInfo(name: 'descripcion')
  final String? descripcion;

  final bool completada;

  @ColumnInfo(name: 'creada_en')
  final DateTime creadaEn;

  @ColumnInfo(name: 'categoria_id')
  final int? categoriaId; // FK

  const Tarea({
    this.id,
    required this.titulo,
    this.descripcion,
    this.completada = false,
    required this.creadaEn,
    this.categoriaId,
  });
}
```

---

## CRUD básico

```dart
final db = Get.find<DatabaseService>();

// Insertar — devuelve el ID generado
final id = await db.tarea.insert(
  Tarea(titulo: 'Comprar leche', creadaEn: DateTime.now()),
);

// Leer todos
final tareas = await db.tarea.getAll();

// Leer por ID
final tarea = await db.tarea.getById(1);

// Actualizar
await db.tarea.updateRow(
  Tarea(
    id:         tarea!.id,
    titulo:     tarea.titulo,
    completada: true,
    creadaEn:   tarea.creadaEn,
  ),
);

// Eliminar
await db.tarea.deleteById(1);
```

---

## Streams reactivos

```dart
// En el Controller — se actualiza automáticamente
@override
void onInit() {
  super.onInit();
  db.tarea.watchAll().listen((lista) => tareas.value = lista);
}
```

---

## Relaciones y FK

```dart
// En tarea_entity.dart — con FK
@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns:  ['categoria_id'],
      parentColumns: ['id'],
      entity:        Categoria,
      onDelete:      ForeignKeyAction.setNull,
    ),
  ],
)
@entity
class Tarea {
  @PrimaryKey(autoGenerate: true) final int? id;
  final String titulo;
  @ColumnInfo(name: 'categoria_id') final int? categoriaId;
  const Tarea({this.id, required this.titulo, this.categoriaId});
}

// En tarea_dao.dart — query con JOIN
@Query(\'\'\'
  SELECT t.*, c.nombre AS categoria_nombre
  FROM   Tarea t
  LEFT JOIN Categoria c ON t.categoriaId = c.id
\'\'\')
Future<List<Map<String, dynamic>>> getAllConCategoria();
```

---

## Queries avanzadas

```dart
// En tarea_dao.dart

@Query('SELECT * FROM Tarea WHERE completada = 0')
Future<List<Tarea>> getPendientes();

@Query('SELECT * FROM Tarea WHERE completada = 0')
Stream<List<Tarea>> watchPendientes();

@Query('SELECT * FROM Tarea WHERE titulo LIKE :patron')
Future<List<Tarea>> buscar(String patron); // pasar '%texto%'

@Query('SELECT * FROM Tarea WHERE categoria_id = :id')
Future<List<Tarea>> getPorCategoria(int id);

@Query('SELECT COUNT(*) FROM Tarea')
Future<int?> contar();

// Paginación con LIMIT/OFFSET
@Query('SELECT * FROM Tarea ORDER BY id DESC LIMIT :limit OFFSET :offset')
Future<List<Tarea>> getPagina(int limit, int offset);
```

---

## Migraciones

```dart
// En AppDatabase.init() — agregar migration al builder
_instance = await \$FloorAppFloorDatabase
    .databaseBuilder('app.db')
    .addMigrations([
      Migration(1, 2, (db) async {
        await db.execute(
            'ALTER TABLE Tarea ADD COLUMN descripcion TEXT');
      }),
      Migration(2, 3, (db) async {
        await db.execute(
            'CREATE INDEX idx_tarea_titulo ON Tarea(titulo)');
      }),
    ])
    .build();
```

Actualizar también la versión en `@Database`:
```dart
@Database(version: 3, entities: [Tarea, Categoria])
abstract class AppFloorDatabase extends FloorDatabase { ... }
```
''';

// ══════════════════════════════════════════════════════════════════════════════
// Genérico
// ══════════════════════════════════════════════════════════════════════════════

String _docGeneric(String lib, String appName) => '''
# Base de datos — $lib

> Librería de almacenamiento local seleccionada: `$lib`.

## Uso

Accede a los datos a través de `DatabaseService`:

```dart
final db = Get.find<DatabaseService>();
```

Consulta la documentación oficial de `$lib` para los métodos específicos.

## Agregar tablas

```bash
# Solo disponible para: drift, isar, sqflite, objectbox, floor
cleanarch create table nombre
```

## Más información

- Pub.dev: https://pub.dev/packages/$lib
''';
