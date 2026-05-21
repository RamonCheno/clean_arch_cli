import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/version.dart';

class UpdateCommand extends Command<void> {
  @override
  final name = 'update';

  @override
  final description = 'Actualiza cleanarch a la última versión disponible.';

  @override
  Future<void> run() async {
    Console.header('Actualizando cleanarch (versión actual: $cliVersion)');

    final result = Process.runSync(
      'dart',
      ['pub', 'global', 'activate', 'clean_arch_cli'],
      runInShell: true,
    );

    if (result.exitCode == 0) {
      Console.success('cleanarch actualizado correctamente.');
      Console.info('Reinicia la terminal para usar la nueva versión.');
    } else {
      Console.error('No se pudo actualizar automáticamente.');
      Console.info(
          'Ejecuta manualmente: dart pub global activate clean_arch_cli');
    }
  }
}
