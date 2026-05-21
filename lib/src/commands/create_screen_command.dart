import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/screen_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateScreenCommand extends Command<void> {
  @override
  final name = 'screen';

  @override
  final aliases = ['page'];

  @override
  final description =
      'Crea una screen (vista + controlador + binding) dentro de un módulo o en screens/.';

  @override
  String get invocation =>
      '${runner!.executableName} create screen [nombre] [--module <modulo>]';

  CreateScreenCommand() {
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
        help: 'Módulo padre (ej: tasks) o módulo/screen padre (ej: tasks/add_task)',
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
    String? screenName;
    final projectRoot = argResults!['path'] as String;
    final parentModule = argResults!['module'] as String?;
    final overwrite = argResults!['overwrite'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    if (argResults!.rest.isNotEmpty) {
      screenName = argResults!.rest.first;
    }

    screenName ??= Console.prompt('Nombre de la screen');

    if (screenName == null || screenName.isEmpty) {
      Console.error('El nombre de la screen no puede estar vacío.');
      exit(1);
    }

    if (!screenName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$screenName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta.');
      exit(1);
    }

    if (dryRun) {
      await ScreenGenerator(overwrite: overwrite, dryRun: true)
          .generate(screenName, projectRoot, parentModule: parentModule);
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await ScreenGenerator(overwrite: overwrite, dryRun: false)
        .generate(screenName, projectRoot, parentModule: parentModule);
  }
}
