import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/feature_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateFeatureCommand extends Command<void> {
  @override
  final name = 'feature';

  @override
  final description =
      'Crea un feature ligero (vista + controlador + binding) sin capas domain/data.';

  @override
  String get invocation =>
      '${runner!.executableName} create feature [nombre]';

  CreateFeatureCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter',
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
      );
  }

  @override
  Future<void> run() async {
    String? featureName;
    final projectRoot = argResults!['path'] as String;
    final overwrite = argResults!['overwrite'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    if (argResults!.rest.isNotEmpty) {
      featureName = argResults!.rest.first;
    }

    featureName ??= Console.prompt('Nombre del feature');

    if (featureName == null || featureName.isEmpty) {
      Console.error('El nombre del feature no puede estar vacío.');
      exit(1);
    }

    if (!featureName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$featureName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta.');
      exit(1);
    }

    if (dryRun) {
      await FeatureGenerator(overwrite: overwrite, dryRun: true)
          .generate(featureName, projectRoot);
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await FeatureGenerator(overwrite: overwrite, dryRun: false)
        .generate(featureName, projectRoot);
  }
}
