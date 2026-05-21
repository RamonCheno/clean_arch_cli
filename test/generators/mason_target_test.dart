import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/mason_target.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mason_target_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('MasonTarget — strip .mustache', () {
    test('elimina extensión .mustache del path', () async {
      final target = MasonTarget(tempDir.path);
      await target.createFile(
        'lib/app/domain/entities/home_entity.dart.mustache',
        'class HomeEntity {}'.codeUnits,
      );
      final expected = File(p.join(tempDir.path, 'lib', 'app', 'domain', 'entities', 'home_entity.dart'));
      expect(expected.existsSync(), isTrue, reason: 'Debe existir sin .mustache');
      final withMustache = File(p.join(tempDir.path, 'lib', 'app', 'domain', 'entities', 'home_entity.dart.mustache'));
      expect(withMustache.existsSync(), isFalse, reason: 'No debe existir con .mustache');
    });

    test('archivos sin .mustache se escriben normal', () async {
      final target = MasonTarget(tempDir.path);
      await target.createFile('lib/main.dart', 'void main() {}'.codeUnits);
      expect(File(p.join(tempDir.path, 'lib', 'main.dart')).existsSync(), isTrue);
    });

    test('crea directorios intermedios automáticamente', () async {
      final target = MasonTarget(tempDir.path);
      await target.createFile('a/b/c/d/file.dart.mustache', 'content'.codeUnits);
      expect(File(p.join(tempDir.path, 'a', 'b', 'c', 'd', 'file.dart')).existsSync(), isTrue);
    });

    test('dry-run no crea archivos', () async {
      final target = MasonTarget(tempDir.path, dryRun: true);
      await target.createFile('lib/home.dart.mustache', 'content'.codeUnits);
      expect(File(p.join(tempDir.path, 'lib', 'home.dart')).existsSync(), isFalse);
    });

    test('no sobreescribe sin overwrite:true', () async {
      final path = p.join(tempDir.path, 'lib', 'file.dart');
      File(path).parent.createSync(recursive: true);
      File(path).writeAsStringSync('original');

      final target = MasonTarget(tempDir.path, overwrite: false);
      await target.createFile('lib/file.dart', 'nuevo'.codeUnits);
      expect(File(path).readAsStringSync(), 'original');
    });

    test('sobreescribe con overwrite:true', () async {
      final path = p.join(tempDir.path, 'lib', 'file.dart');
      File(path).parent.createSync(recursive: true);
      File(path).writeAsStringSync('original');

      final target = MasonTarget(tempDir.path, overwrite: true);
      await target.createFile('lib/file.dart', 'nuevo'.codeUnits);
      expect(File(path).readAsStringSync(), 'nuevo');
    });
  });
}
