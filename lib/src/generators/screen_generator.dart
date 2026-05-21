import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/bundles/screen_bundle.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/generators/module_generator.dart';
import 'package:clean_arch_cli/src/generators/route_injector.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

/// Genera una screen (vista + controlador + binding) dentro de un módulo o standalone.
class ScreenGenerator {
  final bool _overwrite;
  final bool _dryRun;

  ScreenGenerator({bool overwrite = false, bool dryRun = false})
      : _overwrite = overwrite,
        _dryRun = dryRun;

  Future<void> generate(String screenName, String projectRoot,
      {String? parentModule}) async {
    final packageName = readPackageName(projectRoot);
    final name = screenName.toSnakeCase();
    final pascal = name.toPascalCase();

    Console.header('Creando screen: $pascal');

    // ── Auto-crear módulo contenedor si el padre no existe ────────────────
    // Solo aplica al nivel 1 (módulo directo).
    // Nivel 2 (tasks/add_task): el módulo ya debe existir; solo verificamos
    // que el marcador compuesto esté presente.
    if (parentModule != null && parentModule.isNotEmpty) {
      final parts = parentModule.split('/');
      final mod   = parts[0].toSnakeCase();
      final pagesPath = p.join(projectRoot, 'lib', 'app', 'routes', 'app_pages.dart');
      final pagesFile = File(pagesPath);

      if (parts.length == 1) {
        // Nivel 1 — auto-crear contenedor si no existe
        final marker = '// cleanarch:inject:$mod';
        if (pagesFile.existsSync() &&
            !pagesFile.readAsStringSync().contains(marker)) {
          Console.warning(
              'El módulo "$mod" no existe como contenedor en app_pages.dart.');
          Console.info(
              '  Las sub-screens necesitan que el módulo padre esté registrado.');
          Console.info('');
          stdout.write('  ¿Deseas crearlo automáticamente como módulo contenedor? [S/n]: ');
          final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
          if (answer == 'n' || answer == 'no') {
            Console.info('');
            Console.info(
                'Crea primero el módulo contenedor con:\n'
                '  cleanarch create module $mod --container');
            return;
          }
          Console.info('');
          await ModuleGenerator(dryRun: _dryRun)
              .generateContainer(mod, projectRoot, packageName: packageName);
          Console.info('');
        }
      } else {
        // Nivel 2 — verificar que el marcador compuesto existe
        final parentScreen      = parts[1].toSnakeCase();
        final parentScreenCamel = parentScreen.toCamelCase();
        final marker = '// cleanarch:inject:$mod:$parentScreenCamel';
        if (pagesFile.existsSync() &&
            !pagesFile.readAsStringSync().contains(marker)) {
          Console.error(
            'No se encontró el marcador "$marker" en app_pages.dart.\n'
            '  Asegúrate de que "$parentScreen" tenga un bloque children con ese marcador.',
          );
          return;
        }
      }
    }

    // Compute the base directory for this screen.
    // parentModule puede ser 'tasks' (nivel 1) o 'tasks/add_task' (nivel 2).
    final String screenBase;
    final String importPath;

    if (parentModule != null && parentModule.isNotEmpty) {
      final parts = parentModule.split('/');
      final mod   = parts[0].toSnakeCase();

      if (parts.length >= 2) {
        final parentScreen = parts[1].toSnakeCase();
        screenBase = p.join(projectRoot, 'lib', 'app', 'modules', mod,
            'screens', parentScreen, 'screens', name);
        importPath =
            'app/modules/$mod/screens/$parentScreen/screens/$name';
        Console.info('Módulo padre: $mod  /  Screen padre: $parentScreen');
      } else {
        screenBase = p.join(
            projectRoot, 'lib', 'app', 'modules', mod, 'screens', name);
        importPath = 'app/modules/$mod/screens/$name';
        Console.info('Módulo padre: $mod');
      }
    } else {
      screenBase = p.join(projectRoot, 'lib', 'app', 'screens', name);
      importPath = 'app/screens/$name';
    }

    Console.step(1, 'Archivos de la screen');
    final generator = await MasonGenerator.fromBundle(screenBundle);
    await generator.generate(
      // The screen brick's __brick__/ is relative to screenBase, not projectRoot
      MasonTarget(screenBase, overwrite: _overwrite, dryRun: _dryRun),
      vars: {
        'name': name,
        'package_name': packageName,
        'parent_module': parentModule ?? '',
        'has_parent': parentModule != null && parentModule.isNotEmpty,
        'import_path': importPath,
      },
    );

    final injected = RouteInjector.injectScreen(
      projectRoot,
      name,
      pascal,
      parentModule: parentModule,
      packageName: packageName,
      dryRun: _dryRun,
    );

    Console.success('Screen "$pascal" creada en $screenBase');

    if (injected) {
      Console.info('  ✔ Ruta inyectada en app_pages.dart y app_routes.dart');
    } else {
      _printManualSteps(name, pascal, parentModule: parentModule);
    }
  }

  void _printManualSteps(String name, String pascal, {String? parentModule}) {
    final routeName = name.toCamelCase();       // addTask
    final routePath = '/${name.toKebabCase()}'; // /add-task
    Console.info('');
    if (parentModule != null) {
      Console.info(
          'Agrega la ruta en los children de "$parentModule" en app_pages.dart:');
    } else {
      Console.info('Agrega la ruta en los children de home en app_pages.dart:');
    }
    Console.info('');
    Console.info(
        '  GetPage(name: Routes.$routeName, page: () => const ${pascal}Screen(), binding: ${pascal}Binding()),');
    Console.info('');
    Console.info('Y la constante en app_routes.dart:');
    Console.info("  static const $routeName = '$routePath';");
    Console.info('');
  }
}
