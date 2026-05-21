// Templates para los archivos globales del proyecto

String mainDartTemplate(
  String appName,
  String pascal, {
  String datasource = 'rest',
  String storageLib = '',
}) {
  // Solo las libs cuyo AppDatabase expone static Future<void> init().
  // drift y sqflite NO tienen init() — se instancian directamente con su constructor.
  const initLibs = {
    'get_storage',
    'hive', 'hive_flutter',
    'shared_prefs', 'shared_preferences',
    'isar',
  };
  // Normaliza alias comunes que provienen del menú.
  String rawNorm(String lib) {
    if (lib == 'flutter_secure_storage') return 'secure_storage';
    return lib;
  }
  // Extrae SOLO la lib de propósito 'database' (la que genera AppDatabase).
  // Para dual "sp:settings,drift:database" devuelve 'drift'.
  // Para simple devuelve la lib directamente.
  // Esto evita llamar AppDatabase.init() cuando la lib de BD no tiene ese método.
  String dbLib(String lib) {
    if (lib.contains(',') && lib.contains(':')) {
      for (final part in lib.split(',')) {
        final chunks = part.split(':');
        if (chunks.length == 2 && chunks[1].trim() == 'database') {
          return rawNorm(chunks[0].trim());
        }
      }
      return rawNorm(lib.split(',').first.split(':').first.trim());
    }
    return rawNorm(lib.split(':').first.trim());
  }

  final primaryLib = storageLib.isEmpty ? '' : dbLib(storageLib);
  final needsDbInit = primaryLib.isNotEmpty &&
      (datasource == 'local' || datasource == 'both') &&
      initLibs.contains(primaryLib);
  final dbImport = needsDbInit
      ? "\nimport 'package:$appName/app/core/database/app_database.dart';"
      : '';
  final mainAsync = needsDbInit ? 'Future<void>' : 'void';
  final asyncKeyword = needsDbInit ? ' async' : '';
  final dbInitLine = needsDbInit
      ? '\n  // Inicializa la base de datos local ANTES de mostrar cualquier pantalla.\n  await AppDatabase.init();'
      : '';

  return '''
import 'package:flutter/material.dart';
import 'package:$appName/app/app.dart';$dbImport

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  main.dart — Punto de entrada de la aplicación                          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Cómo funciona Clean Architecture en este proyecto?
//
//   Piénsalo como una cebolla con capas. La capa del centro no sabe
//   nada de las capas de afuera. El flujo de datos va así:
//
//   [Vista] → [Controller] → [UseCase] → [Repository] → [Provider] → [API]
//      ↑______________________________________________|
//                    (datos de regreso)
//
// ¿Dónde vive cada cosa?
//   lib/app/domain/      → Las REGLAS del negocio (entidades, contratos, casos de uso)
//   lib/app/data/        → Los DATOS (modelos JSON, llamadas HTTP, implementaciones)
//   lib/app/modules/     → Las PANTALLAS (vistas, controllers, bindings)
//   lib/app/core/        → Cosas GLOBALES (colores, tema, red, constantes)
//   lib/app/routes/      → La NAVEGACIÓN (qué pantalla abre cada ruta)
//
// ¿Por qué esta arquitectura?
//   • Si cambias la API, solo tocas la capa Data. La UI no sabe nada.
//   • Si rediseñas la pantalla, solo tocas la capa Presentation. Los datos no cambian.
//   • Cada pieza se puede probar por separado.

$mainAsync main()$asyncKeyword {
  WidgetsFlutterBinding.ensureInitialized();$dbInitLine
  runApp(const MyApp());
}
''';
}

