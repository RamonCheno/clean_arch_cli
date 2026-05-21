import 'package:args/command_runner.dart';
import 'package:clean_arch_cli/src/commands/create_controller_command.dart';
import 'package:clean_arch_cli/src/commands/create_feature_command.dart';
import 'package:clean_arch_cli/src/commands/create_module_command.dart';
import 'package:clean_arch_cli/src/commands/create_project_command.dart';
import 'package:clean_arch_cli/src/commands/create_screen_command.dart';
import 'package:clean_arch_cli/src/commands/create_table_command.dart';
import 'package:clean_arch_cli/src/commands/create_test_command.dart';
import 'package:clean_arch_cli/src/commands/create_widget_command.dart';

class CreateCommand extends Command<void> {
  @override
  final name = 'create';

  @override
  final description =
      'Crea proyectos, módulos, features, screens, controladores, widgets, tablas o tests con Clean Architecture + GetX.';

  CreateCommand() {
    addSubcommand(CreateProjectCommand());
    addSubcommand(CreateModuleCommand());
    addSubcommand(CreateFeatureCommand());
    addSubcommand(CreateScreenCommand());
    addSubcommand(CreateControllerCommand());
    addSubcommand(CreateWidgetCommand());
    addSubcommand(CreateTableCommand());
    addSubcommand(CreateTestCommand());
  }

  @override
  Future<void> run() async {
    printUsage();
  }
}
