import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/bundles/widget_bundle.dart';
import 'package:clean_arch_cli/src/generators/mason_target.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/project_utils.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class WidgetGenerator {
  final bool _overwrite;
  final bool _dryRun;

  WidgetGenerator({bool overwrite = false, bool dryRun = false})
      : _overwrite = overwrite,
        _dryRun = dryRun;

  /// [widgetName]    — nombre en snake_case o cualquier formato
  /// [projectRoot]   — raíz del proyecto Flutter
  /// [isGlobal]      — true → core/widgets/  |  false → modules/<module>/widgets/
  /// [parentModule]  — nombre del módulo padre (solo si isGlobal == false)
  /// [isStateful]    — genera StatefulWidget si true, StatelessWidget si false
  Future<void> generate(
    String widgetName,
    String projectRoot, {
    bool isGlobal = false,
    String? parentModule,
    bool isStateful = false,
    String? packageName,
  }) async {
    final pkgName = packageName ?? readPackageName(projectRoot);
    final name = widgetName.toSnakeCase();
    final pascal = name.toPascalCase();

    Console.header('Generando widget: ${pascal}Widget');

    // ── Determinar directorio destino ────────────────────────────────────────
    final String targetDir;
    if (isGlobal) {
      targetDir = p.join(projectRoot, 'lib', 'app', 'core', 'widgets');
    } else {
      if (parentModule == null || parentModule.isEmpty) {
        Console.error('Debes especificar --module cuando no usas --global.');
        exit(1);
      }
      final mod = parentModule.toSnakeCase();
      targetDir = p.join(projectRoot, 'lib', 'app', 'modules', mod, 'widgets');
    }

    final targetFile = p.join(targetDir, '${name}_widget.dart');

    if (!_dryRun && File(targetFile).existsSync() && !_overwrite) {
      Console.warning('El widget "${pascal}Widget" ya existe en $targetDir — '
          'usa --overwrite para sobreescribir.');
      return;
    }

    // ── Generar con Mason (escribe en lib/app/ temporalmente) ────────────────
    // El brick genera el archivo en lib/app/{{name}}_widget.dart.
    // Usamos un directorio temporal y luego movemos al destino correcto.
    final tempRoot = Directory.systemTemp.createTempSync('widget_gen_');
    try {
      final generator = await MasonGenerator.fromBundle(widgetBundle);
      await generator.generate(
        MasonTarget(tempRoot.path, dryRun: false),
        vars: {
          'name': name,
          'package_name': pkgName,
          'is_stateful': isStateful,
          'is_global': isGlobal,
          'parent_module': parentModule ?? '',
        },
      );

      final generatedFile = File(
        p.join(tempRoot.path, 'lib', 'app', '${name}_widget.dart'),
      );

      if (_dryRun) {
        Console.dryRun(targetFile);
      } else {
        Directory(targetDir).createSync(recursive: true);
        generatedFile.copySync(targetFile);
        Console.created(targetFile);
      }
    } finally {
      tempRoot.deleteSync(recursive: true);
    }

    // ── Resultado ────────────────────────────────────────────────────────────
    final location = isGlobal
        ? 'core/widgets/'
        : 'modules/${parentModule?.toSnakeCase()}/widgets/';

    Console.success('Widget "${pascal}Widget" generado en lib/app/$location');
    Console.info('  Tipo: ${isStateful ? 'StatefulWidget' : 'StatelessWidget'}');
  }
}
