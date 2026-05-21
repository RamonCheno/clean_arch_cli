import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/project_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/flutter_packages.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';
import 'package:clean_arch_cli/src/commands/storage_lib_menu.dart';

class CreateProjectCommand extends Command<void> {
  @override
  final name = 'project';

  @override
  final description =
      'Crea un nuevo proyecto Flutter con Arquitectura Limpia + GetX.';

  @override
  String get invocation => '${runner!.executableName} create project <nombre>';

  // Paquetes con versión conocida → se escriben en pubspec.yaml
  final _pubspecPackages = <FlutterPackage>[];

  // Nombres sin versión → se agregan con `flutter pub add` al final
  final _pubAddNames = <String>[];

  // Nombres de dev deps → se agregan con `flutter pub add --dev` al final
  final _pubAddDevNames = <String>[];

  // Lista completa mostrada en el menú (general + específicos de plataforma).
  // Se usa para mapear el número elegido al paquete correcto.
  final _menuPackages = <FlutterPackage>[];

  CreateProjectCommand() {
    argParser
      ..addOption(
        'org',
        abbr: 'o',
        help: 'Organización / bundle id (ej. com.empresa)',
        defaultsTo: 'dev.ramonchenodev',
      )
      ..addOption(
        'output',
        abbr: 'd',
        help: 'Directorio de salida',
        defaultsTo: '.',
      )
      ..addMultiOption(
        'modules',
        abbr: 'm',
        help: 'Módulos iniciales separados por coma (ej. home,auth,profile)',
        defaultsTo: ['home'],
      )
      ..addOption(
        'platforms',
        abbr: 'l',
        help: 'Plataformas objetivo separadas por coma.\n'
            'Valores válidos: android, ios, web, windows, linux, macos\n'
            'Atajos: mobile (android,ios) | all (todas)',
        defaultsTo: 'mobile',
      )
      ..addMultiOption(
        'deps',
        help: 'Paquetes a incluir.\n'
            'Con versión → escribe en pubspec.yaml: nombre:^x.y.z\n'
            'Sin versión → usa flutter pub add:   nombre',
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Modo interactivo: solicita datos por consola',
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
        help: 'Tipo de fuente de datos de los módulos generados (rest | local | both)',
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
        'json-annotation',
        abbr: 'j',
        help: 'Usa json_annotation para generar fromJson/toJson automáticamente.\n'
            'Agrega json_annotation + json_serializable al proyecto.\n'
            'Requiere: dart run build_runner build después de agregar campos.',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    String? projectName;
    String org = argResults!['org'] as String;
    String outputDir = argResults!['output'] as String;
    List<String> modules = List<String>.from(argResults!['modules'] as List);
    final List<String> depsArg =
        List<String>.from(argResults!['deps'] as List);
    final interactive = argResults!['interactive'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    List<String> platforms = _resolvePlatforms(argResults!['platforms'] as String);
    String datasource = argResults!['datasource'] as String;
    String httpLib = argResults!['http-lib'] as String;
    String storageLib = argResults!['storage-lib'] as String;
    bool useJsonAnnotation = argResults!['json-annotation'] as bool;

    if (argResults!.rest.isNotEmpty) {
      projectName = argResults!.rest.first;
    }

    if (interactive || projectName == null) {
      Console.header('Nuevo Proyecto Flutter — Clean Architecture + GetX');

      projectName ??=
          Console.prompt('Nombre del proyecto', defaultValue: 'my_app');
      if (projectName == null || projectName.isEmpty) {
        Console.error('El nombre del proyecto no puede estar vacío.');
        exit(1);
      }

      org = Console.prompt('Organización (bundle id)', defaultValue: org) ?? org;
      outputDir =
          Console.prompt('Directorio de salida', defaultValue: outputDir) ??
              outputDir;

      final modulesInput = Console.prompt(
        'Módulos iniciales (separados por coma)',
        defaultValue: modules.join(','),
      );
      if (modulesInput != null && modulesInput.isNotEmpty) {
        modules = modulesInput.split(',').map((m) => m.trim()).toList();
      }

      platforms = _selectPlatformsInteractively(platforms);

      final dsResult = _askDatasourceInteractively();
      datasource = dsResult.$1;
      httpLib = dsResult.$2;
      storageLib = dsResult.$3;
      _preSelectDatasourcePackages(datasource, httpLib, storageLib);

      useJsonAnnotation = _askJsonAnnotation();
      if (useJsonAnnotation) { _preSelectJsonAnnotation(); }

      _selectPackagesInteractively(platforms);
    } else if (depsArg.isNotEmpty) {
      _resolvePackagesByName(depsArg);
    }

    // Si se usó --json-annotation fuera del modo interactivo, pre-seleccionar
    if (useJsonAnnotation && !interactive) { _preSelectJsonAnnotation(); }

    if (!projectName.isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$projectName". Use solo minúsculas, números y guiones bajos.');
      exit(1);
    }

    final validModules = modules
        .where((m) => m.isNotEmpty)
        .map((m) => m.toSnakeCase())
        .toList();

    final projectRoot = p.join(outputDir, projectName.toSnakeCase());

    await ProjectGenerator(dryRun: dryRun).generate(
      projectName: projectName,
      outputDir: outputDir,
      org: org,
      modules: validModules,
      packages: _pubspecPackages,
      platforms: platforms,
      datasource: datasource,
      httpLib: httpLib,
      storageLib: storageLib,
      useJsonAnnotation: useJsonAnnotation,
    );

    if (_pubAddNames.isNotEmpty) {
      _runPubAdd(projectRoot);
    }

    if (_pubAddDevNames.isNotEmpty) {
      _runPubAddDev(projectRoot);
    }
  }

  // ── Datasource ───────────────────────────────────────────────────────────

  /// Menú interactivo de datasource. Devuelve (datasource, httpLib, storageLib).
  (String, String, String) _askDatasourceInteractively() {
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    print('');
    print('$cyan$bold  ¿Cómo accederá a los datos tu app?$reset');
    print('$gray  Determina qué código se genera en la capa Data (Provider).$reset');
    print('');
    print('$yellow  1.$reset API REST       $gray→ provider con llamadas HTTP$reset');
    print('$yellow  2.$reset Solo local      $gray→ provider con almacenamiento en dispositivo$reset');
    print('$yellow  3.$reset Ambas           $gray→ REST con caché local (offline-first)$reset');
    print('$yellow  4.$reset Decidir después $gray→ REST por defecto$reset');
    print('');
    stdout.write('Selecciona una opción [1]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    print('');
    final n = int.tryParse(input) ?? 1;

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
        if (n == 1) httpLib = _askHttpLib();
    }

    return (datasource, httpLib, storageLib);
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

  String _askStorageLib() => storageLibMenu();

  /// Pregunta si se quiere usar json_annotation para serialización automática.
  bool _askJsonAnnotation() {
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    print('');
    print('$cyan  ¿Usar json_annotation para serialización automática?$reset');
    print('$gray  Genera fromJson/toJson con @JsonSerializable en lugar de código manual.$reset');
    print('$gray  Requiere: dart run build_runner build después de agregar campos.$reset');
    print('');
    print('$yellow  1.$reset Sí  $gray→ @JsonSerializable() + build_runner generará el código$reset');
    print('$yellow  2.$reset No  $gray→ fromJson/toJson manuales con TODO (opción por defecto)$reset');
    print('');
    stdout.write('Selecciona una opción [2]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    print('');
    return input == '1';
  }

  /// Agrega json_annotation (runtime) y json_serializable (dev) a los paquetes
  /// pre-seleccionados, evitando duplicados.
  void _preSelectJsonAnnotation() {
    const green = '\x1B[32m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    final pkg = FlutterPackages.byName('json_annotation');
    if (pkg == null) { return; }
    if (_pubspecPackages.any((p) => p.name == 'json_annotation')) { return; }

    _pubspecPackages.add(pkg);
    print('$green  ✓ ${pkg.name} ${pkg.version}$gray → pubspec.yaml$reset');
    for (final entry in pkg.devDependencies.entries) {
      print('$green  ✓ ${entry.key} ${entry.value}$gray → dev_dependencies$reset');
    }
    print('');
  }

  /// Pre-selecciona paquetes en _pubspecPackages según el datasource elegido.
  void _preSelectDatasourcePackages(
      String datasource, String httpLib, String storageLib) {
    const green = '\x1B[32m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    final toAdd = <String>[];

    if (datasource == 'rest' || datasource == 'both') {
      if (httpLib == 'dio') {
        toAdd.addAll(['dio', 'connectivity_plus']);
      }
    }

    if (datasource == 'local' || datasource == 'both') {
      // Extrae los nombres de lib del formato simple ("hive") o dual ("hive:database,shared_preferences:settings")
      final libNames = storageLib.contains(',')
          ? storageLib.split(',').map((p) => p.split(':').first.trim())
          : [storageLib.split(':').first.trim()];

      for (final lib in libNames) {
        switch (lib) {
          case 'none': break;
          case 'hive':
          case 'hive_flutter':          toAdd.add('hive_flutter');
          case 'shared_preferences':
          case 'shared_prefs':          toAdd.add('shared_preferences');
          case 'flutter_secure_storage':
          case 'secure_storage':        toAdd.add('flutter_secure_storage');
          case 'sqflite':               toAdd.add('sqflite');
          case 'isar':                  toAdd.add('isar');
          case 'drift':                 toAdd.add('drift');
          case 'get_storage':           toAdd.add('get_storage');
          default: break;
        }
      }
    }

    if (toAdd.isEmpty) return;

    print('$green  Paquetes pre-seleccionados según el datasource:$reset');
    for (final pkgName in toAdd) {
      if (_pubspecPackages.any((p) => p.name == pkgName)) continue;
      final pkg = FlutterPackages.byName(pkgName);
      if (pkg != null) {
        _pubspecPackages.add(pkg);
        print('$green  ✓ ${pkg.name} ${pkg.version}$gray → pubspec.yaml$reset');
      } else {
        // Paquete no está en la lista conocida → agregar con pub add
        _pubAddNames.add(pkgName);
        print('$green  ✓ $pkgName$gray → flutter pub add$reset');
      }
    }
    print('');
  }

  // ── Plataformas ──────────────────────────────────────────────────────────

  /// Convierte el valor del flag --platforms en una lista de plataformas.
  List<String> _resolvePlatforms(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed == 'mobile') return ['android', 'ios'];
    if (trimmed == 'all') {
      return ['android', 'ios', 'web', 'windows', 'linux', 'macos'];
    }
    return trimmed
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Menú interactivo para elegir las plataformas objetivo.
  List<String> _selectPlatformsInteractively(List<String> currentPlatforms) {
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';
    const reset = '\x1B[0m';

    final presets = [
      ('Android + iOS', ['android', 'ios']),
      ('Android solamente', ['android']),
      ('iOS solamente', ['ios']),
      ('Android + iOS + Web', ['android', 'ios', 'web']),
      ('Escritorio (Windows, Linux, macOS)', ['windows', 'linux', 'macos']),
      ('Multi-plataforma (Android + iOS + Web + Escritorio)',
          ['android', 'ios', 'web', 'windows', 'linux', 'macos']),
    ];

    print('');
    print('$cyan$bold  Plataformas objetivo$reset');
    print('$gray  ¿Para qué sistema(s) operativo(s) vas a desarrollar?$reset');
    print('');

    for (var i = 0; i < presets.length; i++) {
      final (label, platforms) = presets[i];
      final num = '${i + 1}.'.padRight(4);
      final platformStr = gray + platforms.join(', ') + reset;
      print('$yellow  $num$reset $label  $platformStr');
    }

    print('$yellow  ${presets.length + 1}.$reset Personalizado '
        '$gray(escribe las plataformas separadas por coma)$reset');
    print('');
    stdout.write('Selecciona una opción [1]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    print('');

    final n = int.tryParse(input);

    // Opción personalizada
    if (n == presets.length + 1 || input.isEmpty && false) {
      stdout.write(
          'Plataformas (android, ios, web, windows, linux, macos): ');
      final custom = stdin.readLineSync()?.trim() ?? '';
      if (custom.isNotEmpty) {
        final selected = custom
            .split(',')
            .map((p) => p.trim().toLowerCase())
            .where((p) => p.isNotEmpty)
            .toList();
        Console.info(
            '  Plataformas seleccionadas: ${selected.join(', ')}');
        return selected;
      }
      return currentPlatforms;
    }

    // Preset seleccionado (default: 1)
    final idx = (n == null || n < 1 || n > presets.length) ? 0 : n - 1;
    final (label, selected) = presets[idx];
    Console.info('  Plataformas: $label (${selected.join(', ')})');
    return selected;
  }

  // ── Selección interactiva ────────────────────────────────────────────────

  void _selectPackagesInteractively(List<String> platforms) {
    final menu = _printPackageMenu(platforms);
    final otroN = menu.otro;
    final devN = menu.dev;

    stdout.write('\nIngresa los números separados por comas (Enter para ninguna): ');
    final numInput = stdin.readLineSync()?.trim() ?? '';

    final parts = numInput.split(RegExp(r'[,\s]+')).map((s) => s.trim());
    final wantsOtro = parts.any((s) => int.tryParse(s) == otroN);
    final wantsDev = parts.any((s) => int.tryParse(s) == devN);
    final withoutSpecial = parts
        .where((s) => int.tryParse(s) != otroN && int.tryParse(s) != devN)
        .join(',');

    if (withoutSpecial.isNotEmpty) _parseNumberSelection(withoutSpecial);

    if (wantsOtro) {
      print('');
      print('  Paquete personalizado (runtime):');
      print('  • Con versión  → escribe en pubspec.yaml   (ej: flutter_map:^7.0.1)');
      print('  • Solo nombre  → agrega con flutter pub add (ej: pusher_channels)');
      stdout.write('  > ');
      final custom = stdin.readLineSync()?.trim() ?? '';
      if (custom.isNotEmpty) _parseCustomInput(custom);
    }

    if (wantsDev) {
      print('');
      print('  Dev dependencies (--dev):');
      print('  • Solo nombre → agrega con flutter pub add --dev (ej: mockito, build_runner)');
      stdout.write('  > ');
      final devInput = stdin.readLineSync()?.trim() ?? '';
      if (devInput.isNotEmpty) _parseDevInput(devInput);
    }

    if (_pubspecPackages.isEmpty && _pubAddNames.isEmpty && _pubAddDevNames.isEmpty) {
      Console.info('Sin dependencias adicionales.');
    }
  }

  ({int otro, int dev}) _printPackageMenu(List<String> platforms) {
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    const gray = '\x1B[90m';
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';

    _menuPackages.clear();

    print('');
    print('$cyan$bold  Dependencias externas$reset');
    print('$gray  GetX ya está incluido. Selecciona paquetes adicionales:$reset');
    if (_pubspecPackages.isNotEmpty) {
      print('');
      print('$green$bold  Ya incluidos (pre-seleccionados):$reset');
      for (final pkg in _pubspecPackages) {
        print('$green  ✓ ${pkg.name} ${pkg.version}$reset');
      }
    }
    print('');

    int index = 1;
    String? currentCategory;

    // ── Paquetes generales ──
    for (final pkg in FlutterPackages.all) {
      // Saltar los ya pre-seleccionados (no aparecen en el menú numerado)
      if (_pubspecPackages.any((p) => p.name == pkg.name)) continue;
      if (pkg.category != currentCategory) {
        currentCategory = pkg.category;
        print('$bold  $currentCategory$reset');
      }
      _menuPackages.add(pkg);
      final num = index.toString().padLeft(3);
      final namePad = pkg.name.padRight(28);
      final versionPad = pkg.version.padRight(10);
      print('$yellow$num.$reset $namePad $gray$versionPad$reset ${pkg.description}');
      if (pkg.devDependencies.isNotEmpty) {
        final devList = pkg.devDependencies.keys.join(', ');
        print('     $gray↳ incluye dev: $devList$reset');
      }
      index++;
    }

    // ── Paquetes específicos por plataforma (solo si hay 2+ categorías) ──
    final sections = FlutterPackages.platformSectionsFor(platforms);
    if (sections.isNotEmpty) {
      print('');
      print('$green$bold  Específicos por plataforma$reset');
      print(
          '$gray  Recomendados según las plataformas seleccionadas (${platforms.join(', ')}):$reset');

      for (final section in sections) {
        print('');
        print('$bold  ${section.label}$reset');
        for (final pkg in section.packages) {
          if (_pubspecPackages.any((p) => p.name == pkg.name)) continue;
          final num = index.toString().padLeft(3);
          final namePad = pkg.name.padRight(28);
          final versionPad = pkg.version.padRight(10);
          print(
              '$yellow$num.$reset $namePad $gray$versionPad$reset ${pkg.description}');
          _menuPackages.add(pkg);
          index++;
        }
      }
    }

    // Opciones "Otro" y "Dev deps" al final
    print('');
    print('$yellow${index.toString().padLeft(3)}.$reset Otro'
        '                         '
        '$gray→ escribe el nombre del paquete (runtime)$reset');
    final otroN = index;
    index++;
    print('$yellow${index.toString().padLeft(3)}.$reset Dev deps'
        '                      '
        '$gray→ paquetes con --dev (ej: build_runner, mockito)$reset');

    return (otro: otroN, dev: index);
  }

  void _parseNumberSelection(String input) {
    for (final part in input.split(RegExp(r'[,\s]+'))) {
      final n = int.tryParse(part.trim());
      if (n != null && n >= 1 && n <= _menuPackages.length) {
        final pkg = _menuPackages[n - 1];
        _pubspecPackages.add(pkg);
        Console.info('  + ${pkg.name} ${pkg.version}  → pubspec.yaml');
      } else if (part.trim().isNotEmpty) {
        Console.warning('Número inválido ignorado: "$part"');
      }
    }
  }

  // ── Modo no-interactivo con --deps ───────────────────────────────────────

  void _resolvePackagesByName(List<String> entries) {
    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;

      final colonIdx = trimmed.indexOf(':');
      final nameOnly =
          colonIdx >= 0 ? trimmed.substring(0, colonIdx).trim() : trimmed;
      final versionPart =
          colonIdx >= 0 ? trimmed.substring(colonIdx + 1).trim() : '';

      final catalogPkg = FlutterPackages.byName(nameOnly);
      if (catalogPkg != null) {
        _pubspecPackages.add(catalogPkg);
        Console.info('  + $nameOnly ${catalogPkg.version}  → pubspec.yaml');
      } else if (versionPart.isNotEmpty) {
        _addToPubspec(nameOnly, versionPart);
      } else {
        _addToPubAdd(nameOnly);
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Parsea entradas libres: `nombre` o `nombre:^versión`, separadas por coma.
  void _parseCustomInput(String input) {
    for (final part in input.split(RegExp(r',\s*'))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final colonIdx = trimmed.indexOf(':');
      if (colonIdx < 0) {
        // Solo nombre → flutter pub add
        _addToPubAdd(trimmed);
      } else {
        final pkgName = trimmed.substring(0, colonIdx).trim();
        final version = trimmed.substring(colonIdx + 1).trim();
        if (pkgName.isEmpty || version.isEmpty) {
          Console.warning('"$trimmed" ignorado — formato inválido.');
        } else {
          _addToPubspec(pkgName, version);
        }
      }
    }
  }

  void _addToPubspec(String name, String version) {
    _pubspecPackages.add(FlutterPackage(
      name: name,
      version: version,
      description: 'Paquete personalizado',
      category: 'Personalizado',
    ));
    Console.info('  + $name $version  → pubspec.yaml');
  }

  void _addToPubAdd(String name) {
    _pubAddNames.add(name);
    Console.info('  + $name  → flutter pub add  (versión más reciente)');
  }

  void _parseDevInput(String input) {
    for (final part in input.split(RegExp(r',\s*'))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      _addToPubAddDev(trimmed);
    }
  }

  void _addToPubAddDev(String name) {
    _pubAddDevNames.add(name);
    Console.info('  + $name  → flutter pub add --dev  (versión más reciente)');
  }

  // ── flutter pub add ──────────────────────────────────────────────────────

  void _runPubAdd(String projectRoot) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    Console.info('');
    Console.header('Agregando paquetes con flutter pub add');

    for (final pkgName in _pubAddNames) {
      print('$yellow  \$ flutter pub add $pkgName$reset');

      final result = Process.runSync(
        'flutter',
        ['pub', 'add', pkgName],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        Console.success('  $pkgName agregado correctamente');
      } else {
        Console.error('  Error al agregar $pkgName');
        final stderr = result.stderr.toString().trim();
        final stdout = result.stdout.toString().trim();
        if (stderr.isNotEmpty) {
          for (final line in stderr.split('\n')) {
            if (line.trim().isNotEmpty) Console.warning('    $line');
          }
        } else if (stdout.isNotEmpty) {
          for (final line in stdout.split('\n')) {
            if (line.trim().isNotEmpty) Console.warning('    $line');
          }
        }
        Console.warning('  Agrégalo manualmente: flutter pub add $pkgName');
      }
    }
  }

  void _runPubAddDev(String projectRoot) {
    if (_pubAddDevNames.isEmpty) return;

    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    Console.info('');
    Console.header('Agregando dev dependencies con flutter pub add --dev');

    for (final pkgName in _pubAddDevNames) {
      print('$yellow  \$ flutter pub add --dev $pkgName$reset');

      final result = Process.runSync(
        'flutter',
        ['pub', 'add', '--dev', pkgName],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        Console.success('  $pkgName agregado correctamente');
      } else {
        Console.error('  Error al agregar $pkgName');
        final stderr = result.stderr.toString().trim();
        final stdout = result.stdout.toString().trim();
        if (stderr.isNotEmpty) {
          for (final line in stderr.split('\n')) {
            if (line.trim().isNotEmpty) Console.warning('    $line');
          }
        } else if (stdout.isNotEmpty) {
          for (final line in stdout.split('\n')) {
            if (line.trim().isNotEmpty) Console.warning('    $line');
          }
        }
        Console.warning('  Agrégalo manualmente: flutter pub add --dev $pkgName');
      }
    }
  }
}
