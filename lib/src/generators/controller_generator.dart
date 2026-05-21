import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/bundles/controller_bundle.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

/// Genera únicamente un GetxController.
class ControllerGenerator {
  final bool _overwrite;
  final bool _dryRun;

  ControllerGenerator({bool overwrite = false, bool dryRun = false})
      : _overwrite = overwrite,
        _dryRun = dryRun;

  Future<void> generate(String controllerName, String projectRoot,
      {String? parentModule}) async {
    final name = controllerName.toSnakeCase();
    final pascal = name.toPascalCase();

    Console.header('Creando controlador: ${pascal}Controller');

    final String outputDir;
    if (parentModule != null && parentModule.isNotEmpty) {
      final mod = parentModule.toSnakeCase();
      outputDir =
          p.join(projectRoot, 'lib', 'app', 'modules', mod, 'controllers');
    } else {
      outputDir = p.join(projectRoot, 'lib', 'app', 'controllers');
    }

    Console.step(1, 'Generando archivo');
    final generator = await MasonGenerator.fromBundle(controllerBundle);
    await generator.generate(
      MasonTarget(outputDir, overwrite: _overwrite, dryRun: _dryRun),
      vars: {'name': name},
    );

    if (!_dryRun) {
      final filePath = p.join(outputDir, '${name}_controller.dart');
      Console.success('${pascal}Controller creado en $filePath');
      Console.info('');
      Console.info('Úsalo en un binding:');
      Console.info(
          '  Get.lazyPut<${pascal}Controller>(() => ${pascal}Controller());');
      Console.info('');
    }
  }
}
