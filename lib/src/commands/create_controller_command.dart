import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/controller_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateControllerCommand extends Command<void> {
  @override
  final name = 'controller';

  @override
  final aliases = ['ctrl'];

  @override
  final description =
      'Crea un GetxController dentro de un módulo o en controllers/.';

  @override
  String get invocation =>
      '${runner!.executableName} create controller [nombre] [--module <modulo>]';

  CreateControllerCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter',
        defaultsTo: '.',
      )
      ..addOption(
        'module',
        abbr: 'm',
        help: 'Módulo donde colocar el controlador (opcional)',
      )
      ..addFlag(
        'overwrite',
        abbr: 'f',
        help: 'Sobreescribir si ya existe',
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
    String? controllerName;
    final projectRoot = argResults!['path'] as String;
    final parentModule = argResults!['module'] as String?;
    final overwrite = argResults!['overwrite'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    if (argResults!.rest.isNotEmpty) {
      controllerName = argResults!.rest.first;
    }

    controllerName ??= Console.prompt('Nombre del controlador');

    if (controllerName == null || controllerName.isEmpty) {
      Console.error('El nombre del controlador no puede estar vacío.');
      exit(1);
    }

    // Quitar sufijo "Controller" si el usuario lo escribió
    final cleaned = controllerName
        .replaceAll(RegExp(r'[Cc]ontroller$'), '')
        .trim();
    final finalName = cleaned.isEmpty ? controllerName : cleaned;

    if (!finalName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$finalName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta.');
      exit(1);
    }

    if (dryRun) {
      await ControllerGenerator(overwrite: overwrite, dryRun: true)
          .generate(finalName, projectRoot, parentModule: parentModule);
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await ControllerGenerator(overwrite: overwrite, dryRun: false)
        .generate(finalName, projectRoot, parentModule: parentModule);
  }
}
