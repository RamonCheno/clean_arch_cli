import 'package:test/test.dart';
import 'package:clean_arch_cli/src/templates/service_templates.dart';
import 'package:clean_arch_cli/src/templates/module_templates.dart'
    show storageRuntimePackages, storageDevPackages, storageCompanionPackages;

void main() {
  // ── serviceClassName / serviceFileName ─────────────────────────────────────
  group('serviceClassName', () {
    test('database → DatabaseService', () => expect(serviceClassName('database'), 'DatabaseService'));
    test('settings → SettingsService', () => expect(serviceClassName('settings'), 'SettingsService'));
    test('cache    → CacheService',    () => expect(serviceClassName('cache'),    'CacheService'));
    test('secure   → SecureService',   () => expect(serviceClassName('secure'),   'SecureService'));
  });

  group('serviceFileName', () {
    test('database → database_service.dart', () => expect(serviceFileName('database'), 'database_service.dart'));
    test('settings → settings_service.dart', () => expect(serviceFileName('settings'), 'settings_service.dart'));
    test('cache    → cache_service.dart',    () => expect(serviceFileName('cache'),    'cache_service.dart'));
    test('secure   → secure_service.dart',   () => expect(serviceFileName('secure'),   'secure_service.dart'));
  });

  // ── storageServiceTemplate ──────────────────────────────────────────────────
  group('storageServiceTemplate — database', () {
    for (final lib in ['get_storage', 'hive', 'shared_prefs', 'secure_storage', 'sqflite', 'isar', 'drift']) {
      test('genera template para $lib', () {
        final tpl = storageServiceTemplate(lib);
        expect(tpl, isNotEmpty, reason: '$lib debe generar contenido');
        expect(tpl.contains('DatabaseService'), isTrue, reason: '$lib debe contener DatabaseService');
        expect(tpl.contains('class DatabaseService'), isTrue, reason: '$lib debe declarar la clase');
      });
    }
  });

  group('storageServiceTemplate — settings', () {
    for (final lib in ['get_storage', 'hive', 'shared_prefs', 'secure_storage']) {
      test('genera template settings para $lib', () {
        final tpl = storageServiceTemplate(lib, purpose: 'settings');
        expect(tpl.contains('SettingsService'), isTrue);
      });
    }
  });

  // ── apiServiceTemplate ──────────────────────────────────────────────────────
  group('apiServiceTemplate', () {
    test('get_connect genera ApiService con GetConnect', () {
      final tpl = apiServiceTemplate('get_connect', packageName: 'my_app');
      expect(tpl.contains('ApiService'), isTrue);
      expect(tpl.contains('GetConnect'), isTrue);
    });

    test('dio genera ApiService con Dio', () {
      final tpl = apiServiceTemplate('dio', packageName: 'my_app');
      expect(tpl.contains('ApiService'), isTrue);
      expect(tpl.contains('Dio'), isTrue);
    });
  });

  // ── apiServiceBindingEntry ──────────────────────────────────────────────────
  group('apiServiceBindingEntry', () {
    test('retorna import, registration, comment', () {
      final entry = apiServiceBindingEntry('get_connect', packageName: 'my_app');
      expect(entry.import, contains("import 'package:my_app/"));
      expect(entry.registration, contains('ApiService'));
      expect(entry.comment, isNotEmpty);
    });
  });

  // ── serviceBindingEntries ───────────────────────────────────────────────────
  group('serviceBindingEntries', () {
    test('get_storage retorna 1 entrada', () {
      final entries = serviceBindingEntries('get_storage', packageName: 'my_app');
      expect(entries, hasLength(1));
      expect(entries.first.registration, contains('DatabaseService'));
    });

    test('todas las entradas tienen import package:', () {
      for (final lib in ['get_storage', 'hive', 'shared_prefs', 'secure_storage']) {
        final entries = serviceBindingEntries(lib, packageName: 'my_app');
        for (final e in entries) {
          expect(e.import, contains("import 'package:my_app/"),
              reason: '$lib debe usar import package:');
        }
      }
    });
  });

  // ── storageRuntimePackages ──────────────────────────────────────────────────
  group('storageRuntimePackages', () {
    test('get_storage → {get_storage: ^2.1.1}', () {
      expect(storageRuntimePackages('get_storage'), equals({'get_storage': '^2.1.1'}));
    });
    test('hive → hive_flutter', () {
      expect(storageRuntimePackages('hive').keys, contains('hive_flutter'));
    });
    test('drift → solo drift (sin drift_sqflite hardcodeado)', () {
      final pkgs = storageRuntimePackages('drift');
      expect(pkgs.keys, contains('drift'));
      expect(pkgs.keys, isNot(contains('drift_sqflite')),
          reason: 'drift_sqflite se agrega via companion, no version fija');
    });
    test('isar → isar + isar_flutter_libs', () {
      final pkgs = storageRuntimePackages('isar');
      expect(pkgs.keys, containsAll(['isar', 'isar_flutter_libs']));
    });
  });

  // ── storageDevPackages ──────────────────────────────────────────────────────
  group('storageDevPackages', () {
    test('drift → drift_dev + build_runner', () {
      final pkgs = storageDevPackages('drift');
      expect(pkgs.keys, containsAll(['drift_dev', 'build_runner']));
    });
    test('isar → isar_generator + build_runner', () {
      final pkgs = storageDevPackages('isar');
      expect(pkgs.keys, containsAll(['isar_generator', 'build_runner']));
    });
    test('get_storage → sin dev packages', () {
      expect(storageDevPackages('get_storage'), isEmpty);
    });
  });

  // ── storageCompanionPackages ────────────────────────────────────────────────
  group('storageCompanionPackages', () {
    test('drift → [drift_sqflite]', () {
      expect(storageCompanionPackages('drift'), equals(['drift_sqflite']));
    });
    test('get_storage → []', () {
      expect(storageCompanionPackages('get_storage'), isEmpty);
    });
    test('hive → []', () {
      expect(storageCompanionPackages('hive'), isEmpty);
    });
  });
}
