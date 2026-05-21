import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/templates/module_templates.dart'
    show storageRuntimePackages, storageDevPackages, storageCompanionPackages;
import 'package:clean_arch_cli/src/templates/project_templates.dart';
import 'package:clean_arch_cli/src/templates/service_templates.dart'
    show
        apiServiceTemplate,
        apiServiceBindingEntry,
        serviceBindingEntries,
        serviceFileName,
        storageServiceTemplate,
        appDatabaseTemplate,
        isKnownStorageLib;
import 'package:clean_arch_cli/src/templates/database_doc_templates.dart'
    show databaseDocTemplate;
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/flutter_packages.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart' show projectUsesFvm;
import 'package:clean_arch_cli/src/utils/string_ext.dart';
import 'package:clean_arch_cli/src/generators/file_writer.dart';
import 'package:clean_arch_cli/src/generators/module_generator.dart';

class ProjectGenerator {
  // overwrite: true porque siempre generamos sobre un directorio nuevo.
  final bool _dryRun;
  late final FileWriter _writer;

  ProjectGenerator({bool dryRun = false}) : _dryRun = dryRun {
    _writer = FileWriter(overwrite: true, dryRun: dryRun);
  }

  Future<void> generate({
    required String projectName,
    required String outputDir,
    required String org,
    List<String> modules = const ['home'],
    List<FlutterPackage> packages = const [],
    List<String> platforms = const ['android', 'ios'],
    String datasource = 'rest',
    String httpLib = 'get_connect',
    String storageLib = 'get_storage',
    bool useJsonAnnotation = false,
  }) async {
    final name = projectName.toSnakeCase();
    final pascal = name.toPascalCase();
    final root = p.join(outputDir, name);

    Console.header('Creando proyecto: $pascal');

    if (!_dryRun && Directory(root).existsSync()) {
      Console.warning('El directorio "$root" ya existe.');
      if (!Console.confirm('¿Deseas continuar de todas formas?')) {
        Console.info('Operación cancelada.');
        return;
      }
    }

    if (!_dryRun) {
      Console.step(1, 'Inicializando proyecto Flutter (flutter create)');
      _runFlutterCreate(outputDir, name, org, platforms);
    }

    Console.step(2, 'Estructura base del proyecto');
    _generateProjectBase(name, pascal, org, root,
        datasource: datasource, storageLib: storageLib);

    Console.step(3, 'Archivos de configuración');
    _generateConfigFiles(name, pascal, org, root, packages,
        storageLib: storageLib, datasource: datasource, httpLib: httpLib);

    Console.step(4, 'Core (theme, constants, network, bindings)');
    _generateCore(root,
        pascal: pascal,
        datasource: datasource, httpLib: httpLib, storageLib: storageLib,
        packageName: name);

    Console.step(5, 'Routes & Translations');
    _generateRoutesAndTranslations(name, root);

    Console.step(6, 'Módulos iniciales');
    final modGen = ModuleGenerator(dryRun: _dryRun);
    for (final mod in modules) {
      // El módulo 'home' (dashboard principal) no tiene datos propios por defecto.
      // Preguntamos al usuario — la respuesta por defecto es NO (solo presentación).
      final isHome = mod == 'home';
      bool modPresentationOnly = false;
      if (isHome && !_dryRun) {
        Console.info('');
        stdout.write(
          '  ¿El módulo "home" tendrá su propia capa de datos '
          '(provider + repositorio + casos de uso)? [s/N]: ',
        );
        final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
        modPresentationOnly = answer != 's' && answer != 'si' && answer != 'sí';
        Console.info('');
      } else if (isHome) {
        modPresentationOnly = true; // dry-run: siempre presentationOnly para home
      }

      await modGen.generate(mod, root,
          datasource: datasource, httpLib: httpLib, storageLib: storageLib,
          packageName: name,
          useJsonAnnotation: useJsonAnnotation,
          presentationOnly: modPresentationOnly);
    }

    Console.step(7, 'Estructura de assets');
    _generateAssets(root);

    if (datasource == 'local' || datasource == 'both') {
      Console.step(8, 'Documentación de base de datos (docs/DATABASE.md)');
      _generateDocs(root, storageLib, name);
    }

    if (!_dryRun) {
      Console.step(9, 'Instalando dependencias (flutter pub get)');
      _runFlutterPubGet(root);
      _runCompanionPubAdds(root, storageLib: storageLib, datasource: datasource);
    }

    Console.success('');
    Console.success('¡Proyecto "$pascal" creado exitosamente en $root');
    if (!_dryRun) { _printFinalInstructions(name, root, platforms); }
  }

