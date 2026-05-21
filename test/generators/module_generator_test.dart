import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/module_generator.dart';

// ── Proyecto mínimo para tests de integración ────────────────────────────────

void _setupFakeProject(Directory root, String pkgName) {
  // pubspec.yaml
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: $pkgName
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

  // app_pages.dart con marcadores
  final routesDir = Directory(p.join(root.path, 'lib', 'app', 'routes'));
  routesDir.createSync(recursive: true);
  File(p.join(routesDir.path, 'app_pages.dart')).writeAsStringSync('''
import 'package:get/get.dart';
// cleanarch:import
abstract class AppPages {
  static final routes = [
    // cleanarch:inject
  ];
}
''');

  // app_routes.dart con marcador
  File(p.join(routesDir.path, 'app_routes.dart')).writeAsStringSync('''
abstract class Routes {
  // cleanarch:route
}
''');

  // initial_binding.dart con marcadores
  final bindingDir = Directory(p.join(root.path, 'lib', 'app', 'core', 'bindings'));
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<String> _allFiles(Directory dir) {
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll('\\', '/'))
      .toList();
}

bool _hasMustache(List<String> files) =>
    files.any((f) => f.endsWith('.mustache'));

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_gen_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Estructura de archivos generados ────────────────────────────────────────

  group('ModuleGenerator — estructura (datasource: rest)', () {
    late List<String> files;
    late String root;

    setUpAll(() async {
      final dir = Directory.systemTemp.createTempSync('mod_rest_');
      root = dir.path;
      _setupFakeProject(dir, 'test_app');
      await ModuleGenerator(dryRun: false).generate(
        'home', root, datasource: 'rest', packageName: 'test_app',
      );
      files = _allFiles(dir);
    });

    tearDownAll(() {
      final dir = Directory(root);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    // Ningún archivo con .mustache
    test('ningún archivo tiene extensión .mustache', () {
      expect(_hasMustache(files), isFalse,
          reason: 'Archivos con .mustache: ${files.where((f) => f.endsWith('.mustache')).toList()}');
    });

    // Domain
    test('genera home_entity.dart', () {
      expect(files.any((f) => f.endsWith('home_entity.dart')), isTrue);
    });
    test('genera home_repository.dart', () {
      expect(files.any((f) => f.endsWith('home_repository.dart')), isTrue);
    });
    test('genera get_all_homes_usecase.dart', () {
      expect(files.any((f) => f.endsWith('get_all_homes_usecase.dart')), isTrue);
    });
    test('genera get_home_by_id_usecase.dart', () {
      expect(files.any((f) => f.endsWith('get_home_by_id_usecase.dart')), isTrue);
    });

    // Data
    test('genera home_model.dart', () {
      expect(files.any((f) => f.endsWith('home_model.dart')), isTrue);
    });
    test('genera home_repository_impl.dart', () {
      expect(files.any((f) => f.endsWith('home_repository_impl.dart')), isTrue);
    });
    test('genera home_provider.dart', () {
      expect(files.any((f) => f.endsWith('home_provider.dart')), isTrue);
    });

    // Presentation
    test('genera home_controller.dart', () {
      expect(files.any((f) => f.endsWith('home_controller.dart')), isTrue);
    });
    test('genera home_binding.dart', () {
      expect(files.any((f) => f.endsWith('home_binding.dart')), isTrue);
    });
    test('genera home_view.dart', () {
      expect(files.any((f) => f.endsWith('home_view.dart')), isTrue);
    });

    // Widgets placeholder
    test('genera carpeta widgets con .gitkeep', () {
      expect(files.any((f) => f.contains('/modules/home/widgets/')), isTrue);
    });

    // Ningún archivo .dart vacío
    test('ningún archivo .dart está vacío', () {
      final dartFiles = files.where((f) => f.endsWith('.dart')).toList();
      expect(dartFiles, isNotEmpty, reason: 'Debe haber archivos .dart');
      final emptyFiles = dartFiles.where((f) => File(f).readAsStringSync().trim().isEmpty).toList();
      expect(emptyFiles, isEmpty,
          reason: 'Archivos vacíos encontrados: $emptyFiles');
    });
  });

  // ── Contenido de archivos generados ─────────────────────────────────────────

  group('ModuleGenerator — contenido correcto', () {
    late Directory dir;

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('mod_content_');
      _setupFakeProject(dir, 'my_app');
      await ModuleGenerator(dryRun: false).generate(
        'product', dir.path, datasource: 'rest', packageName: 'my_app',
      );
    });

    tearDownAll(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('entity contiene class ProductEntity', () {
      final f = File(p.join(dir.path, 'lib', 'app', 'domain', 'entities', 'product_entity.dart'));
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('ProductEntity'));
    });

    test('controller contiene class ProductController', () {
      final f = File(p.join(dir.path, 'lib', 'app', 'modules', 'product', 'controllers', 'product_controller.dart'));
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('ProductController'));
    });

    test('binding contiene class ProductBinding', () {
      final f = File(p.join(dir.path, 'lib', 'app', 'modules', 'product', 'bindings', 'product_binding.dart'));
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('ProductBinding'));
    });

    test('view contiene class ProductView', () {
      final f = File(p.join(dir.path, 'lib', 'app', 'modules', 'product', 'views', 'product_view.dart'));
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('ProductView'));
    });

    test('archivos usan imports package: (no relativos)', () {
      final binding = File(p.join(dir.path, 'lib', 'app', 'modules', 'product', 'bindings', 'product_binding.dart'));
      if (binding.existsSync()) {
        final content = binding.readAsStringSync();
        expect(content, isNot(contains("import '../")),
            reason: 'No debe tener imports relativos');
        expect(content, contains("import 'package:"),
            reason: 'Debe usar imports package:');
      }
    });
  });

  // ── Route injection ──────────────────────────────────────────────────────────

  group('ModuleGenerator — route injection', () {
    test('inyecta ruta en app_pages.dart con import package:', () async {
      _setupFakeProject(tempDir, 'my_app');
      await ModuleGenerator(dryRun: false).generate(
        'auth', tempDir.path, datasource: 'rest', packageName: 'my_app',
      );
      final pages = File(p.join(tempDir.path, 'lib', 'app', 'routes', 'app_pages.dart'))
          .readAsStringSync();
      expect(pages, contains("import 'package:my_app/app/modules/auth/views/auth_view.dart'"));
      expect(pages, contains('AuthView'));
      expect(pages, contains('AuthBinding'));
    });

    test('inyecta constante en app_routes.dart', () async {
      _setupFakeProject(tempDir, 'my_app');
      await ModuleGenerator(dryRun: false).generate(
        'auth', tempDir.path, datasource: 'rest', packageName: 'my_app',
      );
      final routes = File(p.join(tempDir.path, 'lib', 'app', 'routes', 'app_routes.dart'))
          .readAsStringSync();
      expect(routes, contains("static const auth = '/auth'"));
    });

    test('no inyecta duplicados en segunda ejecución', () async {
      _setupFakeProject(tempDir, 'my_app');
      await ModuleGenerator(dryRun: false).generate(
        'auth', tempDir.path, datasource: 'rest', packageName: 'my_app',
      );
      await ModuleGenerator(dryRun: false).generate(
        'auth', tempDir.path, datasource: 'rest', packageName: 'my_app',
      );
      final pages = File(p.join(tempDir.path, 'lib', 'app', 'routes', 'app_pages.dart'))
          .readAsStringSync();
      final count = 'AuthView'.allMatches(pages).length;
      expect(count, equals(1), reason: 'AuthView no debe duplicarse');
    });
  });

  // ── Dry-run ──────────────────────────────────────────────────────────────────

  group('ModuleGenerator — dry-run', () {
    test('no crea archivos en modo dry-run', () async {
      _setupFakeProject(tempDir, 'my_app');
      final libDir = Directory(p.join(tempDir.path, 'lib', 'app', 'domain'));
      await ModuleGenerator(dryRun: true).generate(
        'home', tempDir.path, datasource: 'rest', packageName: 'my_app',
      );
      expect(libDir.existsSync(), isFalse,
          reason: 'No debe crear archivos en dry-run');
    });
  });

  // ── Datasource: local ────────────────────────────────────────────────────────

  group('ModuleGenerator — datasource local', () {
    test('genera archivos correctamente con local + get_storage', () async {
      _setupFakeProject(tempDir, 'my_app');
      await ModuleGenerator(dryRun: false).generate(
        'note', tempDir.path,
        datasource: 'local',
        storageLib: 'get_storage',
        packageName: 'my_app',
      );
      final files = _allFiles(tempDir);
      expect(_hasMustache(files), isFalse);
      expect(files.any((f) => f.endsWith('note_entity.dart')), isTrue);
      expect(files.any((f) => f.endsWith('note_controller.dart')), isTrue);
    });
  });
}