/// Genera `lib/app/app.dart` con la clase MyApp (GetMaterialApp).
String appTemplate(String appName, String pascal) => '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$appName/app/routes/app_pages.dart';
import 'package:$appName/app/core/theme/app_theme.dart';
import 'package:$appName/app/core/bindings/initial_binding.dart';
import 'package:$appName/app/core/constants/app_constants.dart';
import 'package:$appName/app/translations/app_translations.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  MyApp — Configuración raíz de la aplicación                            │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Aquí vive la configuración global de la app:
//   • Tema (claro / oscuro)
//   • Rutas de navegación
//   • Binding inicial (servicios globales)
//   • Idiomas (i18n)
//
// main.dart solo llama runApp(const MyApp()) y mantiene la inicialización
// de bajo nivel (WidgetsFlutterBinding, AppDatabase.init(), etc.).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Colores y tipografía de la app (cámbialo en core/theme/app_theme.dart)
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // InitialBinding crea los servicios globales ANTES de mostrar cualquier pantalla
      // (por ejemplo: el cliente HTTP, el servicio de autenticación, etc.)
      initialBinding: InitialBinding(),

      // Pantalla que se muestra primero al abrir la app
      initialRoute: AppPages.initial,

      // Lista completa de pantallas y sus rutas (routes/app_pages.dart)
      getPages: AppPages.routes,

      // Textos en varios idiomas (translations/app_translations.dart)
      translationsKeys: AppTranslations.translationsKeys,
      locale: const Locale('es', 'MX'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
''';

String appPagesTemplate(String appName) => '''
import 'package:get/get.dart';
import 'package:$appName/app/modules/home/views/home_view.dart';
import 'package:$appName/app/modules/home/bindings/home_binding.dart';
// cleanarch:import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppPages — Lista de todas las pantallas de la app                      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace este archivo?
//   Es el "directorio de pantallas". Cada pantalla de la app está registrada
//   aquí como un GetPage. Home es la pantalla raíz; el resto son sus hijos.
//
// ¿Cómo agrego una pantalla nueva?
//   Usa el CLI — él inyecta la ruta automáticamente:
//
//     cleanarch create module <nombre>     → módulo completo (hijo de home)
//     cleanarch create feature <nombre>    → feature ligero (hijo de home)
//     cleanarch create screen <nombre> --module <mod>  → screen dentro de un módulo
//
// Estructura de rutas:
//   home (raíz)
//   └── producto     ← módulo hijo
//       └── detalle  ← screen hija del módulo
//   └── dashboard    ← feature hijo
//
// ¿Cómo navego?
//   Get.toNamed(Routes.producto);
//   Get.toNamed(Routes.detalleScreen, arguments: {'id': '1'});
//   Get.back();

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // Primera pantalla que se muestra al abrir la app
  static const initial = Routes.home;

  static final routes = <GetPage>[
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      // Todas las demás pantallas son hijos de home.
      // El CLI las agrega aquí automáticamente al usar cleanarch create.
      children: [
        // cleanarch:inject
      ],
    ),
  ];
}
''';

String appRoutesTemplate() => '''
part of 'app_pages.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  AppRoutes — Nombres de las rutas de navegación                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Para qué sirve esto?
//   En lugar de escribir '/home' cada vez que navegas, usas Routes.home.
//   Ventaja: si cambias el nombre de la ruta, lo cambias aquí y se
//   actualiza en toda la app sin buscar string por string.
//
// ¿Cómo navego de una pantalla a otra?
//   Get.toNamed(Routes.home);                    // navegar y agregar al historial
//   Get.offNamed(Routes.home);                   // navegar y quitar la pantalla actual
//   Get.offAllNamed(Routes.home);                // navegar y limpiar todo el historial
//
// ¿Cómo paso datos a la pantalla de destino?
//   Get.toNamed(Routes.producto, arguments: {'id': '123'});
//   Y en el Controller de destino: final args = Get.arguments as Map;
//
// El CLI agrega aquí nuevas constantes automáticamente al usar cleanarch create.
abstract class Routes {
  Routes._();

  static const home = '/home';
  // cleanarch:route
}
''';

String appThemeTemplate() => '''
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF1976D2);
  static const _secondary = Color(0xFF03A9F4);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      secondary: _secondary,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      secondary: _secondary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  );
}
''';

String appTranslationsTemplate() => '''
class AppTranslations {
  AppTranslations._();

  static const translationsKeys = <String, Map<String, String>>{
    'es_MX': _esMX,
    'en_US': _enUS,
  };

  static const _esMX = <String, String>{
    'app_name': 'Mi App',
    'loading': 'Cargando...',
    'error': 'Ocurrió un error',
    'retry': 'Reintentar',
    'no_data': 'Sin registros',
  };

  static const _enUS = <String, String>{
    'app_name': 'My App',
    'loading': 'Loading...',
    'error': 'An error occurred',
    'retry': 'Retry',
    'no_data': 'No records',
  };
}
''';

String initialBindingTemplate({
  List<({String import, String registration, String comment})> services = const [],
  String packageName = 'your_app',
}) {
  final serviceImports = services.map((s) => s.import).join('\n');
  final serviceLines = services
      .map((s) => '${s.comment}\n${s.registration}')
      .join('\n\n');

  final importsBlock = serviceImports.isNotEmpty ? '\n$serviceImports' : '';
  final servicesBlock = serviceLines.isNotEmpty
      ? '\n$serviceLines\n'
      : '\n    // TODO: agrega aquí tus servicios globales\n'
        '    // Get.put<AuthService>(AuthService(), permanent: true);\n';

  return '''
