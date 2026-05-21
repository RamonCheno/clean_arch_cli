import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:clean_arch_cli/src/commands/create_command.dart';
import 'package:clean_arch_cli/src/commands/update_command.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/version.dart';

class _CompletionRunner extends CompletionCommandRunner<void> {
  _CompletionRunner(super.executableName, super.description);
}

class CleanArchRunner {
  static const _executableName = 'cleanarch';
  static const _description = 'CLI para generar proyectos Flutter con Clean Architecture + GetX\n'
      'Desarrollado por RamonChenoDev';

  late final CommandRunner<void> _runner;
  bool _verbose = false;

  CleanArchRunner() {
    _runner = _CompletionRunner(_executableName, _description)
      ..argParser.addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Muestra la versión del CLI.',
      )
      ..argParser.addFlag(
        'verbose',
        abbr: 'V',
        negatable: false,
        help: 'Muestra el stack trace completo en caso de error.',
      )
      ..argParser.addFlag(
        'quiet',
        abbr: 'q',
        negatable: false,
        help: 'Suprime la salida informativa (solo errores y resultado final).',
      );

    _runner.addCommand(CreateCommand());
    _runner.addCommand(UpdateCommand());
  }

  Future<void> run(List<String> args) async {
    try {
      _verbose = args.contains('--verbose') || args.contains('-V');
      final quiet = args.contains('--quiet') || args.contains('-q');
      if (quiet) {
        Console.setQuiet(true);
      }

      // --version / -v
      if (args.isNotEmpty && (args.contains('--version') || args.contains('-v'))) {
        _printBanner();
        Console.info('cleanarch versión $cliVersion');
        exit(0);
      }

      // --help / -h / sin argumentos → ayuda personalizada completa
      if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
        _printBanner();
        _printHelp();
        exit(0);
      }

      await _runner.run(args);
    } on UsageException catch (e) {
      Console.error(e.message);
      print('');
      print(e.usage);
      exit(64);
    } catch (e, stackTrace) {
      Console.error('Error inesperado: $e');
      if (_verbose) {
        print(stackTrace);
      }
      exit(1);
    }
  }

  void _printBanner() {
    const cyan = '\x1B[36m';
    const bold = '\x1B[1m';
    const reset = '\x1B[0m';
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';

    print('');
    print('$cyan$bold'
        r'''
  ____ _                      _             _
 / ___| | ___  __ _ _ __     / \   _ __ ___| |__
| |   | |/ _ \/ _` | '_ \  / _ \ | '__/ __| '_ \
| |___| |  __/ (_| | | | |/ ___ \| | | (__| | | |
 \____|_|\___|\__,_|_| |_/_/   \_\_|  \___|_| |_|
'''
        '$reset');
    print('$yellow$bold  Flutter Clean Architecture + GetX Generator v$cliVersion$reset');
    print('$green  by RamonChenoDev$reset');
    print('');
  }

  void _printHelp() {
    const bold = '\x1B[1m';
    const reset = '\x1B[0m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';
    const green = '\x1B[32m';

    // ── Uso ────────────────────────────────────────────────────────────────
    print('${bold}Uso:$reset');
    print('  cleanarch <comando> [argumentos]');
    print('');

    // ── Comandos ───────────────────────────────────────────────────────────
    print('$cyan${bold}Comandos disponibles:$reset');
    print('');

    print('  ${bold}Proyecto$reset');
    print('  ${yellow}create project$reset  <nombre>          '
        '${gray}Crea un nuevo proyecto Flutter con Clean Architecture + GetX$reset');
    print('');

    print('  ${bold}Módulos y Features$reset');
    print('  ${yellow}create module$reset   <nombre>          '
        '${gray}Genera un módulo completo (usecase, repo, controller, view, binding)$reset');
    print('  ${yellow}create feature$reset  <nombre>          '
        '${gray}Genera una feature simplificada (controller, view, binding)$reset');
    print('');

    print('  ${bold}Componentes individuales$reset');
    print('  ${yellow}create screen$reset      <nombre>       '
        '${gray}Agrega una pantalla a un módulo o feature existente$reset');
    print('  $gray  alias: create page$reset');
    print('  ${yellow}create controller$reset  <nombre>       '
        '${gray}Genera solo un controlador GetX$reset');
    print('  $gray  alias: create ctrl$reset');
    print('  ${yellow}create widget$reset      <nombre>       '
        '${gray}Genera un widget (global o por módulo)$reset');
    print('');

    print('  ${bold}Base de datos (Drift)$reset');
    print('  ${yellow}create table$reset    <nombre>          '
        '${gray}Genera tabla Drift + DAO con CRUD e inyecta en AppDatabase y DatabaseService$reset');
    print('  $gray  alias: create tbl$reset');
    print('');

    print('  ${bold}Pruebas$reset');
    print('  ${yellow}create test$reset     <nombre>          '
        '${gray}Genera archivos de prueba para un módulo o feature$reset');
    print('');

    // ── Opciones ───────────────────────────────────────────────────────────
    print('$cyan${bold}Opciones globales:$reset');
    print('  $yellow-h, --help$reset       Muestra esta ayuda');
    print('  $yellow-v, --version$reset    Muestra la versión del CLI');
    print('');

    // ── Ejemplos ───────────────────────────────────────────────────────────
    print('$cyan${bold}Ejemplos:$reset');
    print('  $green\$ cleanarch create project mi_app$reset');
    print('  $green\$ cleanarch create project mi_app --platforms android,ios,web$reset');
    print('  $green\$ cleanarch create project mi_app -i$reset'
        '                   $gray# modo interactivo$reset');
    print('');
    print('  $green\$ cleanarch create module auth$reset');
    print('  $green\$ cleanarch create feature dashboard$reset');
    print('  $green\$ cleanarch create screen login --module auth$reset');
    print('  $green\$ cleanarch create controller settings$reset');
    print('  $green\$ cleanarch create widget app_button --global$reset');
    print('  $green\$ cleanarch create widget home_card --module home$reset');
    print('  $green\$ cleanarch create widget counter --module home --stateful$reset');
    print('');
    print('  $green\$ cleanarch create table tarea$reset');
    print('  $green\$ cleanarch create table categoria --path ./mi_app$reset');
    print('');
    print('  $green\$ cleanarch create test auth$reset');
    print('  $green\$ cleanarch create test dashboard --feature --type controller$reset');
    print('');

    // ── Más ayuda ─────────────────────────────────────────────────────────
    print('${gray}Más ayuda sobre cada comando:$reset');
    print('  cleanarch help create project');
    print('  cleanarch help create module');
    print('  cleanarch help create feature');
    print('  cleanarch help create screen');
    print('  cleanarch help create controller');
    print('  cleanarch help create table');
    print('  cleanarch help create test');
    print('');
  }
}
