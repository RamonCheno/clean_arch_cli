import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

/// Inyecta rutas automáticamente en app_pages.dart y app_routes.dart.
///
/// Usa marcadores de texto en los archivos para saber dónde insertar:
///   // cleanarch:import  → donde van los nuevos imports
///   // cleanarch:inject  → donde van los GetPage hijos de home
///   // cleanarch:inject:nombre → donde van los GetPage hijos de un módulo
///   // cleanarch:route   → donde van las constantes de ruta
class RouteInjector {
  static const _injectMarker = '// cleanarch:inject';
  static const _routeMarker = '// cleanarch:route';
  static const _importMarker = '// cleanarch:import';

  static String _pagesPath(String root) =>
      p.join(root, 'lib', 'app', 'routes', 'app_pages.dart');

  static String _routesPath(String root) =>
      p.join(root, 'lib', 'app', 'routes', 'app_routes.dart');

  static bool _filesExist(String root) =>
      File(_pagesPath(root)).existsSync() &&
      File(_routesPath(root)).existsSync();

  // ── Módulo — hijo directo de home, con su propio bloque children ────────

  static bool injectModule(
    String projectRoot,
    String name,
    String pascal, {
    required String packageName,
    bool dryRun = false,
    bool container = false,
  }) {
    if (!_filesExist(projectRoot)) { return false; }

    final pagesFile = _pagesPath(projectRoot);
    final viewImport =
        "import 'package:$packageName/app/modules/$name/views/${name}_view.dart';";
    if (File(pagesFile).readAsStringSync().contains(viewImport)) {
      Console.warning(
          'Módulo "$name" ya existe en app_pages.dart — saltando inyección de ruta.');
      return true;
    }

    if (dryRun) {
      Console.info('  [dry-run] Inyectaría ruta "$name" en app_pages.dart y app_routes.dart');
      return true;
    }

    _injectRouteConstant(_routesPath(projectRoot), name, '/$name',
        sectionModule: name);

    // Módulo contenedor: solo importa la view shell, sin binding propio.
    // Módulo normal: importa view + binding.
    final imports = container
        ? [viewImport]
        : [
            viewImport,
            "import 'package:$packageName/app/modules/$name/bindings/${name}_binding.dart';",
          ];
    _injectImports(pagesFile, imports);

    // Módulo contenedor: GetPage sin binding (solo agrupa children).
    // Módulo normal: GetPage con binding.
    final block = container
        ? [
            'GetPage(',
            '  name: Routes.$name,',
            '  page: () => const ${pascal}View(),',
            '  // Módulo contenedor — sin binding propio',
            '  children: [',
            '    // cleanarch:inject:$name',
            '  ],',
            '),',
          ]
        : [
            'GetPage(',
            '  name: Routes.$name,',
            '  page: () => const ${pascal}View(),',
            '  binding: ${pascal}Binding(),',
            '  children: [',
            '    // cleanarch:inject:$name',
            '  ],',
            '),',
          ];
    _injectBlock(pagesFile, _injectMarker, block);
    return true;
  }

  // ── Feature — hijo directo de home, sin children propios ────────────────

  static bool injectFeature(
    String projectRoot,
    String name,
    String pascal, {
    required String packageName,
    bool dryRun = false,
  }) {
    if (!_filesExist(projectRoot)) { return false; }

    final pagesFile = _pagesPath(projectRoot);
    final viewImport =
        "import 'package:$packageName/app/features/$name/views/${name}_view.dart';";
    if (File(pagesFile).readAsStringSync().contains(viewImport)) {
      Console.warning(
          'Feature "$name" ya existe en app_pages.dart — saltando inyección de ruta.');
      return true;
    }

    if (dryRun) {
      Console.info('  [dry-run] Inyectaría ruta "$name" en app_pages.dart y app_routes.dart');
      return true;
    }

    _injectRouteConstant(_routesPath(projectRoot), name, '/$name',
        sectionModule: name);
    _injectImports(pagesFile, [
      viewImport,
      "import 'package:$packageName/app/features/$name/bindings/${name}_binding.dart';",
    ]);
    _injectBlock(pagesFile, _injectMarker, [
      'GetPage(',
      '  name: Routes.$name,',
      '  page: () => const ${pascal}View(),',
      '  binding: ${pascal}Binding(),',
      '),',
    ]);
    return true;
  }

  // ── Screen — hijo de un módulo, hijo de una screen, o hijo directo de home ─

