import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/generators/route_injector.dart';

void main() {
  late Directory tempDir;

  String pagesPath(String root) =>
      p.join(root, 'lib', 'app', 'routes', 'app_pages.dart');
  String routesPath(String root) =>
      p.join(root, 'lib', 'app', 'routes', 'app_routes.dart');

  void createRouteFiles(String root,
      {String pages = '', String routes = ''}) {
    File(pagesPath(root)).parent.createSync(recursive: true);
    File(pagesPath(root)).writeAsStringSync(pages);
    File(routesPath(root)).writeAsStringSync(routes);
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('route_injector_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('injectModule', () {
    test('inyecta imports package: no relativos', () {
      createRouteFiles(
        tempDir.path,
        pages: "// cleanarch:import\n// cleanarch:inject\n",
        routes: "// cleanarch:route\n",
      );

      RouteInjector.injectModule(tempDir.path, 'auth', 'Auth',
          packageName: 'my_app');

      final content = File(pagesPath(tempDir.path)).readAsStringSync();
      expect(content,
          contains("import 'package:my_app/app/modules/auth/views/auth_view.dart'"));
      expect(content,
          contains("import 'package:my_app/app/modules/auth/bindings/auth_binding.dart'"));
      expect(content, isNot(contains("import '../")));
    });

    test('detecta duplicado y no re-inyecta', () {
      final existing =
          "import 'package:my_app/app/modules/auth/views/auth_view.dart';\n"
          "// cleanarch:inject\n";
      createRouteFiles(tempDir.path, pages: existing, routes: "// cleanarch:route\n");

      final result = RouteInjector.injectModule(tempDir.path, 'auth', 'Auth',
          packageName: 'my_app');
      expect(result, isTrue);
      final content = File(pagesPath(tempDir.path)).readAsStringSync();
      // El import sigue siendo uno solo
      expect(
          'package:my_app/app/modules/auth/views/auth_view.dart'
              .allMatches(content)
              .length,
          1);
    });
  });

  group('injectFeature', () {
    test('inyecta imports package: para features', () {
      createRouteFiles(
        tempDir.path,
        pages: "// cleanarch:import\n// cleanarch:inject\n",
        routes: "// cleanarch:route\n",
      );

      RouteInjector.injectFeature(tempDir.path, 'dashboard', 'Dashboard',
          packageName: 'my_app');

      final content = File(pagesPath(tempDir.path)).readAsStringSync();
      expect(content,
          contains("import 'package:my_app/app/features/dashboard/views/dashboard_view.dart'"));
    });
  });

  group('injectScreen', () {
    test('inyecta screen standalone con package:', () {
      createRouteFiles(
        tempDir.path,
        pages: "// cleanarch:import\n// cleanarch:inject\n",
        routes: "// cleanarch:route\n",
      );

      RouteInjector.injectScreen(tempDir.path, 'login', 'Login',
          packageName: 'my_app');

      final content = File(pagesPath(tempDir.path)).readAsStringSync();
      expect(content,
          contains("import 'package:my_app/app/screens/login/views/login_screen.dart'"));
    });

    test('inyecta screen dentro de módulo padre con package:', () {
      createRouteFiles(
        tempDir.path,
        pages: "// cleanarch:import\n// cleanarch:inject:auth\n",
        routes: "// cleanarch:route\n",
      );

      RouteInjector.injectScreen(tempDir.path, 'register', 'Register',
          parentModule: 'auth', packageName: 'my_app');

      final content = File(pagesPath(tempDir.path)).readAsStringSync();
      expect(content,
          contains("import 'package:my_app/app/modules/auth/screens/register/views/register_screen.dart'"));
    });
  });
}