import 'package:get/get.dart';
import 'package:$packageName/app/core/network/api_client.dart';$importsBlock
// cleanarch:import

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  InitialBinding — Servicios globales de la app                          │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué hace este archivo?
//   Es el primer Binding que ejecuta GetX, incluso antes de mostrar
//   cualquier pantalla. Aquí registras los objetos que TODA la app necesita.
//
// ¿Qué va aquí?
//   ✅ ApiClient          → para hacer llamadas HTTP desde cualquier Provider
//   ✅ DatabaseService    → base de datos local global
//   ✅ SettingsService    → configuración persistente global
//
// ¿Qué NO va aquí?
//   ❌ Controllers de pantallas específicas (esos van en el Binding de cada módulo)
//
// ¿Qué significa permanent: true?
//   Le dice a GetX: "No destruyas este objeto aunque cambie la pantalla".
//   Los servicios globales siempre deben ser permanent: true.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Cliente HTTP disponible para todos los Providers de la app
    Get.put<ApiClient>(ApiClient(), permanent: true);
$servicesBlock    // cleanarch:service
  }
}
''';
}

String apiClientTemplate([String httpLib = 'get_connect']) {
  final norm = httpLib.toLowerCase().trim();
  if (norm == 'dio') return _apiClientDio();
  return _apiClientGetConnect();
}

String _apiClientGetConnect() => '''
import 'package:get/get.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ApiClient — Cliente HTTP de la app (GetConnect)                        │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué debo cambiar aquí?
//   1. baseUrl → pon la URL de tu API (sin la barra final)
//   2. Token   → descomenta las líneas de Authorization
//   3. Error 401 → redirige al login en responseModifier
class ApiClient extends GetConnect {
  @override
  void onInit() {
    // TODO: cambia esta URL por la dirección real de tu API
    httpClient.baseUrl = 'https://api.example.com/v1';
    httpClient.timeout = const Duration(seconds: 30);

    // Se ejecuta antes de cada petición → agrega headers necesarios
    httpClient.addRequestModifier<dynamic>((request) {
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';

      // TODO: si tu API requiere autenticación, descomenta esto:
      // final token = Get.find<AuthService>().token.value;
      // if (token.isNotEmpty) {
      //   request.headers['Authorization'] = 'Bearer \$token';
      // }

      return request;
    });

    // Se ejecuta después de cada respuesta → maneja errores globales
    httpClient.addResponseModifier((request, response) {
      if (response.statusCode == 401) {
        // 401 = sesión expirada o no autorizado
        // TODO: redirige al usuario al login
        // Get.offAllNamed(Routes.login);
      }
      return response;
    });

    super.onInit();
  }
}
''';

String _apiClientDio() => '''
import 'package:dio/dio.dart';

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  ApiClient — Cliente HTTP de la app (Dio)                               │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ¿Qué debo cambiar aquí?
//   1. baseUrl → pon la URL de tu API (sin la barra final)
//   2. Token   → descomenta las líneas de Authorization en el interceptor
//   3. Error 401 → redirige al login en el interceptor onError
//
// ApiService obtiene la instancia de Dio vía: Get.find<ApiClient>().dio
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        // TODO: cambia esta URL por la dirección real de tu API
        baseUrl: 'https://api.example.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: si tu API requiere autenticación, descomenta esto:
          // final token = Get.find<AuthService>().token.value;
          // if (token.isNotEmpty) {
          //   options.headers['Authorization'] = 'Bearer \$token';
          // }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // 401 = sesión expirada o no autorizado
            // TODO: redirige al usuario al login
            // Get.offAllNamed(Routes.login);
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Instancia de Dio configurada. Usada por ApiService.
  Dio get dio => _dio;
}
''';

String appConstantsTemplate(String pascal) => '''
class AppConstants {
  AppConstants._();

  static const appName = '$pascal';
  static const appVersion = '1.0.0';

