import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/templates/table_templates.dart';
// ignore_for_file: prefer_single_quotes
import 'package:clean_arch_cli/src/generators/file_writer.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  TableGenerator — Genera tabla/colección + DAO según el ORM del         │
// │  proyecto (Drift, Isar, Sqflite) e inyecta en AppDatabase y Service.    │
// └─────────────────────────────────────────────────────────────────────────┘
class TableGenerator {
  final bool _dryRun;
  late final FileWriter _writer;

  TableGenerator({bool dryRun = false}) : _dryRun = dryRun {
    _writer = FileWriter(overwrite: false, dryRun: dryRun);
  }

  Future<void> generate(String name, String root) async {
    final snake = name.toSnakeCase();
    final pascal = snake.toPascalCase();
    final camel = snake.toCamelCase();
    final packageName = readPackageName(root);
    final dbDir = p.join(root, 'lib', 'app', 'core', 'database');

    Console.header('Generando tabla: $pascal');

    final orm = _detectOrm(root);

    switch (orm) {
      case 'drift':
        _generateDrift(dbDir, snake, pascal, camel, packageName);
      case 'isar':
        _generateIsar(dbDir, snake, pascal, packageName);
      case 'sqflite':
        _generateSqflite(dbDir, snake, pascal, packageName);
      case 'objectbox':
        _generateObjectBox(dbDir, snake, pascal, packageName);
      case 'floor':
        _generateFloor(dbDir, snake, pascal, camel, packageName);
      default:
        Console.error(
          'No se detectó un ORM compatible (drift, isar, sqflite, objectbox, floor).\n'
          'Asegúrate de tener una de estas dependencias en pubspec.yaml.',
        );
        exit(1);
    }

    Console.success('');
    Console.success('Tabla "$pascal" creada exitosamente.');
    _printNextSteps(orm, snake);
  }

  // ── Drift ──────────────────────────────────────────────────────────────────

  void _generateDrift(String dbDir, String snake, String pascal, String camel,
      String packageName) {
    _writer.createDir(p.join(dbDir, 'tables'));
    _writer.createDir(p.join(dbDir, 'daos'));

    _writer.write(
      p.join(dbDir, 'tables', '${snake}_table.dart'),
      driftTableTemplate(snake, pascal),
    );
    _writer.write(
      p.join(dbDir, 'daos', '${snake}_dao.dart'),
      driftDaoTemplate(snake, pascal, camel, packageName),
    );

    if (_dryRun) return;
    _injectDriftAppDatabase(dbDir, snake, pascal);
    _injectDriftDatabaseService(
      dbDir: dbDir,
      root: _rootFromDbDir(dbDir),
      snake: snake,
      pascal: pascal,
      packageName: packageName,
    );
  }

