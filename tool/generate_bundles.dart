// Run this script to regenerate all Mason bundles after editing brick templates:
//   dart run tool/generate_bundles.dart
//
// Requires mason_cli: dart pub global activate mason_cli
import 'dart:io';

const _bricks = [
  'feature',
  'controller',
  'screen',
  'module',
  'widget',
  'test_module',
  'test_feature',
];

Future<void> main() async {
  final root = Directory.current.path;
  final bricksDir = '$root/bricks';
  final outputDir = '$root/lib/src/bundles';

  Directory(outputDir).createSync(recursive: true);

  for (final brick in _bricks) {
    stdout.write('Bundling $brick... ');
    final result = await Process.run(
      'mason',
      ['bundle', '$bricksDir/$brick', '--type', 'dart', '--output-dir', outputDir],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      stdout.writeln('OK');
    } else {
      stdout.writeln('FAILED');
      stderr.writeln(result.stderr);
      exitCode = 1;
    }
  }

  if (exitCode == 0) {
    stdout.writeln('\nAll bundles generated in $outputDir');
  }
}
