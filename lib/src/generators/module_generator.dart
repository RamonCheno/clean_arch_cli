import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/bundles/module_bundle.dart';
import 'package:clean_arch_cli/src/generators/file_writer.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/generators/route_injector.dart';
import 'package:clean_arch_cli/src/generators/storage_injector.dart';

import 'package:clean_arch_cli/src/templates/module_templates.dart'
    show
        providerTemplate,
        modelTemplate,
        repositoryImplTemplate,
        containerViewTemplate,
        controllerPresentationOnlyTemplate,
        bindingPresentationOnlyTemplate,
        viewTemplate,
        isStorageLibInjected,
        storageRuntimePackages,
        storageDevPackages,
        storageCompanionPackages;
import 'package:clean_arch_cli/src/templates/service_templates.dart'
    show
        apiServiceTemplate,
        serviceFileName,
        storageServiceTemplate,
        appDatabaseTemplate,
        isKnownStorageLib;
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart'
    show readPackageName;
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class ModuleGenerator {
  final FileWriter _writer;
  final bool _dryRun;
  final bool _overwrite;

  ModuleGenerator({bool overwrite = false, bool dryRun = false})
      : _writer = FileWriter(overwrite: overwrite, dryRun: dryRun),
        _dryRun = dryRun,
        _overwrite = overwrite;

  /// datasource:        'rest' | 'local' | 'both'
  /// httpLib:           'get_connect' | 'dio'
  /// storageLib:        'get_storage' | 'hive' | 'shared_prefs' | 'secure_storage'
  /// useJsonAnnotation: si es null se auto-detecta leyendo pubspec.yaml del proyecto
  /// presentationOnly:  true → solo genera Controller + Binding + View (sin datos)
  Future<void> generate(
    String moduleName,
    String projectRoot, {
    String datasource = 'rest',
    String httpLib = 'get_connect',
    String storageLib = 'get_storage',
    String? packageName,
    bool? useJsonAnnotation,
    bool presentationOnly = false,
  }) async {
    final pkgName = packageName ?? readPackageName(projectRoot);
    final name = moduleName.toSnakeCase();
    final pascal = name.toPascalCase();
    // Auto-detecta json_annotation en pubspec.yaml si no se especificó explícitamente
    final jsonAnnotation = useJsonAnnotation ?? _detectJsonAnnotation(projectRoot);

    Console.header('Generando módulo: $pascal');

    // ── Módulo solo de presentación: Controller + Binding + View ─────────
    if (presentationOnly) {
      return _generatePresentationOnly(name, pascal, pkgName, projectRoot);
    }

    // ── Step 1: Domain + Data + Presentation via Mason brick ─────────────
    Console.step(1, 'Capa Domain + Data + Presentation');
    // Los hooks de Mason no se ejecutan en la API programática,
    // por lo que computamos las vars del hook manualmente aquí.
    final plural = name.toPlural();
    final pluralPascal = plural.toPascalCase();
    final syncLibs = ['get_storage', 'hive', 'hive_flutter'];
    final normLib = storageLib.split(':').first.trim().toLowerCase();
    final isLocalSync = datasource == 'local' && syncLibs.contains(normLib);

    // Captura si el model ya existía ANTES de que Mason corra.
    // Esto distingue: módulo nuevo (Mason crea el archivo) vs módulo existente
    // (el archivo ya estaba). El ormWriter solo sobreescribe en módulos nuevos
    // o cuando el usuario aprobó explícitamente con --overwrite.
    final modelPath = p.join(
        projectRoot, 'lib', 'app', 'data', 'models', '${name}_model.dart');
    final modelExistedBefore = File(modelPath).existsSync();

    final generator = await MasonGenerator.fromBundle(moduleBundle);
    await generator.generate(
      MasonTarget(projectRoot, dryRun: _dryRun, overwrite: _overwrite),
      vars: {
        'name': name,
        'package_name': pkgName,
        'datasource': datasource,
        'storage_lib': storageLib,
        'plural': plural,
        'plural_pascal': pluralPascal,
        'is_rest': datasource == 'rest',
        'is_local': datasource == 'local',
        'is_both': datasource == 'both',
        'is_local_sync': isLocalSync,
      },
    );

    // ── Step 2: Provider + Model + RepositoryImpl (templates Dart) ──────
    Console.step(2, 'Provider');
    _writer.write(
      p.join(projectRoot, 'lib', 'app', 'data', 'providers',
          '${name}_provider.dart'),
      providerTemplate(name, pascal, plural,
          datasource: datasource,
          httpLib: httpLib,
          storageLib: storageLib,
          packageName: pkgName),
    );

    // Sobreescribimos el model (y repositoryImpl para ORM) que generó Mason:
    //   • ORM:             model con fromDrift/fromOrm + repo sin Map intermediario
    //   • json_annotation: model con @JsonSerializable + part directive
    //   • Ambos:           model con fromDrift/fromOrm + @JsonSerializable
    final needsModelOverwrite = jsonAnnotation ||
        ((datasource == 'local' || datasource == 'both') &&
            isStorageLibInjected(normLib));
    final isOrm = (datasource == 'local' || datasource == 'both') &&
        isStorageLibInjected(normLib);

    // Detecta si el módulo tiene su propia tabla en el proyecto.
    // Si no existe (ej. módulo dashboard que consume varias tablas),
    // el fromDrift/fromOrm se genera comentado para que el código compile.
    final tableExists = _tableExists(name, normLib, projectRoot);

    if (needsModelOverwrite) {
      if (_dryRun) {
        final tableNote = isOrm && !tableExists
            ? ' — fromDrift comentado (sin tabla propia)'
            : '';
        final modelLabel = jsonAnnotation && isOrm
            ? 'ORM + @JsonSerializable'
            : isOrm
                ? 'ORM (fromDrift / fromOrm)'
                : '@JsonSerializable';
        Console.info('  ↳ ${name}_model.dart → versión $modelLabel$tableNote (sobreescribe Mason)');
        if (isOrm) {
          Console.info('  ↳ ${name}_repository_impl.dart → versión ORM sin fromJson (sobreescribe Mason)');
        }
      } else {
        // Si el model no existía antes → Mason lo acaba de crear → ormWriter
        // DEBE sobreescribir (reemplaza la versión básica de Mason con la ORM).
        // Si el model ya existía → módulo existente → solo sobreescribir si
        // el usuario lo aprobó con --overwrite (o confirmó la pregunta).
        final ormWriter = FileWriter(
          overwrite: !modelExistedBefore || _overwrite,
          dryRun: false,
        );
        ormWriter.write(
          p.join(projectRoot, 'lib', 'app', 'data', 'models', '${name}_model.dart'),
          modelTemplate(name, pascal, pkgName,
              storageLib: storageLib,
              useJsonAnnotation: jsonAnnotation,
              tableExists: tableExists),
        );
        if (isOrm) {
          ormWriter.write(
            p.join(projectRoot, 'lib', 'app', 'data', 'repositories',
                '${name}_repository_impl.dart'),
            repositoryImplTemplate(name, pascal, plural, pluralPascal,
                datasource: datasource,
                storageLib: storageLib,
                packageName: pkgName),
          );
        }
      }
    }

    // ── Step 3: Shared services (api_service / storage services) ─────────
    if (datasource == 'rest' || datasource == 'both') {
      _ensureApiService(projectRoot, httpLib, pkgName);
    }
    if (datasource == 'local' || datasource == 'both') {
      _ensureServices(projectRoot, storageLib, pkgName);
    }

    // ── Step 4: Widgets placeholder ───────────────────────────────────────
    if (!_dryRun) {
      _writer.createDir(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets'));
      _writer.write(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets',
              '.gitkeep'),
          '');
    }

    // ── Route injection ───────────────────────────────────────────────────
    final injected = RouteInjector.injectModule(projectRoot, name, pascal,
        packageName: pkgName, dryRun: _dryRun);

    Console.success('Módulo "$pascal" creado en $projectRoot');

    if (injected) {
      Console.info('  ✔ Ruta inyectada en app_pages.dart y app_routes.dart');
    } else {
      _printManualSteps(name, pascal);
    }
  }

  /// Devuelve true si ya existe un archivo de tabla para este módulo.
  /// Cada ORM guarda sus tablas en carpetas distintas:
  ///   drift/sqflite/floor → database/tables/${name}_table.dart
  ///   isar/objectbox      → database/collections/${name}_collection.dart
  bool _tableExists(String name, String normLib, String projectRoot) {
    final dbDir = p.join(projectRoot, 'lib', 'app', 'core', 'database');
    switch (normLib) {
      case 'isar':
      case 'objectbox':
        return File(p.join(dbDir, 'collections', '${name}_collection.dart'))
            .existsSync();
      default: // drift, sqflite, floor
        return File(p.join(dbDir, 'tables', '${name}_table.dart')).existsSync();
    }
  }

  void _ensureApiService(String root, String httpLib, String packageName) {
    FileWriter(overwrite: false, dryRun: _dryRun).write(
      p.join(root, 'lib', 'app', 'core', 'services', 'api_service.dart'),
      apiServiceTemplate(httpLib, packageName: packageName),
    );
    final injected =
        StorageInjector.injectApiService(root, httpLib, packageName: packageName);
    if (injected) {
      Console.info('  ✔ ApiService registrado en initial_binding.dart');
    }
  }

  void _ensureServices(String root, String storageLib, String packageName) {
    final serviceWriter = FileWriter(overwrite: false, dryRun: _dryRun);
    final servicesDir = p.join(root, 'lib', 'app', 'core', 'services');

    if (!isKnownStorageLib(storageLib)) {
      final lib = storageLib.split(',').first.split(':').first.trim();
      Console.warning(
        '  Librería "$lib" no reconocida — se generó un template genérico con TODOs.\n'
        '  Implementa DatabaseService y AppDatabase para tu librería.',
      );
    }

    void writeService(String lib, String purpose) {
      serviceWriter.write(
        p.join(servicesDir, serviceFileName(purpose)),
        storageServiceTemplate(lib, purpose: purpose, packageName: packageName),
      );
    }

    if (storageLib.contains(',') && storageLib.contains(':')) {
      for (final part in storageLib.split(',')) {
        final chunks = part.split(':');
        if (chunks.length == 2) { writeService(chunks[0].trim(), chunks[1].trim()); }
      }
    } else {
      writeService(storageLib.split(':').first.trim(), 'database');
    }

    _ensureAppDatabase(root, storageLib);
    _ensurePackages(root, storageLib);

    final injected = StorageInjector.injectStorageService(
      root,
      storageLib,
      packageName: packageName,
    );
    if (injected) {
      Console.info('  ✔ Servicio de storage registrado en initial_binding.dart');
    }
  }

  /// Crea lib/app/core/database/app_database.dart si no existe aún.
  void _ensureAppDatabase(String root, String storageLib) {
    if (storageLib.isEmpty) { return; }
    final dbFile = p.join(
        root, 'lib', 'app', 'core', 'database', 'app_database.dart');
    if (File(dbFile).existsSync()) { return; } // ya fue creado (ej. create project)
    FileWriter(overwrite: false, dryRun: _dryRun).write(
      dbFile,
      appDatabaseTemplate(_extractDatabaseLib(storageLib)),
    );
  }

  /// Para dual storage ("lib1:purpose1,lib2:purpose2") devuelve la lib con
  /// purpose='database'. Para simple devuelve la lib directamente.
  static String _extractDatabaseLib(String storageLib) {
    if (storageLib.contains(',') && storageLib.contains(':')) {
      for (final part in storageLib.split(',')) {
        final chunks = part.split(':');
        if (chunks.length == 2 && chunks[1].trim() == 'database') {
          return chunks[0].trim();
        }
      }
      return storageLib.split(',').first.split(':').first.trim();
    }
    return storageLib.split(':').first.trim();
  }

  /// Verifica que los paquetes del storage lib estén en pubspec.yaml.
  /// Si faltan, los instala con `flutter pub add`.
  void _ensurePackages(String projectRoot, String storageLib) {
    if (_dryRun) { return; }

    final runtime = storageRuntimePackages(storageLib);
    final dev = storageDevPackages(storageLib);
    if (runtime.isEmpty && dev.isEmpty) { return; }

    final pubspecFile = File(p.join(projectRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) { return; }
    final content = pubspecFile.readAsStringSync();

    final missingRuntime =
        runtime.keys.where((pkg) => !content.contains('$pkg:')).toList();
    final missingDev =
        dev.keys.where((pkg) => !content.contains('$pkg:')).toList();

    if (missingRuntime.isNotEmpty) {
      Console.info('  Agregando dependencias: ${missingRuntime.join(', ')}');
      final result = Process.runSync(
          'flutter', ['pub', 'add', ...missingRuntime],
          workingDirectory: projectRoot, runInShell: true);
      if (result.exitCode == 0) {
        Console.success(
            '  ✔ ${missingRuntime.join(', ')} agregados a dependencies');
      } else {
        Console.warning(
          '  No se pudo ejecutar el comando.\n'
          '  Ejecuta manualmente: flutter pub add ${missingRuntime.join(' ')}',
        );
      }
    }

    if (missingDev.isNotEmpty) {
      Console.info('  Agregando dev dependencies: ${missingDev.join(', ')}');
      final result = Process.runSync(
          'flutter', ['pub', 'add', '--dev', ...missingDev],
          workingDirectory: projectRoot, runInShell: true);
      if (result.exitCode == 0) {
        Console.success(
            '  ✔ ${missingDev.join(', ')} agregados a dev_dependencies');
      } else {
        Console.warning(
          '  Ejecuta manualmente: flutter pub add --dev ${missingDev.join(' ')}',
        );
      }
    }

    final companions = storageCompanionPackages(storageLib);
    final missingCompanions =
        companions.where((pkg) => !content.contains('$pkg:')).toList();
    if (missingCompanions.isNotEmpty) {
      Console.info('  Agregando companions: ${missingCompanions.join(', ')}');
      final result = Process.runSync(
          'flutter', ['pub', 'add', ...missingCompanions],
          workingDirectory: projectRoot, runInShell: true);
      if (result.exitCode == 0) {
        Console.success(
            '  ✔ ${missingCompanions.join(', ')} agregados a dependencies');
      } else {
        Console.warning(
          '  Ejecuta manualmente: flutter pub add ${missingCompanions.join(' ')}',
        );
      }
    }
  }

  /// Devuelve true si el proyecto ya tiene json_annotation en su pubspec.yaml.
  /// Se usa para auto-detectar si los modelos deben usar @JsonSerializable.
  bool _detectJsonAnnotation(String projectRoot) {
    final pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
    if (!pubspec.existsSync()) { return false; }
    return pubspec.readAsStringSync().contains('json_annotation:');
  }

  /// Devuelve los archivos del módulo que ya existen en el proyecto.
  /// Se usa antes de generar para avisar al usuario qué se sobreescribiría.
  ///
  /// [presentationOnly] = true → solo revisa los 3 archivos de presentación.
  /// [container]        = true → solo revisa la view shell.
  static List<String> existingModuleFiles(
      String moduleName, String projectRoot,
      {bool presentationOnly = false, bool container = false}) {
    final name   = moduleName.toSnakeCase();
    final plural = name.toPlural();

    // Módulo contenedor: solo la view shell
    if (container) {
      final viewPath = p.join(projectRoot, 'lib', 'app', 'modules', name,
          'views', '${name}_view.dart');
      return [if (File(viewPath).existsSync()) viewPath];
    }

    final presentationFiles = [
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'bindings',    '${name}_binding.dart'),
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'controllers', '${name}_controller.dart'),
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'views',       '${name}_view.dart'),
    ];

    if (presentationOnly) {
      return presentationFiles.where((f) => File(f).existsSync()).toList();
    }

    final candidates = [
      p.join(projectRoot, 'lib', 'app', 'data', 'models',         '${name}_model.dart'),
      p.join(projectRoot, 'lib', 'app', 'data', 'repositories',   '${name}_repository_impl.dart'),
      p.join(projectRoot, 'lib', 'app', 'data', 'providers',      '${name}_provider.dart'),
      p.join(projectRoot, 'lib', 'app', 'domain', 'entities',     '${name}_entity.dart'),
      p.join(projectRoot, 'lib', 'app', 'domain', 'repositories', '${name}_repository.dart'),
      p.join(projectRoot, 'lib', 'app', 'domain', 'usecases',     'get_all_${plural}_usecase.dart'),
      p.join(projectRoot, 'lib', 'app', 'domain', 'usecases',     'get_${name}_by_id_usecase.dart'),
      ...presentationFiles,
    ];
    return candidates.where((f) => File(f).existsSync()).toList();
  }

  /// Prioridad de detección:
  ///   Storage: ORMs primero (drift > isar > objectbox > floor > sqflite),
  ///            luego key-value (hive > get_storage > shared_preferences > flutter_secure_storage).
  ///   HTTP:    dio > http > get_connect (get_connect es el default de GetX, siempre disponible).
  ///   Datasource: HTTP explícito + storage → 'both'; solo storage → 'local'; resto → 'rest'.
  static ({String datasource, String httpLib, String storageLib}) detectProjectConfig(
      String projectRoot) {
    final pubspecFile = File(p.join(projectRoot, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return (datasource: 'rest', httpLib: 'get_connect', storageLib: '');
    }
    final content = pubspecFile.readAsStringSync();

    // ── Storage lib ───────────────────────────────────────────────────────────
    const ormLibs = ['drift', 'isar', 'objectbox', 'floor', 'sqflite'];
    const kvLibs  = ['hive', 'get_storage', 'shared_preferences', 'flutter_secure_storage'];
    String storageLib = '';
    for (final lib in [...ormLibs, ...kvLibs]) {
      // Busca "lib:" como dependencia (evita falsos positivos como "drift_sqflite:")
      if (RegExp('^\\s*$lib\\s*:', multiLine: true).hasMatch(content)) {
        storageLib = lib;
        break;
      }
    }

    // ── HTTP lib ──────────────────────────────────────────────────────────────
    String httpLib = 'get_connect';
    if (RegExp(r'^\s*dio\s*:', multiLine: true).hasMatch(content)) {
      httpLib = 'dio';
    } else if (RegExp(r'^\s*http\s*:', multiLine: true).hasMatch(content)) {
      httpLib = 'http';
    }

    // ── Datasource ────────────────────────────────────────────────────────────
    final hasExplicitHttp = httpLib != 'get_connect';
    final hasStorage = storageLib.isNotEmpty;
    final datasource = (hasExplicitHttp && hasStorage)
        ? 'both'
        : hasStorage
            ? 'local'
            : 'rest';

    return (datasource: datasource, httpLib: httpLib, storageLib: storageLib);
  }

  /// Genera un módulo contenedor: solo el directorio + view shell mínima + marker de ruta.
  /// No genera domain, data, controller ni binding.
  ///
  /// Usado para agrupar sub-screens bajo un mismo namespace, por ejemplo:
  ///   modules/tasks/  → contenedor
  ///     screens/list_task/
  ///     screens/add_task/
  ///     screens/update_task/
  Future<void> generateContainer(
      String moduleName, String projectRoot, {String? packageName}) async {
    final pkgName = packageName ?? readPackageName(projectRoot);
    final name = moduleName.toSnakeCase();
    final pascal = name.toPascalCase();

    Console.header('Creando módulo contenedor: $pascal');

    Console.step(1, 'View shell');
    _writer.write(
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'views',
          '${name}_view.dart'),
      containerViewTemplate(name, pascal),
    );

    // Carpeta widgets como placeholder
    if (!_dryRun) {
      _writer.createDir(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets'));
      _writer.write(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets',
              '.gitkeep'),
          '');
    }

    Console.step(2, 'Ruta contenedor');
    final injected = RouteInjector.injectModule(
      projectRoot, name, pascal,
      packageName: pkgName,
      dryRun: _dryRun,
      container: true,
    );

    Console.success('Módulo contenedor "$pascal" creado en $projectRoot');
    Console.info('  ℹ Sub-screens:  cleanarch create screen <nombre> --module $name');

    if (!injected) {
      _printManualSteps(name, pascal);
    }
  }

  /// Genera solo Controller + Binding + View (sin Provider / Repository / UseCases).
  /// Usado para módulos tipo dashboard que agregan datos de otros módulos.
  Future<void> _generatePresentationOnly(
      String name, String pascal, String pkgName, String projectRoot) async {
    Console.step(1, 'Controller');
    _writer.write(
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'controllers',
          '${name}_controller.dart'),
      controllerPresentationOnlyTemplate(name, pascal, pkgName),
    );

    Console.step(2, 'Binding');
    _writer.write(
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'bindings',
          '${name}_binding.dart'),
      bindingPresentationOnlyTemplate(name, pascal, pkgName),
    );

    Console.step(3, 'View');
    _writer.write(
      p.join(projectRoot, 'lib', 'app', 'modules', name, 'views',
          '${name}_view.dart'),
      viewTemplate(name, pascal, pkgName),
    );

    // Widgets placeholder
    if (!_dryRun) {
      _writer.createDir(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets'));
      _writer.write(
          p.join(projectRoot, 'lib', 'app', 'modules', name, 'widgets',
              '.gitkeep'),
          '');
    }

    final injected = RouteInjector.injectModule(projectRoot, name, pascal,
        packageName: pkgName, dryRun: _dryRun);

    Console.success('Módulo "$pascal" (solo presentación) creado en $projectRoot');

    if (injected) {
      Console.info('  ✔ Ruta inyectada en app_pages.dart y app_routes.dart');
    } else {
      _printManualSteps(name, pascal);
    }
  }

  void _printManualSteps(String name, String pascal) {
    Console.info('');
    Console.info('Agrega manualmente la ruta en app_pages.dart:');
    Console.info('');
    Console.info(
        '  GetPage(name: Routes.$name, page: () => const ${pascal}View(), binding: ${pascal}Binding(), children: []),');
    Console.info('');
    Console.info('Y la constante en app_routes.dart:');
    Console.info("  static const $name = '/$name';");
    Console.info('');
  }
}
