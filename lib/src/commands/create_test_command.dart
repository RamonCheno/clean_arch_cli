import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/generators/test_generator.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/utils/string_ext.dart';

class CreateTestCommand extends Command<void> {
  @override
  final name = 'test';

  @override
  final description =
      'Genera archivos de prueba (unit tests y widget tests) para un módulo o feature.';

  @override
  String get invocation =>
      '${runner!.executableName} create test <nombre> [opciones]';

  CreateTestCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Tipo de test a generar.',
        allowed: ['all', 'controller', 'usecase', 'repository', 'widget'],
        allowedHelp: {
          'all': 'Genera todos los tests (por defecto)',
          'controller': 'Solo el test del controlador GetX',
          'usecase': 'Solo el test del use case (solo para módulos)',
          'repository': 'Solo el test del repositorio (solo para módulos)',
          'widget': 'Solo el widget test de la vista',
        },
        defaultsTo: 'all',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta raíz del proyecto Flutter (donde está pubspec.yaml)',
        defaultsTo: '.',
      )
      ..addFlag(
        'feature',
        abbr: 'f',
        help:
            'Genera tests para un feature (ligero) en lugar de un módulo completo.',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    String? targetName;
    final projectRoot = argResults!['path'] as String;
    final typeStr = argResults!['type'] as String;
    final isFeature = argResults!['feature'] as bool;

    if (argResults!.rest.isNotEmpty) {
      targetName = argResults!.rest.first;
    }

    if (targetName == null || targetName.isEmpty) {
      targetName = Console.prompt(
        isFeature ? 'Nombre del feature' : 'Nombre del módulo',
      );
      if (targetName == null || targetName.isEmpty) {
        Console.error('El nombre no puede estar vacío.');
        exit(1);
      }
    }

    if (!targetName.toSnakeCase().isValidIdentifier) {
      Console.error(
          'Nombre inválido: "$targetName". Use solo letras, números y guiones bajos.');
      exit(1);
    }

    final pubspec = File('$projectRoot/pubspec.yaml');
    if (!pubspec.existsSync()) {
      Console.error(
          'No se encontró pubspec.yaml en "$projectRoot". Verifica la ruta del proyecto.');
      exit(1);
    }

    final type = _parseType(typeStr);
    final gen = TestGenerator();

    if (isFeature) {
      await gen.generateForFeature(targetName, projectRoot, type: type);
    } else {
      await gen.generateForModule(targetName, projectRoot, type: type);
    }
  }

  TestType _parseType(String value) {
    switch (value) {
      case 'controller':
        return TestType.controller;
      case 'usecase':
        return TestType.usecase;
      case 'repository':
        return TestType.repository;
      case 'widget':
        return TestType.widget;
      default:
        return TestType.all;
    }
  }
}