  /// [parentModule] puede ser:
  ///   - null o ''        → hijo directo de home  (marker: // cleanarch:inject)
  ///   - 'tasks'          → hijo del módulo tasks (marker: // cleanarch:inject:tasks)
  ///   - 'tasks/add_task' → hijo de add_task dentro de tasks
  ///                        (marker: // cleanarch:inject:tasks:addTask)
  static bool injectScreen(
    String projectRoot,
    String name,
    String pascal, {
    String? parentModule,
    required String packageName,
    bool dryRun = false,
  }) {
    if (!_filesExist(projectRoot)) { return false; }

    final pagesFile = _pagesPath(projectRoot);

    // Bug 4 — nombre de constante en lowerCamelCase, ruta en kebab-case sin sufijo
    final routeName = name.toCamelCase();          // addTask
    final routePath = '/${name.toKebabCase()}';    // /add-task

    final String viewImport;
    final String bindingImport;
    final String marker;

    if (parentModule != null && parentModule.isNotEmpty) {
      // Soporte de módulo compuesto: 'tasks/add_task'
      final parts = parentModule.split('/');
      final mod   = parts[0].toSnakeCase();

      if (parts.length >= 2) {
        // Nivel 2: screen dentro de otra screen dentro de un módulo
        final parentScreen = parts[1].toSnakeCase();
        final parentScreenCamel = parentScreen.toCamelCase();
        viewImport =
            "import 'package:$packageName/app/modules/$mod/screens/$parentScreen/screens/$name/views/${name}_screen.dart';";
        bindingImport =
            "import 'package:$packageName/app/modules/$mod/screens/$parentScreen/screens/$name/bindings/${name}_binding.dart';";
        marker = '$_injectMarker:$mod:$parentScreenCamel';
      } else {
        // Nivel 1: screen directa de un módulo
        viewImport =
            "import 'package:$packageName/app/modules/$mod/screens/$name/views/${name}_screen.dart';";
        bindingImport =
            "import 'package:$packageName/app/modules/$mod/screens/$name/bindings/${name}_binding.dart';";
        marker = '$_injectMarker:$mod';
      }
    } else {
      viewImport =
          "import 'package:$packageName/app/screens/$name/views/${name}_screen.dart';";
      bindingImport =
          "import 'package:$packageName/app/screens/$name/bindings/${name}_binding.dart';";
      marker = _injectMarker;
    }

    if (File(pagesFile).readAsStringSync().contains(viewImport)) {
      Console.warning(
          'Screen "$name" ya existe en app_pages.dart — saltando inyección de ruta.');
      return true;
    }

    // Bug 3 — verificar que el marker existe ANTES de tocar cualquier archivo.
    // Si no existe y hay módulo padre, el usuario debe crear el módulo primero.
    final pagesContent = File(pagesFile).readAsStringSync();
    if (!pagesContent.contains(marker)) {
      if (parentModule != null && parentModule.isNotEmpty) {
        Console.error(
          'No se encontró el marcador "$marker" en app_pages.dart.\n'
          '  Crea primero el módulo padre con:\n'
          '    cleanarch create module $parentModule',
        );
      } else {
        Console.warning(
          'No se encontró el marcador "$marker" en app_pages.dart. '
          'Agrega la ruta manualmente.',
        );
      }
      return false;
    }

    if (dryRun) {
      Console.info('  [dry-run] Inyectaría ruta "$routeName" ($routePath) en app_pages.dart y app_routes.dart');
      return true;
    }

    // sectionModule = primer segmento del parentModule ('tasks' en 'tasks/add_task')
    final sectionMod = (parentModule != null && parentModule.isNotEmpty)
        ? parentModule.split('/').first.toSnakeCase()
        : null;
    _injectRouteConstant(_routesPath(projectRoot), routeName, routePath,
        sectionModule: sectionMod);
    _injectImports(pagesFile, [viewImport, bindingImport]);
    _injectBlock(pagesFile, marker, [
      'GetPage(',
      '  name: Routes.$routeName,',
      '  page: () => const ${pascal}Screen(),',
      '  binding: ${pascal}Binding(),',
      '),',
    ]);
    return true;
  }

  // ── Helpers internos ─────────────────────────────────────────────────────

  /// Inyecta una constante de ruta en app_routes.dart.
  ///
  /// [sectionModule] — si se provee, busca primero el marcador de sección
  /// `// cleanarch:route:<sectionModule>` y lo usa como punto de inserción.
  /// Si no existe, cae al marcador global `// cleanarch:route`.
  static void _injectRouteConstant(
      String filePath, String name, String path,
      {String? sectionModule}) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    if (content.contains('static const $name =')) { return; }

    // Determinar qué marcador usar como punto de inserción.
    final sectionMarker = sectionModule != null
        ? '$_routeMarker:$sectionModule'
        : null;
    final activeMarker = (sectionMarker != null && content.contains(sectionMarker))
        ? sectionMarker
        : _routeMarker;

    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.trim() == activeMarker) {
        result.add("  static const $name = '$path';");
      }
      result.add(line);
    }
    file.writeAsStringSync(result.join('\n'));
  }

  static void _injectImports(String filePath, List<String> imports) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final toAdd = imports.where((i) => !content.contains(i)).toList();
    if (toAdd.isEmpty) { return; }

    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.trim() == _importMarker) {
        result.addAll(toAdd);
      }
      result.add(line);
    }
    file.writeAsStringSync(result.join('\n'));
  }

  /// Inserta [blockLines] justo antes de la línea que contiene [marker],
  /// usando la misma indentación que tiene esa línea en el archivo.
  static void _injectBlock(
      String filePath, String marker, List<String> blockLines) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final result = <String>[];
    bool found = false;

    for (final line in lines) {
      if (!found && line.trim() == marker) {
        found = true;
        final indent = ' ' * (line.length - line.trimLeft().length);
        for (final blockLine in blockLines) {
          result.add(blockLine.isEmpty ? '' : '$indent$blockLine');
        }
      }
      result.add(line);
    }

    if (!found) {
      Console.warning(
        'No se encontró el marcador "$marker" en ${p.basename(filePath)}. '
        'Agrega la ruta manualmente.',
      );
    } else {
      file.writeAsStringSync(result.join('\n'));
    }
  }
}