  void _injectDriftAppDatabase(String dbDir, String snake, String pascal) {
    final filePath = p.join(dbDir, 'app_database.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró app_database.dart — agrega la tabla manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    final tableImport = "import 'tables/${snake}_table.dart';";
    final daoImport   = "import 'daos/${snake}_dao.dart';";

    if (!content.contains(tableImport)) {
      content = _injectBeforeMarker(content, '// cleanarch:table_import', tableImport,
          fallback: () => content.replaceFirst(
                "part 'app_database.g.dart';",
                "$tableImport\npart 'app_database.g.dart';",
              ));
    }
    if (!content.contains(daoImport)) {
      content = _injectBeforeMarker(content, '// cleanarch:dao_import', daoImport,
          fallback: () => content.replaceFirst(
                "part 'app_database.g.dart';",
                "$daoImport\npart 'app_database.g.dart';",
              ));
    }

    content = _ensureDaosClause(content);
    content = _injectIntoAnnotationList(content, 'tables', pascal);
    content = _injectIntoAnnotationList(content, 'daos', '${pascal}Dao');

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ $pascal registrada en app_database.dart');
  }

  void _injectDriftDatabaseService({
    required String dbDir,
    required String root,
    required String snake,
    required String pascal,
    required String packageName,
  }) {
    final filePath = p.join(root, 'lib', 'app', 'core', 'services', 'database_service.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró database_service.dart — agrega el getter manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();
    final camel = snake.toCamelCase();

    final daoImport = "import 'package:$packageName/app/core/database/daos/${snake}_dao.dart';";
    if (!content.contains(daoImport)) {
      content = _injectBeforeMarker(content, '// cleanarch:dao_import', daoImport,
          fallback: () {
        final anchor = "import 'package:$packageName/app/core/database/app_database.dart';";
        return content.replaceFirst(anchor, '$anchor\n$daoImport');
      });
    }

    final getter = '${pascal}Dao get $camel => _db.${camel}Dao;';
    if (!content.contains(getter)) {
      content = _injectBeforeMarker(content, '// cleanarch:dao_getter', getter,
          fallback: () => content.replaceFirst(
                'final AppDatabase _db = AppDatabase();',
                'final AppDatabase _db = AppDatabase();\n\n  $getter',
              ));
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ ${pascal}Dao getter agregado a database_service.dart');
  }

  // ── Isar ───────────────────────────────────────────────────────────────────

  void _generateIsar(String dbDir, String snake, String pascal, String packageName) {
    _writer.createDir(p.join(dbDir, 'collections'));

    _writer.write(
      p.join(dbDir, 'collections', '${snake}_collection.dart'),
      isarCollectionTemplate(snake, pascal),
    );

    if (_dryRun) return;
    _injectIsarAppDatabase(dbDir, snake, pascal);
    _injectIsarDatabaseService(
      root: _rootFromDbDir(dbDir),
      snake: snake,
      pascal: pascal,
      packageName: packageName,
    );
  }

  void _injectIsarAppDatabase(String dbDir, String snake, String pascal) {
    final filePath = p.join(dbDir, 'app_database.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró app_database.dart — agrega el schema manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    // Import de la colección
    final collectionImport = "import 'collections/${snake}_collection.dart';";
    if (!content.contains(collectionImport)) {
      content = _injectBeforeMarker(
        content, '// cleanarch:collection_import', collectionImport,
        fallback: () {
          // Sin marcador → insertar después del último import de paquete
          final lastImport = _lastImportIndex(content);
          if (lastImport == -1) return content;
          final insertPos = content.indexOf('\n', lastImport) + 1;
          return content.substring(0, insertPos) +
              '$collectionImport\n' +
              content.substring(insertPos);
        },
      );
    }

    // Agregar schema a la lista Isar.open([...])
    // El marcador está DENTRO del bloque de la lista
    final schemaEntry = '${pascal}Schema,';
    if (!content.contains(schemaEntry)) {
      content = _injectBeforeMarker(
        content, '// cleanarch:schema', schemaEntry,
        fallback: () {
          // Sin marcador → buscar 'schemas,' o el parámetro directo
          return content.replaceFirst(
            'schemas,',
            '[$schemaEntry/* agrega más schemas aquí */],',
          );
        },
      );
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ ${pascal}Schema registrado en app_database.dart');
  }

  void _injectIsarDatabaseService({
    required String root,
    required String snake,
    required String pascal,
    required String packageName,
  }) {
    final filePath = p.join(root, 'lib', 'app', 'core', 'services', 'database_service.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró database_service.dart — agrega el getter manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();
    final camel = snake.toCamelCase();

    // Import de la colección
    final collectionImport =
        "import 'package:$packageName/app/core/database/collections/${snake}_collection.dart';";
    if (!content.contains(collectionImport)) {
      content = _injectBeforeMarker(
        content, '// cleanarch:collection_import', collectionImport,
        fallback: () {
          final anchor =
              "import 'package:$packageName/app/core/database/app_database.dart';";
          return content.replaceFirst(anchor, '$anchor\n$collectionImport');
        },
      );
    }

    // Getter de la colección
    final getter = 'IsarCollection<$pascal> get $camel => AppDatabase.instance.collection<$pascal>();';
    if (!content.contains(getter)) {
      content = _injectBeforeMarker(
        content, '// cleanarch:collection_getter', getter,
        fallback: () => content.replaceFirst(
              'Isar get _isar => AppDatabase.instance;',
              'Isar get _isar => AppDatabase.instance;\n\n  $getter',
            ),
      );
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ IsarCollection<$pascal> getter agregado a database_service.dart');
  }

  // ── Sqflite ────────────────────────────────────────────────────────────────

  void _generateSqflite(String dbDir, String snake, String pascal, String packageName) {
    _writer.createDir(p.join(dbDir, 'models'));
    _writer.createDir(p.join(dbDir, 'daos'));

    _writer.write(
      p.join(dbDir, 'models', '${snake}_model.dart'),
      sqfliteModelTemplate(snake, pascal),
    );
    _writer.write(
      p.join(dbDir, 'daos', '${snake}_dao.dart'),
      sqfliteDaoTemplate(snake, pascal, packageName),
    );

    if (_dryRun) return;
    _injectSqfliteAppDatabase(dbDir, snake, pascal);
    _injectSqfliteDatabaseService(
      root: _rootFromDbDir(dbDir),
      snake: snake,
      pascal: pascal,
      packageName: packageName,
    );
  }

  void _injectSqfliteAppDatabase(String dbDir, String snake, String pascal) {
    final filePath = p.join(dbDir, 'app_database.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró app_database.dart — agrega el CREATE TABLE manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    // Agregar SQL de creación de tabla
    final createSql =
        "await db.execute('CREATE TABLE IF NOT EXISTS $snake (id INTEGER PRIMARY KEY AUTOINCREMENT /* TODO: agrega columnas */)');"
        " // TODO: define las columnas en ${snake}_model.dart";
    if (!content.contains("CREATE TABLE IF NOT EXISTS $snake")) {
      content = _injectBeforeMarker(
        content, '// cleanarch:table_create', createSql,
        fallback: () {
          Console.warning(
            '  Marcador "// cleanarch:table_create" no encontrado.\n'
            '  Agrega manualmente en AppDatabase._onCreate():\n'
            '  $createSql',
          );
          return content;
        },
      );
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ CREATE TABLE $snake agregado en app_database.dart');
  }

  void _injectSqfliteDatabaseService({
    required String root,
    required String snake,
    required String pascal,
    required String packageName,
  }) {
    final filePath = p.join(root, 'lib', 'app', 'core', 'services', 'database_service.dart');
    if (!File(filePath).existsSync()) {
      Console.warning('No se encontró database_service.dart — agrega el DAO manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    // Import del DAO
    final daoImport =
        "import 'package:$packageName/app/core/database/daos/${snake}_dao.dart';";
    if (!content.contains(daoImport)) {
      content = _injectBeforeMarker(
        content, '// cleanarch:dao_import', daoImport,
        fallback: () {
          final anchor =
              "import 'package:$packageName/app/core/database/app_database.dart';";
          return content.replaceFirst(anchor, '$anchor\n$daoImport');
        },
      );
    }

    // Campo y getter del DAO (Sqflite no usa código generado, instancia directa)
    final field  = 'final ${pascal}Dao _${snake}Dao = ${pascal}Dao();';
    final getter = '${pascal}Dao get $snake => _${snake}Dao;';
    if (!content.contains(getter)) {
      final injection = '$field\n  $getter';
      content = _injectBeforeMarker(
        content, '// cleanarch:dao_getter', injection,
        fallback: () => content,
      );
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ ${pascal}Dao agregado a database_service.dart');
  }

  // ── ObjectBox ──────────────────────────────────────────────────────────────

  void _generateObjectBox(
      String dbDir, String snake, String pascal, String packageName) {
    _writer.createDir(p.join(dbDir, 'entities'));

    _writer.write(
      p.join(dbDir, 'entities', '${snake}_entity.dart'),
      objectBoxEntityTemplate(snake, pascal),
    );

    if (_dryRun) return;
    _injectObjectBoxDatabaseService(
      root: _rootFromDbDir(dbDir),
      snake: snake,
      pascal: pascal,
      packageName: packageName,
    );
  }

  void _injectObjectBoxDatabaseService({
    required String root,
    required String snake,
    required String pascal,
    required String packageName,
  }) {
    final filePath = p.join(
        root, 'lib', 'app', 'core', 'services', 'database_service.dart');
    if (!File(filePath).existsSync()) {
      Console.warning(
          'No se encontró database_service.dart — agrega el getter manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();
    final camel = snake.toCamelCase();

    // Import de la entidad
    final entityImport =
        "import 'package:$packageName/app/core/database/entities/${snake}_entity.dart';";
    if (!content.contains(entityImport)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:entity_import', entityImport,
          fallback: () {
        final anchor =
            "import 'package:$packageName/app/core/database/app_database.dart';";
        return content.replaceFirst(anchor, '$anchor\n$entityImport');
      });
    }

    // Getter Box<T>
    final getter =
        'Box<$pascal> get $camel => AppDatabase.instance.box<$pascal>();';
    if (!content.contains(getter)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:collection_getter', getter,
          fallback: () => content);
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ Box<$pascal> getter agregado a database_service.dart');
  }

  // ── Floor ──────────────────────────────────────────────────────────────────

  void _generateFloor(String dbDir, String snake, String pascal, String camel,
      String packageName) {
    _writer.createDir(p.join(dbDir, 'entities'));
    _writer.createDir(p.join(dbDir, 'daos'));

    _writer.write(
      p.join(dbDir, 'entities', '${snake}_entity.dart'),
      floorEntityTemplate(snake, pascal),
    );
    _writer.write(
      p.join(dbDir, 'daos', '${snake}_dao.dart'),
      floorDaoTemplate(snake, pascal, camel, packageName),
    );

    if (_dryRun) return;
    _injectFloorAppDatabase(dbDir, snake, pascal);
    _injectFloorDatabaseService(
      root: _rootFromDbDir(dbDir),
      snake: snake,
      pascal: pascal,
      packageName: packageName,
    );
  }

  void _injectFloorAppDatabase(String dbDir, String snake, String pascal) {
    final filePath = p.join(dbDir, 'app_database.dart');
    if (!File(filePath).existsSync()) {
      Console.warning(
          'No se encontró app_database.dart — agrega la entidad manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    // Import de entidad y DAO
    final entityImport = "import 'entities/${snake}_entity.dart';";
    final daoImport = "import 'daos/${snake}_dao.dart';";

    if (!content.contains(entityImport)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:entity_import', entityImport,
          fallback: () => content.replaceFirst(
                "part 'app_database.g.dart';",
                "$entityImport\npart 'app_database.g.dart';",
              ));
    }
    if (!content.contains(daoImport)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:dao_import', daoImport,
          fallback: () => content.replaceFirst(
                "part 'app_database.g.dart';",
                "$daoImport\npart 'app_database.g.dart';",
              ));
    }

    // Agregar entidad a @Database(entities: [...])
    content = _injectIntoAnnotationList(content, 'entities', pascal);

    // Declarar abstract getter del DAO en AppFloorDatabase
    final floorGetter = '${pascal}Dao get ${snake}Dao;';
    if (!content.contains(floorGetter)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:floor_dao_getter', floorGetter,
          fallback: () => content);
    }

    File(filePath).writeAsStringSync(content);
    Console.success('  ✔ $pascal registrada en app_database.dart');
  }

  void _injectFloorDatabaseService({
    required String root,
    required String snake,
    required String pascal,
    required String packageName,
  }) {
    final filePath = p.join(
        root, 'lib', 'app', 'core', 'services', 'database_service.dart');
    if (!File(filePath).existsSync()) {
      Console.warning(
          'No se encontró database_service.dart — agrega el getter manualmente.');
      return;
    }
    var content = File(filePath).readAsStringSync();

    // Import del DAO
    final daoImport =
        "import 'package:$packageName/app/core/database/daos/${snake}_dao.dart';";
    if (!content.contains(daoImport)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:dao_import', daoImport,
          fallback: () {
        final anchor =
            "import 'package:$packageName/app/core/database/app_database.dart';";
        return content.replaceFirst(anchor, '$anchor\n$daoImport');
      });
    }

    // Getter del DAO (delega al AppFloorDatabase generado)
    final getter = '${pascal}Dao get $snake => AppDatabase.instance.${snake}Dao;';
    if (!content.contains(getter)) {
      content = _injectBeforeMarker(
          content, '// cleanarch:dao_getter', getter,
          fallback: () => content);
    }

    File(filePath).writeAsStringSync(content);
    Console.success(
        '  ✔ ${pascal}Dao getter agregado a database_service.dart');
  }

  // ── Detección de ORM ───────────────────────────────────────────────────────

  String _detectOrm(String root) {
    final pubspec = File(p.join(root, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return 'unknown';
    final content = pubspec.readAsStringSync();
    if (content.contains('drift:')) return 'drift';
    if (content.contains('isar:')) return 'isar';
    if (content.contains('objectbox:')) return 'objectbox';
    if (content.contains('floor:')) return 'floor';
    if (content.contains('sqflite:')) return 'sqflite';
    return 'unknown';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Sube 3 niveles desde database/ para llegar al root del proyecto:
  /// lib/app/core/database → lib/app/core → lib/app → lib → root
  String _rootFromDbDir(String dbDir) =>
      p.normalize(p.join(dbDir, '..', '..', '..', '..'));

  /// Inserta [newLine] justo ANTES de la línea que contiene [marker].
  /// Si el marcador no existe, llama a [fallback].
  String _injectBeforeMarker(
    String content,
    String marker,
    String newLine, {
    String Function()? fallback,
  }) {
    if (!content.contains(marker)) {
      if (fallback != null) return fallback();
      Console.warning(
          '  Marcador "$marker" no encontrado — agrega manualmente: $newLine');
      return content;
    }
    if (content.contains(newLine)) return content; // ya existe

    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.trim() == marker) {
        final indent = ' ' * (line.length - line.trimLeft().length);
        result.add('$indent$newLine');
      }
      result.add(line);
    }
    return result.join('\n');
  }

  /// Asegura que `@DriftDatabase(...)` tenga la cláusula `daos: []`.
  String _ensureDaosClause(String content) {
    if (content.contains('daos:')) return content;
    final annotationIdx = content.indexOf('@DriftDatabase(');
    if (annotationIdx == -1) return content;
    var depth = 0;
    for (var i = annotationIdx + '@DriftDatabase('.length - 1; i < content.length; i++) {
      if (content[i] == '(') {
        depth++;
      } else if (content[i] == ')') {
        depth--;
        if (depth == 0) {
          return '${content.substring(0, i)}, daos: []${content.substring(i)}';
        }
      }
    }
    return content;
  }

  /// Inyecta [newItem] dentro de `key: [...]` en la anotación `@DriftDatabase`.
  /// Busca SOLO la anotación real (línea que empieza con @DriftDatabase, no comentarios).
  String _injectIntoAnnotationList(String content, String key, String newItem) {
    // Buscar la anotación real: @DriftDatabase al inicio de una línea (no en comentario).
    final annotationMatch =
        RegExp(r'^\s*@DriftDatabase\(', multiLine: true).firstMatch(content);
    if (annotationMatch == null) { return content; }
    final annotationStart = annotationMatch.start;

    final startPattern = '$key: [';
    final startIdx = content.indexOf(startPattern, annotationStart);
    if (startIdx == -1) { return content; }

    final bracketOpenIdx = startIdx + startPattern.length - 1;
    var depth = 0;
    var listEnd = -1;
    for (var i = bracketOpenIdx; i < content.length; i++) {
      if (content[i] == '[') {
        depth++;
      } else if (content[i] == ']') {
        depth--;
        if (depth == 0) {
          listEnd = i;
          break;
        }
      }
    }
    if (listEnd == -1) { return content; }

    final listContentStart = bracketOpenIdx + 1;
    final existing = content.substring(listContentStart, listEnd).trim();
    if (existing.contains(newItem)) { return content; }

    final newContent = existing.isEmpty ? newItem : '$existing, $newItem';
    return content.substring(0, listContentStart) +
        newContent +
        content.substring(listEnd);
  }

  /// Devuelve el índice del último `import` del archivo.
  int _lastImportIndex(String content) {
    final matches = RegExp(r"^import '", multiLine: true).allMatches(content);
    if (matches.isEmpty) return -1;
    return matches.last.start;
  }

  void _printNextSteps(String orm, String snake) {
    Console.info('');
    Console.info('Próximos pasos:');
    switch (orm) {
      case 'drift':
        Console.info('  1. Define las columnas en lib/app/core/database/tables/${snake}_table.dart');
        Console.info('  2. Agrega queries en lib/app/core/database/daos/${snake}_dao.dart');
        Console.info('  3. Regenera:  dart run build_runner build --delete-conflicting-outputs');
      case 'isar':
        Console.info('  1. Define los campos en lib/app/core/database/collections/${snake}_collection.dart');
        Console.info('  2. Regenera:  dart run build_runner build --delete-conflicting-outputs');
        Console.info('  3. Usa el getter en tu controller: Get.find<DatabaseService>().$snake');
      case 'sqflite':
        Console.info('  1. Define las columnas en lib/app/core/database/models/${snake}_model.dart');
        Console.info('  2. Actualiza el SQL en AppDatabase._onCreate (app_database.dart)');
        Console.info('  3. Agrega queries en lib/app/core/database/daos/${snake}_dao.dart');
      case 'objectbox':
        Console.info('  1. Define los campos en lib/app/core/database/entities/${snake}_entity.dart');
        Console.info('  2. Regenera:  dart run build_runner build --delete-conflicting-outputs');
        Console.info('  3. Usa el getter en tu controller: Get.find<DatabaseService>().$snake');
      case 'floor':
        Console.info('  1. Define los campos en lib/app/core/database/entities/${snake}_entity.dart');
        Console.info('  2. Agrega queries en lib/app/core/database/daos/${snake}_dao.dart');
        Console.info('  3. Regenera:  dart run build_runner build --delete-conflicting-outputs');
    }
    Console.info('');
  }
}
