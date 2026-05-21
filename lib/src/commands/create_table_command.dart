import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/table_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateTableCommand extends Command<void> {
  @override
  final name = 'table';

  @override
  final description =
      'Genera una tabla Drift con su DAO (CRUD completo) e inyecta en AppDatabase y DatabaseService.';

  @override
  List<String> get aliases => ['tbl'];

  @override
  String get invocation =>
      '${runner!.executableName} create table <nombre> [--path <ruta>]';

  CreateTableCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter (donde está pubspec.yaml)',
        defaultsTo: '.',
      )
      ..addFlag(
        'dry-run',
        help: 'Muestra los archivos que se generarían sin crearlos',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    String? tableName;
    final projectRoot = argResults!['path'] as String;
    final dryRun = argResults!['dry-run'] as bool;

    if (argResults!.rest.isNotEmpty) {
      tableName = argResults!.rest.first;
    }

    if (tableName == null || tableName.isEmpty) {
      tableName = Console.prompt('Nombre de la tabla (singular, ej: tarea)');
      if (tableName == null || tableName.isEmpty) {
        Console.error('El nombre de la tabla no puede estar vacío.');
        exit(1);
      }
    }

    if (!tableName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$tableName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta del proyecto.');
      exit(1);
    }

    if (dryRun) {
      await TableGenerator(dryRun: true).generate(tableName, projectRoot);
      if (!Console.confirmDryRun()) {
        Console.info('Operación cancelada.');
        return;
      }
    }
    await TableGenerator(dryRun: false).generate(tableName, projectRoot);
  }
}
