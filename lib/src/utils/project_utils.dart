import 'dart:io';
import 'package:path/path.dart' as p;

String readPackageName(String projectRoot) {
  final pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return 'your_app';
  for (final line in pubspec.readAsLinesSync()) {
    if (line.startsWith('name:')) return line.replaceFirst('name:', '').trim();
  }
  return 'your_app';
}

/// Detecta si el directorio tiene FVM configurado.
/// Busca `.fvm/fvm_config.json` o `.fvm/flutter_sdk`.
bool projectUsesFvm(String directory) =>
    File(p.join(directory, '.fvm', 'fvm_config.json')).existsSync() ||
    Directory(p.join(directory, '.fvm', 'flutter_sdk')).existsSync();
