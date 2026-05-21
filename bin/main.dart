import 'dart:io';
import 'package:clean_arch_cli/src/runner.dart';

Future<void> main(List<String> arguments) async {
  await CleanArchRunner().run(arguments);
  exit(0);
}
