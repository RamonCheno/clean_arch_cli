import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/module_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';
import 'package:clean_arch_cli/src/commands/storage_lib_menu.dart';

class CreateModuleCommand extends Command<void> {
  @override
  final name = 'module';

  @override
  final description =
      'Agrega un módulo completo (domain + data + presentation) con Clean Architecture + GetX.';

  @override
  String get invocation =>
      '${runner!.executableName} create module <nombre> [--path <ruta>]';

  CreateModuleCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter (donde está pubspec.yaml)',
        defaultsTo: '.',
      )
      ..addFlag(
        'overwrite',
        abbr: 'f',
        help: 'Sobreescribir archivos existentes',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Muestra los archivos que se generarían sin crearlos',
        negatable: false,
      )
      ..addOption(
        'datasource',
        abbr: 's',
        help: 'Tipo de fuente de datos del módulo (rest | local | both)',
        allowed: ['rest', 'local', 'both'],
        defaultsTo: 'rest',
      )
      ..addOption(
        'http-lib',
        help: 'Librería HTTP (ej: dio, get_connect, http)',
        defaultsTo: 'dio',
      )
      ..addOption(
        'storage-lib',
        help: 'Librería local (ej: get_storage, hive, sqflite, isar, drift)',
        defaultsTo: 'get_storage',
      )
      ..addFlag(
        'container',
        abbr: 'c',
        help: 'Módulo contenedor: solo directorio + marker de rutas (sin domain/data)',
        negatable: false,
      )
      ..addFlag(
        'presentation-only',
        abbr: 'P',
        help: 'Solo Controller + Binding + View (sin domain/data)',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    String? moduleName;
    String projectRoot = argResults!['path'] as String;
    final overwrite = argResults!['overwrite'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final containerFlag = argResults!['container'] as bool;
    final presentationOnlyFlag = argResults!['presentation-only'] as bool;
    String datasource = argResults!['datasource'] as String;
    String httpLib = argResults!['http-lib'] as String;
    String storageLib = argResults!['storage-lib'] as String;

    if (argResults!.rest.isNotEmpty) {
      moduleName = argResults!.rest.first;
    }

    if (moduleName == null || moduleName.isEmpty) {
      moduleName = Console.prompt('Nombre del módulo');
      if (moduleName == null || moduleName.isEmpty) {
        Console.error('El nombre del módulo no puede estar vacío.');
        exit(1);
      }
    }

    if (!moduleName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$moduleName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta del proyecto.');
      exit(1);
    }

    // ── Módulo contenedor: ruta directa, sin preguntas de datasource ─────────
    if (containerFlag) {
      final existingContainer = ModuleGenerator.existingModuleFiles(
          moduleName, projectRoot, container: true);
      bool effectiveOverwriteContainer = overwrite;
      if (existingContainer.isNotEmpty && !overwrite && !dryRun) {
        Console.warning('El módulo contenedor "$moduleName" ya existe.');
        if (!Console.confirm('¿Deseas sobreescribir la view shell?')) {
          Console.info('Operación cancelada.');
          return;
        }
        effectiveOverwriteContainer = true;
      }
      await ModuleGenerator(overwrite: effectiveOverwriteContainer, dryRun: dryRun)
          .generateContainer(moduleName, projectRoot);
      return;
    }

    // ── Módulo normal / presentation-only: detectar datasource ───────────────
    bool presentationOnly = presentationOnlyFlag;

    if (presentationOnly) {
      // --presentation-only pasado por flag: saltar menú interactivo directamente.
    } else if (!argResults!.wasParsed('datasource') &&
        !argResults!.wasParsed('storage-lib') &&
        !argResults!.wasParsed('http-lib')) {
      final result = _askDatasource();
      presentationOnly = result.$4;
      final isContainer = result.$5;
      if (isContainer) {
        // Opción 6 del menú — delegar a generateContainer
        await ModuleGenerator(overwrite: overwrite, dryRun: dryRun)
            .generateContainer(moduleName, projectRoot);
        return;
      }
      if (!presentationOnly) {
        datasource = result.$1;
        httpLib    = result.$2;
        storageLib = result.$3;
      }
    }

    // Detecta qué archivos del módulo ya existen antes de generar.
    // Si alguno existe y no se pasó --overwrite, lista los archivos y pregunta.
    final existingFiles = ModuleGenerator.existingModuleFiles(
        moduleName, projectRoot, presentationOnly: presentationOnly);

    bool effectiveOverwrite = overwrite;
    if (existingFiles.isNotEmpty && !overwrite && !dryRun) {
      Console.warning('Los siguientes archivos del módulo "$moduleName" ya existen:');
      for (final f in existingFiles) {
        Console.info('  • ${p.relative(f, from: projectRoot)}');
      }
      Console.info('');
      if (!Console.confirm('¿Deseas sobreescribir estos archivos?')) {
        Console.info('  Continuando sin sobreescribir — se saltarán los archivos existentes.');
        Console.info('');
        // effectiveOverwrite permanece false → FileWriter saltará los existentes
      } else {
        effectiveOverwrite = true;
      }
    }

    if (dryRun) {
      await ModuleGenerator(overwrite: effectiveOverwrite, dryRun: true).generate(
        moduleName, projectRoot,
        datasource: datasource, httpLib: httpLib, storageLib: storageLib,
        presentationOnly: presentationOnly,
      );
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await ModuleGenerator(overwrite: effectiveOverwrite, dryRun: false).generate(
      moduleName, projectRoot,
      datasource: datasource, httpLib: httpLib, storageLib: storageLib,
      presentationOnly: presentationOnly,
    );
  }

  /// Muestra el menú interactivo de datasource.
  /// Devuelve (datasource, httpLib, storageLib, presentationOnly, container).
  (String, String, String, bool, bool) _askDatasource() {
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    print('');
    print('$cyan$bold  ¿Cómo accederá a los datos este módulo?$reset');
    print('');
    print('$yellow  1.$reset API REST            $gray→ provider con llamadas HTTP$reset');
    print('$yellow  2.$reset Solo local           $gray→ provider con almacenamiento en dispositivo$reset');
    print('$yellow  3.$reset Ambas                $gray→ REST con caché local (offline-first)$reset');
    print('$yellow  4.$reset Decidir después      $gray→ REST por defecto$reset');
    print('$yellow  5.$reset Sin datos propios    $gray→ solo Controller + Binding + View$reset');
    print('$yellow  6.$reset Módulo contenedor    $gray→ agrupa sub-screens (sin domain/data/controller)$reset');
    print('');
    stdout.write('Selecciona una opción [1]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final n = int.tryParse(input) ?? 1;

    if (n == 5) { return ('rest', 'get_connect', 'get_storage', true, false); }
    if (n == 6) { return ('rest', 'get_connect', 'get_storage', false, true); }

    String datasource;
    String httpLib = 'get_connect';
    String storageLib = 'get_storage';

    switch (n) {
      case 2:
        datasource = 'local';
        storageLib = _askStorageLib();
      case 3:
        datasource = 'both';
        httpLib = _askHttpLib();
        storageLib = _askStorageLib();
      default:
        datasource = 'rest';
        if (n == 1) { httpLib = _askHttpLib(); }
    }

    return (datasource, httpLib, storageLib, false, false);
  }

  String _askHttpLib() {
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    print('');
    print('  Librería HTTP $gray(sugerencias: dio, get_connect, http)$reset');
    stdout.write('  Escribe el nombre del paquete [dio]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty ? 'dio' : input;
  }

  /// Retorna un string con formato:
  ///   - 1 lib:  "hive"
  ///   - 2 libs: "hive:database,shared_preferences:settings"
  String _askStorageLib() => storageLibMenu();
}
