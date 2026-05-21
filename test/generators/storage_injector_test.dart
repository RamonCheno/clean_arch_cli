import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/storage_injector.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Directory _makeProject(Directory base) {
  final bindingDir = Directory(p.join(base.path, 'lib', 'app', 'core', 'bindings'));
  bindingDir.createSync(recursive: true);
  File(p.join(bindingDir.path, 'initial_binding.dart')).writeAsStringSync('''
import 'package:get/get.dart';
// cleanarch:import
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // cleanarch:service
  }
}
''');
  return base;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('storage_injector_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('StorageInjector.injectApiService', () {
    test('inyecta import y registro en initial_binding.dart', () {
      _makeProject(tempDir);
      final result = StorageInjector.injectApiService(
        tempDir.path, 'get_connect', packageName: 'my_app',
      );
      expect(result, isTrue);
      final content = File(p.join(tempDir.path, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart'))
          .readAsStringSync();
      expect(content.contains('ApiService'), isTrue, reason: 'Debe registrar ApiService');
      expect(content.contains("import 'package:my_app/"), isTrue, reason: 'Debe tener import package:');
    });

    test('no duplica si ya está registrado', () {
      _makeProject(tempDir);
      StorageInjector.injectApiService(tempDir.path, 'get_connect', packageName: 'my_app');
      StorageInjector.injectApiService(tempDir.path, 'get_connect', packageName: 'my_app');
      final content = File(p.join(tempDir.path, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart'))
          .readAsStringSync();
      // Cuenta cuántas veces aparece el registro
      final count = 'ApiService'.allMatches(content).length;
      expect(count, lessThanOrEqualTo(3), reason: 'No debe duplicar registros');
    });

    test('retorna false si no existe initial_binding.dart', () {
      final result = StorageInjector.injectApiService(
        tempDir.path, 'get_connect', packageName: 'my_app',
      );
      expect(result, isFalse);
    });
  });

  group('StorageInjector.injectStorageService', () {
    test('inyecta DatabaseService para get_storage', () {
      _makeProject(tempDir);
      final result = StorageInjector.injectStorageService(
        tempDir.path, 'get_storage', packageName: 'my_app',
      );
      expect(result, isTrue);
      final content = File(p.join(tempDir.path, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart'))
          .readAsStringSync();
      expect(content.contains('DatabaseService'), isTrue);
    });

    test('inyecta DatabaseService para hive', () {
      _makeProject(tempDir);
      StorageInjector.injectStorageService(tempDir.path, 'hive', packageName: 'my_app');
      final content = File(p.join(tempDir.path, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart'))
          .readAsStringSync();
      expect(content.contains('DatabaseService'), isTrue);
    });

    test('no duplica si ya está registrado', () {
      _makeProject(tempDir);
      StorageInjector.injectStorageService(tempDir.path, 'get_storage', packageName: 'my_app');
      StorageInjector.injectStorageService(tempDir.path, 'get_storage', packageName: 'my_app');
      final content = File(p.join(tempDir.path, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart'))
          .readAsStringSync();
      final count = RegExp(r'Get\.put').allMatches(content).length;
      expect(count, equals(1), reason: 'Solo debe haber un Get.put');
    });
  });
}