  // ── flutter create ───────────────────────────────────────────────────────

  void _runFlutterCreate(
      String outputDir, String name, String org, List<String> platforms) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    final useFvm = projectUsesFvm(outputDir);
    final exe = useFvm ? 'fvm' : 'flutter';
    final args = useFvm
        ? ['flutter', 'create', '--org', org, '--platforms', platforms.join(','), name]
        : ['create', '--org', org, '--platforms', platforms.join(','), name];
    final display = useFvm
        ? 'fvm flutter create --org $org --platforms ${platforms.join(',')} $name'
        : 'flutter create --org $org --platforms ${platforms.join(',')} $name';

    print('$yellow  \$ $display$reset');

    final result = Process.runSync(
      exe, args,
      workingDirectory: outputDir,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      Console.error('Error al ejecutar flutter create:');
      Console.error(result.stderr.toString());
      exit(1);
    }

    Console.success('  flutter create completado → carpetas de plataforma creadas');
  }

  void _runFlutterPubGet(String root) {
    final result = Process.runSync(
      'flutter',
      ['pub', 'get'],
      workingDirectory: root,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      Console.success('  flutter pub get completado');
    } else {
      Console.warning('  flutter pub get falló — ejecuta manualmente en $root');
    }
  }

  void _runCompanionPubAdds(String root, {
    required String storageLib,
    required String datasource,
  }) {
    if (datasource != 'local' && datasource != 'both') { return; }
    final companions = storageCompanionPackages(storageLib);
    if (companions.isEmpty) { return; }

    Console.info('  Agregando companions: ${companions.join(', ')}');
    final result = Process.runSync(
      'flutter',
      ['pub', 'add', ...companions],
      workingDirectory: root,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      Console.success('  ✔ ${companions.join(', ')} agregados a dependencies');
    } else {
      Console.warning(
        '  Ejecuta manualmente: flutter pub add ${companions.join(' ')}',
      );
    }
  }

  // ── Generación de archivos ───────────────────────────────────────────────

  void _generateProjectBase(
      String name, String pascal, String org, String root, {
      String datasource = 'rest',
      String storageLib = '',
  }) {
    _writer.write(
      p.join(root, 'lib', 'main.dart'),
      mainDartTemplate(name, pascal, datasource: datasource, storageLib: storageLib),
    );
    _writer.write(
      p.join(root, 'lib', 'app', 'app.dart'),
      appTemplate(name, pascal),
    );
  }

  void _generateConfigFiles(
      String name, String pascal, String org, String root,
      List<FlutterPackage> packages, {
      String storageLib = '',
      String datasource = 'rest',
      String httpLib = 'get_connect',
  }) {
    final extraDeps = <String, String>{};
    final extraDevDeps = <String, String>{};
    for (final pkg in packages) {
      extraDeps[pkg.name] = pkg.version;
      extraDeps.addAll(pkg.companions);
      extraDevDeps.addAll(pkg.devDependencies);
    }
    // Agregar dio cuando se eligió como cliente HTTP
    if (httpLib.toLowerCase().trim() == 'dio') {
      extraDeps['dio'] = '^5.7.0';
    }
    // Agregar paquetes del storage lib elegido (ej. drift + drift_sqflite + drift_dev)
    if (datasource == 'local' || datasource == 'both') {
      if (storageLib.isNotEmpty) {
        extraDeps.addAll(storageRuntimePackages(storageLib));
        extraDevDeps.addAll(storageDevPackages(storageLib));
      }
    }

    _writer.write(
      p.join(root, 'pubspec.yaml'),
      pubspecTemplate(name, org, extraDeps: extraDeps, extraDevDeps: extraDevDeps),
    );
    _writer.write(
      p.join(root, '.gitignore'),
      gitignoreTemplate(),
    );
    _writer.write(
      p.join(root, 'analysis_options.yaml'),
      analysisOptionsTemplate(),
    );
    _writer.write(
      p.join(root, 'README.md'),
      readmeTemplate(pascal, name),
    );
  }

  void _generateCore(String root, {
    required String pascal,
    String datasource = 'rest',
    String httpLib = 'get_connect',
    String storageLib = '',
    required String packageName,
  }) {
    final core = p.join(root, 'lib', 'app', 'core');

    _writer.write(p.join(core, 'theme', 'app_theme.dart'), appThemeTemplate());
    _writer.write(
        p.join(core, 'constants', 'app_colors.dart'), appColorsTemplate());
    _writer.write(p.join(core, 'constants', 'app_text_styles.dart'),
        appTextStylesTemplate());
    _writer.write(
        p.join(core, 'constants', 'app_constants.dart'), appConstantsTemplate(pascal));

    _writer.write(
        p.join(core, 'network', 'api_client.dart'), apiClientTemplate(httpLib));

    // Generar servicios globales según datasource
    final services = <({String import, String registration, String comment})>[];

    if (datasource == 'rest' || datasource == 'both') {
      services.add(apiServiceBindingEntry(httpLib, packageName: packageName));
      _writer.write(
        p.join(core, 'services', 'api_service.dart'),
        apiServiceTemplate(httpLib, packageName: packageName),
      );
    }

    if (datasource == 'local' || datasource == 'both') {
      services.addAll(serviceBindingEntries(storageLib, packageName: packageName));
      _generateServices(core, storageLib, packageName: packageName);
      _generateAppDatabase(core, storageLib);
    }

    _writer.write(
      p.join(core, 'bindings', 'initial_binding.dart'),
      initialBindingTemplate(services: services, packageName: packageName),
    );

    _writer.createDir(p.join(core, 'utils'));
    _writer.write(p.join(core, 'utils', '.gitkeep'), '');

    _writer.createDir(p.join(core, 'errors'));
    _writer.write(
      p.join(core, 'errors', 'failures.dart'),
      _failuresTemplate(),
    );
  }

  void _generateAppDatabase(String core, String storageLib) {
    if (storageLib.isEmpty) { return; }
    _writer.write(
      p.join(core, 'database', 'app_database.dart'),
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
      // Sin purpose='database' explícito → primera lib como fallback
      return storageLib.split(',').first.split(':').first.trim();
    }
    return storageLib.split(':').first.trim();
  }

  void _generateServices(String core, String storageLib, {required String packageName}) {
    if (storageLib.isEmpty) { return; }

    if (!isKnownStorageLib(storageLib)) {
      final lib = storageLib.split(',').first.split(':').first.trim();
      Console.warning(
        '  Librería "$lib" no reconocida — se generó un template genérico con TODOs.\n'
        '  Implementa DatabaseService y AppDatabase para tu librería.',
      );
    }

    void writeService(String lib, String purpose) {
      final fileName = serviceFileName(purpose);
      _writer.write(
        p.join(core, 'services', fileName),
        storageServiceTemplate(lib, purpose: purpose, packageName: packageName),
      );
    }

    if (storageLib.contains(',') && storageLib.contains(':')) {
      for (final part in storageLib.split(',')) {
        final chunks = part.split(':');
        if (chunks.length == 2) {
          writeService(chunks[0].trim(), chunks[1].trim());
        }
      }
    } else {
      final lib = storageLib.split(':').first.trim();
      writeService(lib, 'database');
    }
  }

  void _generateRoutesAndTranslations(String name, String root) {
    final routes = p.join(root, 'lib', 'app', 'routes');
    _writer.write(p.join(routes, 'app_pages.dart'), appPagesTemplate(name));  // name IS packageName
    _writer.write(p.join(routes, 'app_routes.dart'), appRoutesTemplate());

    _writer.write(
      p.join(root, 'lib', 'app', 'translations', 'app_translations.dart'),
      appTranslationsTemplate(),
    );
  }

  void _generateAssets(String root) {
    for (final dir in [
      'assets/images',
      'assets/icons',
      'assets/fonts',
    ]) {
      _writer.createDir(p.join(root, dir));
      _writer.write(p.join(root, dir, '.gitkeep'), '');
    }
  }

  String _failuresTemplate() => '''
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error de servidor']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de caché']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado']);
}
''';

  // ── Documentación ───────────────────────────────────────────────────────

  void _generateDocs(String root, String storageLib, String appName) {
    if (storageLib.isEmpty) { return; }
    final docsDir = p.join(root, 'docs');
    _writer.createDir(docsDir);
    _writer.write(
      p.join(docsDir, 'DATABASE.md'),
      databaseDocTemplate(storageLib, appName),
    );
  }

  void _printFinalInstructions(
      String name, String root, List<String> platforms) {
    Console.info('');
    Console.info('Plataformas: ${platforms.join(', ')}');
    Console.info('');
    Console.info('Para comenzar:');
    Console.info('  cd $root');
    Console.info('  flutter pub get');
    Console.info('  flutter run');
    Console.info('');
    Console.info('Agregar más módulos después:');
    Console.info('  cleanarch create module <nombre>');
    Console.info('');
  }
}
