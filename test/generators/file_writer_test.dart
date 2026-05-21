import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/file_writer.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_writer_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('FileWriter — modo normal', () {
    test('crea archivo y directorios intermedios', () {
      final path = p.join(tempDir.path, 'sub', 'dir', 'file.dart');
      FileWriter().write(path, 'content');
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsStringSync(), 'content');
    });

    test('no sobreescribe sin overwrite:true', () {
      final path = p.join(tempDir.path, 'file.dart');
      FileWriter().write(path, 'original');
      FileWriter().write(path, 'nuevo');
      expect(File(path).readAsStringSync(), 'original');
    });

    test('sobreescribe con overwrite:true', () {
      final path = p.join(tempDir.path, 'file.dart');
      FileWriter().write(path, 'original');
      FileWriter(overwrite: true).write(path, 'nuevo');
      expect(File(path).readAsStringSync(), 'nuevo');
    });
  });

  group('FileWriter — dry-run', () {
    test('no crea archivos en modo dry-run', () {
      final path = p.join(tempDir.path, 'dry', 'file.dart');
      FileWriter(dryRun: true).write(path, 'content');
      expect(File(path).existsSync(), isFalse);
    });

    test('createDir no crea directorios en dry-run', () {
      final dirPath = p.join(tempDir.path, 'dry_dir');
      FileWriter(dryRun: true).createDir(dirPath);
      expect(Directory(dirPath).existsSync(), isFalse);
    });
  });
}
