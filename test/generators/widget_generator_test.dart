import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/widget_generator.dart';

void _setupFakeProject(Directory root, String pkgName) {
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: $pkgName
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
  // Carpeta widgets del módulo home
  Directory(p.join(root.path, 'lib', 'app', 'modules', 'home', 'widgets'))
      .createSync(recursive: true);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('widget_gen_test_');
    _setupFakeProject(tempDir, 'my_app');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── Widget global ──────────────────────────────────────────────────────────

  group('WidgetGenerator — global', () {
    test('genera archivo en core/widgets/', () async {
      await WidgetGenerator().generate(
        'app_button', tempDir.path, isGlobal: true,
      );
      final file = File(p.join(
          tempDir.path, 'lib', 'app', 'core', 'widgets', 'app_button_widget.dart'));
      expect(file.existsSync(), isTrue);
    });

    test('contiene StatelessWidget por defecto', () async {
      await WidgetGenerator().generate(
        'app_loader', tempDir.path, isGlobal: true,
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'core', 'widgets', 'app_loader_widget.dart'))
          .readAsStringSync();
      expect(content, contains('StatelessWidget'));
      expect(content, isNot(contains('StatefulWidget')));
    });

    test('contiene StatefulWidget con --stateful', () async {
      await WidgetGenerator().generate(
        'animated_btn', tempDir.path, isGlobal: true, isStateful: true,
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'core', 'widgets', 'animated_btn_widget.dart'))
          .readAsStringSync();
      expect(content, contains('StatefulWidget'));
      expect(content, contains('State<AnimatedBtnWidget>'));
    });

    test('nombre en PascalCase correcto', () async {
      await WidgetGenerator().generate(
        'my_custom_card', tempDir.path, isGlobal: true,
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'core', 'widgets', 'my_custom_card_widget.dart'))
          .readAsStringSync();
      expect(content, contains('MyCustomCardWidget'));
    });

    test('no tiene extensión .mustache', () async {
      await WidgetGenerator().generate(
        'test_widget_name', tempDir.path, isGlobal: true,
      );
      final withMustache = File(p.join(
          tempDir.path, 'lib', 'app', 'core', 'widgets', 'test_widget_name_widget.dart.mustache'));
      expect(withMustache.existsSync(), isFalse);
    });

    test('archivo no está vacío', () async {
      await WidgetGenerator().generate(
        'empty_check', tempDir.path, isGlobal: true,
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'core', 'widgets', 'empty_check_widget.dart'))
          .readAsStringSync();
      expect(content.trim(), isNotEmpty);
    });
  });

  // ── Widget por módulo ──────────────────────────────────────────────────────

  group('WidgetGenerator — por módulo', () {
    test('genera archivo en modules/<mod>/widgets/', () async {
      await WidgetGenerator().generate(
        'home_card', tempDir.path, isGlobal: false, parentModule: 'home',
      );
      final file = File(p.join(
          tempDir.path, 'lib', 'app', 'modules', 'home', 'widgets', 'home_card_widget.dart'));
      expect(file.existsSync(), isTrue);
    });

    test('StatelessWidget por defecto en módulo', () async {
      await WidgetGenerator().generate(
        'product_tile', tempDir.path, isGlobal: false, parentModule: 'home',
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'modules', 'home', 'widgets', 'product_tile_widget.dart'))
          .readAsStringSync();
      expect(content, contains('StatelessWidget'));
    });

    test('StatefulWidget en módulo', () async {
      await WidgetGenerator().generate(
        'counter_box', tempDir.path,
        isGlobal: false, parentModule: 'home', isStateful: true,
      );
      final content = File(p.join(
              tempDir.path, 'lib', 'app', 'modules', 'home', 'widgets', 'counter_box_widget.dart'))
          .readAsStringSync();
      expect(content, contains('StatefulWidget'));
    });

    test('crea carpeta widgets si no existe', () async {
      await WidgetGenerator().generate(
        'auth_header', tempDir.path, isGlobal: false, parentModule: 'auth',
      );
      final dir = Directory(
          p.join(tempDir.path, 'lib', 'app', 'modules', 'auth', 'widgets'));
      expect(dir.existsSync(), isTrue);
    });
  });

  // ── Dry-run ────────────────────────────────────────────────────────────────

  group('WidgetGenerator — dry-run', () {
    test('no crea archivo en dry-run', () async {
      await WidgetGenerator(dryRun: true).generate(
        'dry_widget', tempDir.path, isGlobal: true,
      );
      final file = File(p.join(
          tempDir.path, 'lib', 'app', 'core', 'widgets', 'dry_widget_widget.dart'));
      expect(file.existsSync(), isFalse);
    });
  });

  // ── No sobreescribe ────────────────────────────────────────────────────────

  group('WidgetGenerator — overwrite', () {
    test('no sobreescribe sin --overwrite', () async {
      await WidgetGenerator().generate(
        'btn', tempDir.path, isGlobal: true,
      );
      final file = File(p.join(
          tempDir.path, 'lib', 'app', 'core', 'widgets', 'btn_widget.dart'));
      file.writeAsStringSync('// manual content');

      await WidgetGenerator(overwrite: false).generate(
        'btn', tempDir.path, isGlobal: true,
      );
      expect(file.readAsStringSync(), '// manual content');
    });

    test('sobreescribe con --overwrite', () async {
      await WidgetGenerator().generate(
        'btn2', tempDir.path, isGlobal: true,
      );
      final file = File(p.join(
          tempDir.path, 'lib', 'app', 'core', 'widgets', 'btn2_widget.dart'));
      file.writeAsStringSync('// manual content');

      await WidgetGenerator(overwrite: true).generate(
        'btn2', tempDir.path, isGlobal: true,
      );
      expect(file.readAsStringSync(), isNot('// manual content'));
      expect(file.readAsStringSync(), contains('Btn2Widget'));
    });
  });
}
