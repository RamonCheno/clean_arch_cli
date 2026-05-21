import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/bundles/feature_bundle.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/generators/route_injector.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

/// Genera un feature ligero: vista + controlador + binding (sin capas domain/data).
class FeatureGenerator {
  final bool _overwrite;
  final bool _dryRun;

  FeatureGenerator({bool overwrite = false, bool dryRun = false})
      : _overwrite = overwrite,
        _dryRun = dryRun;

  Future<void> generate(String featureName, String projectRoot) async {
    final packageName = readPackageName(projectRoot);
    final name = featureName.toSnakeCase();
    final pascal = name.toPascalCase();

    Console.header('Creando feature: $pascal');

    Console.step(1, 'Archivos del feature');
    final generator = await MasonGenerator.fromBundle(featureBundle);
    await generator.generate(
      MasonTarget(projectRoot, overwrite: _overwrite, dryRun: _dryRun),
      vars: {'name': name, 'package_name': packageName},
    );

    if (!_dryRun) {
      final widgetsDir =
          p.join(projectRoot, 'lib', 'app', 'features', name, 'widgets');
      Directory(widgetsDir).createSync(recursive: true);
      File(p.join(widgetsDir, '.gitkeep')).writeAsStringSync('');
    }

    final injected = RouteInjector.injectFeature(projectRoot, name, pascal,
        packageName: packageName, dryRun: _dryRun);

    Console.success(
        'Feature "$pascal" creado en $projectRoot/lib/app/features/$name');

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
        '  GetPage(name: Routes.$name, page: () => const ${pascal}View(), binding: ${pascal}Binding()),');
    Console.info('');
    Console.info('Y la constante en app_routes.dart:');
    Console.info("  static const $name = '/$name';");
    Console.info('');
  }
}