  // Storage keys
  static const tokenKey = 'auth_token';
  static const userKey = 'user_data';
  static const themeKey = 'theme_mode';
  static const langKey = 'language';
}
''';

String appColorsTemplate() => '''
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1976D2);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF1565C0);

  static const secondary = Color(0xFF03A9F4);

  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  static const backgroundLight = Color(0xFFF5F5F5);
  static const backgroundDark = Color(0xFF121212);

  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textDisabled = Color(0xFFBDBDBD);
}
''';

String appTextStylesTemplate() => '''
import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const body1 = TextStyle(fontSize: 16);
  static const body2 = TextStyle(fontSize: 14);
  static const caption = TextStyle(fontSize: 12, letterSpacing: 0.4);

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
''';

String pubspecTemplate(
  String appName,
  String org, {
  Map<String, String> extraDeps = const {},
  Map<String, String> extraDevDeps = const {},
}) {
  // Agrupa las dependencias extra por categoría si vienen con comentario
  final depsBlock = StringBuffer();
  if (extraDeps.isNotEmpty) {
    depsBlock.writeln();
    depsBlock.writeln('  # Dependencias adicionales');
    for (final entry in extraDeps.entries) {
      depsBlock.writeln('  ${entry.key}: ${entry.value}');
    }
  }

  // Claves ya presentes en la plantilla → no duplicar
  const hardcodedDevDeps = {'flutter_test', 'flutter_lints', 'mockito', 'build_runner'};

  final devDepsBlock = StringBuffer();
  final filteredDevDeps = Map.fromEntries(
    extraDevDeps.entries.where((e) => !hardcodedDevDeps.contains(e.key)),
  );
  if (filteredDevDeps.isNotEmpty) {
    devDepsBlock.writeln();
    devDepsBlock.writeln('  # Dev dependencies adicionales');
    for (final entry in filteredDevDeps.entries) {
      devDepsBlock.writeln('  ${entry.key}: ${entry.value}');
    }
  }

  return '''
name: $appName
description: A Flutter application with Clean Architecture and GetX.
# Author: RamonChenoDev
version: 1.0.0+1
publish_to: 'none'
homepage: https://github.com/RamonChenoDev/$appName

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # State management, navegación e inyección de dependencias
  get: ^4.6.6
$depsBlock
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # Testing
  mockito: ^5.4.4
  build_runner: ^2.4.12
$devDepsBlock
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
''';
}

String gitignoreTemplate() => '''
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# VS Code
.vscode/

# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Generated files (mockito mocks, build_runner output)
*.mocks.dart

# Android
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java

# iOS
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/.generated/
**/ios/Flutter/.last_build_id
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral/
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# Environment
.env
.env.*
''';

String analysisOptionsTemplate() => '''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_empty_else
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_single_quotes
    - sort_child_properties_last
    - use_key_in_widget_constructors
''';

String readmeTemplate(String pascal, String appName) => '''
# $pascal

Proyecto Flutter con **Arquitectura Limpia** y **GetX** como manejador de estados.

## Estructura del Proyecto

```
lib/
├── app/
│   ├── core/
│   │   ├── bindings/        # InitialBinding
│   │   ├── constants/       # AppConstants, AppColors, AppTextStyles
│   │   ├── network/         # ApiClient (GetConnect)
│   │   ├── theme/           # AppTheme
│   │   └── utils/           # Helpers generales
│   ├── data/
│   │   ├── models/          # Modelos (extienden entities)
│   │   ├── providers/       # Fuentes de datos remotas/locales
│   │   └── repositories/    # Implementaciones de repositorios
│   ├── domain/
│   │   ├── entities/        # Entidades de negocio
│   │   ├── repositories/    # Contratos (interfaces)
│   │   └── usecases/        # Casos de uso
│   ├── modules/             # Módulos (feature slices)
│   │   └── <module>/
│   │       ├── bindings/    # Inyección de dependencias
│   │       ├── controllers/ # GetxController
│   │       ├── views/       # Vistas (GetView)
│   │       └── widgets/     # Widgets locales del módulo
│   ├── routes/              # AppPages + AppRoutes
│   └── translations/        # i18n
└── main.dart
```

## Generado con cleanarch CLI — by [RamonChenoDev](https://github.com/RamonChenoDev)

```bash
# Crear proyecto
cleanarch create project <nombre>

# Crear módulo completo (domain + data + presentation)
cleanarch create module <nombre>

# Crear feature ligero (vista + controlador + binding)
cleanarch create feature <nombre>

# Crear screen dentro de un módulo
cleanarch create screen <nombre> --module <modulo>

# Crear solo un controlador
cleanarch create controller <nombre>

# Ver ayuda
cleanarch --help
```

## Comenzar

```bash
flutter pub get
flutter run
```
''';
