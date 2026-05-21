import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/widget_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateWidgetCommand extends Command<void> {
  @override
  final name = 'widget';

  @override
  final description =
      'Genera un widget Flutter (StatelessWidget o StatefulWidget).';

  @override
  String get invocation =>
      '${runner!.executableName} create widget <nombre> [opciones]';

  CreateWidgetCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter',
        defaultsTo: '.',
      )
      ..addFlag(
        'global',
        abbr: 'g',
        help: 'Widget global → lib/app/core/widgets/',
        negatable: false,
      )
      ..addOption(
        'module',
        abbr: 'm',
        help: 'Módulo al que pertenece el widget → lib/app/modules/<módulo>/widgets/',
      )
      ..addFlag(
        'stateful',
        abbr: 's',
        help: 'Genera un StatefulWidget en lugar de StatelessWidget',
        negatable: false,
      )
      ..addFlag(
        'overwrite',
        abbr: 'f',
        help: 'Sobreescribir si el archivo ya existe',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Muestra el archivo que se generaría sin crearlo',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    String? widgetName;
    final projectRoot = argResults!['path'] as String;
    final isGlobal = argResults!['global'] as bool;
    final parentModule = argResults!['module'] as String?;
    final isStateful = argResults!['stateful'] as bool;
    final overwrite = argResults!['overwrite'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    if (argResults!.rest.isNotEmpty) {
      widgetName = argResults!.rest.first;
    }

    widgetName ??= Console.prompt('Nombre del widget');

    if (widgetName == null || widgetName.isEmpty) {
      Console.error('El nombre del widget no puede estar vacío.');
      exit(1);
    }

    if (!widgetName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$widgetName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    if (!isGlobal && (parentModule == null || parentModule.isEmpty)) {
      Console.error(
          'Especifica --global para un widget global, o --module <nombre> para un widget de módulo.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta.');
      exit(1);
    }

    if (dryRun) {
      await WidgetGenerator(overwrite: overwrite, dryRun: true).generate(
        widgetName, projectRoot,
        isGlobal: isGlobal, parentModule: parentModule, isStateful: isStateful,
      );
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await WidgetGenerator(overwrite: overwrite, dryRun: false).generate(
      widgetName, projectRoot,
      isGlobal: isGlobal, parentModule: parentModule, isStateful: isStateful,
    );
  }
}
