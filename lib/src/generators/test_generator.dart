import 'package:mason/mason.dart';
import 'package:clean_arch_cli/src/bundles/test_feature_bundle.dart';
import 'package:clean_arch_cli/src/bundles/test_module_bundle.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

/// Tipos de test que se pueden generar para un módulo.
enum TestType { controller, usecase, repository, widget, all }

class TestGenerator {
  /// Genera tests para un **módulo** completo (domain + data + presentation).
  Future<void> generateForModule(
    String moduleName,
    String projectRoot, {
    TestType type = TestType.all,
  }) async {
    final name = moduleName.toSnakeCase();
    final pascal = name.toPascalCase();
    final packageName = readPackageName(projectRoot);

    Console.header('Generando tests para módulo: $pascal');

    // The test_module brick generates all 4 test files at once.
    // For selective generation (TestType != all), we generate all and let
    // overwrite:false skip existing files.
    Console.step(1, 'Generando archivos de test');
    final generator = await MasonGenerator.fromBundle(testModuleBundle);
    await generator.generate(
      MasonTarget(projectRoot),
      vars: {'name': name, 'package_name': packageName},
    );

    _printSummary(projectRoot);
  }

  /// Genera tests para un **feature** ligero (controlador + vista).
  Future<void> generateForFeature(
    String featureName,
    String projectRoot, {
    TestType type = TestType.all,
  }) async {
    final name = featureName.toSnakeCase();
    final pascal = name.toPascalCase();
    final packageName = readPackageName(projectRoot);

    Console.header('Generando tests para feature: $pascal');

    Console.step(1, 'Generando archivos de test');
    final generator = await MasonGenerator.fromBundle(testFeatureBundle);
    await generator.generate(
      MasonTarget(projectRoot),
      vars: {'name': name, 'package_name': packageName},
    );

    _printSummary(projectRoot);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _printSummary(String projectRoot) {
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';
    const cyan = '\x1B[36m';
    const bold = '\x1B[1m';
    const reset = '\x1B[0m';

    Console.success('');
    Console.success('Tests generados correctamente.');
    print('');
    print('$bold${cyan}Siguiente paso — genera los mocks con:$reset');
    print('');
    print('$yellow  cd $projectRoot$reset');
    print('$yellow  dart run build_runner build --delete-conflicting-outputs$reset');
    print('');
    print('$bold${cyan}Ejecuta los tests con:$reset');
    print('');
    print('$yellow  flutter test$reset');
    print('$yellow  flutter test --coverage$reset');
    print('');
    print(
        '${green}Tip:$reset Los archivos $bold*.mocks.dart$reset se generan automáticamente —');
    print('     no los edites a mano ni los subas al repo (.gitignore los ignora).');
    print('');
  }
}
