/// Catálogo de paquetes Flutter disponibles para agregar al proyecto.
class FlutterPackage {
  final String name;
  final String version;
  final String description;
  final String category;

  /// Paquetes runtime que deben instalarse junto con este (ej. drift_sqflite con drift).
  final Map<String, String> companions;
  final Map<String, String> devDependencies;

  const FlutterPackage({
    required this.name,
    required this.version,
    required this.description,
    required this.category,
    this.companions = const {},
    this.devDependencies = const {},
  });
}

/// Catálogo completo de paquetes disponibles, organizados por categoría.
class FlutterPackages {
  FlutterPackages._();

  // ── Paquetes generales (cross-platform) ─────────────────────────────────

  static const all = <FlutterPackage>[
    // ── Almacenamiento local ─────────────────────────────────────────────
    FlutterPackage(
      name: 'get_storage',
      version: '^2.1.1',
      description: 'Storage ligero compatible con GetX (sin async)',
      category: 'Almacenamiento local',
    ),
    FlutterPackage(
      name: 'shared_preferences',
      version: '^2.3.2',
      description: 'Key-value storage simple (async)',
      category: 'Almacenamiento local',
    ),
    FlutterPackage(
      name: 'hive_flutter',
      version: '^1.1.0',
      description: 'Base de datos NoSQL local, rápida y ligera',
      category: 'Almacenamiento local',
    ),
    FlutterPackage(
      name: 'flutter_secure_storage',
      version: '^9.2.2',
      description: 'Almacenamiento seguro (keychain en iOS / keystore en Android)',
      category: 'Almacenamiento local',
    ),
    FlutterPackage(
      name: 'sqflite',
      version: '^2.4.1',
      description: 'Base de datos SQLite relacional para Flutter',
      category: 'Almacenamiento local',
    ),
    FlutterPackage(
      name: 'isar',
      version: '^3.1.0+1',
      description: 'Base de datos NoSQL local con code-gen y queries tipadas',
      category: 'Almacenamiento local',
      companions: {
        'isar_flutter_libs': '^3.1.0+1',
      },
      devDependencies: {
        'isar_generator': '^3.1.0+1',
        'build_runner': '^2.4.12',
      },
    ),
    FlutterPackage(
      name: 'drift',
      version: '^2.22.1',
      description: 'ORM SQLite con code-gen y soporte reactivo (streams)',
      category: 'Almacenamiento local',
      devDependencies: {
        'drift_dev': '^2.22.1',
        'build_runner': '^2.4.12',
      },
    ),
    FlutterPackage(
      name: 'objectbox',
      version: '^4.0.0',
      description: 'Base de datos NoSQL de alto rendimiento con code-gen',
      category: 'Almacenamiento local',
      companions: {
        'objectbox_flutter_libs': '^4.0.0',
      },
      devDependencies: {
        'objectbox_generator': '^4.0.0',
        'build_runner': '^2.4.12',
      },
    ),
    FlutterPackage(
      name: 'floor',
      version: '^1.5.0',
      description: 'ORM SQLite inspirado en Room (Android) con code-gen y DAOs',
      category: 'Almacenamiento local',
      devDependencies: {
        'floor_generator': '^1.5.0',
        'build_runner': '^2.4.12',
      },
    ),

    // ── Red & API ────────────────────────────────────────────────────────
    FlutterPackage(
      name: 'dio',
      version: '^5.7.0',
      description: 'Cliente HTTP avanzado con interceptores, retry y cancelación',
      category: 'Red & API',
    ),
    FlutterPackage(
      name: 'connectivity_plus',
      version: '^6.1.0',
      description: 'Detectar conexión a internet (WiFi, móvil, sin conexión)',
      category: 'Red & API',
    ),

    // ── UI & Medios ──────────────────────────────────────────────────────
    FlutterPackage(
      name: 'flutter_svg',
      version: '^2.0.10+1',
      description: 'Renderizar imágenes SVG en Flutter',
      category: 'UI & Medios',
    ),
    FlutterPackage(
      name: 'cached_network_image',
      version: '^3.4.1',
      description: 'Imágenes de red con caché automática',
      category: 'UI & Medios',
    ),
    FlutterPackage(
      name: 'shimmer',
      version: '^3.0.0',
      description: 'Efecto skeleton / shimmer para pantallas de carga',
      category: 'UI & Medios',
    ),
    FlutterPackage(
      name: 'lottie',
      version: '^3.1.0',
      description: 'Animaciones Lottie (exportadas desde Adobe After Effects)',
      category: 'UI & Medios',
    ),
    FlutterPackage(
      name: 'image_picker',
      version: '^1.1.2',
      description: 'Seleccionar imágenes o videos de galería o cámara',
      category: 'UI & Medios',
    ),

    // ── Utilidades ───────────────────────────────────────────────────────
    FlutterPackage(
      name: 'intl',
      version: '^0.19.0',
      description: 'Formatos de fecha, número, moneda e internacionalización',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'equatable',
      version: '^2.0.5',
      description: 'Comparación de objetos por valor (sin sobreescribir == manualmente)',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'logger',
      version: '^2.4.0',
      description: 'Logs con colores, niveles y formato legible en consola',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'flutter_dotenv',
      version: '^5.2.1',
      description: 'Variables de entorno desde un archivo .env',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'permission_handler',
      version: '^11.3.1',
      description: 'Solicitar permisos en runtime (cámara, ubicación, etc.)',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'url_launcher',
      version: '^6.3.1',
      description: 'Abrir URLs, correos electrónicos y llamadas telefónicas',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'path',
      version: '^1.9.1',
      description: 'Manipulación de rutas de archivos multiplataforma (join, basename, dirname...)',
      category: 'Utilidades',
    ),
    FlutterPackage(
      name: 'path_provider',
      version: '^2.1.5',
      description: 'Rutas del sistema de archivos (documentos, caché, temp) en Android/iOS/Desktop',
      category: 'Utilidades',
    ),

    // ── Firebase ─────────────────────────────────────────────────────────
    FlutterPackage(
      name: 'firebase_core',
      version: '^3.6.0',
      description: 'Base requerida para todos los servicios de Firebase',
      category: 'Firebase',
    ),
    FlutterPackage(
      name: 'firebase_auth',
      version: '^5.3.1',
      description: 'Autenticación Firebase (email, Google, phone, etc.)',
      category: 'Firebase',
    ),
    FlutterPackage(
      name: 'cloud_firestore',
      version: '^5.4.4',
      description: 'Base de datos NoSQL en tiempo real de Firebase',
      category: 'Firebase',
    ),
    FlutterPackage(
      name: 'firebase_messaging',
      version: '^15.1.3',
      description: 'Notificaciones push con Firebase Cloud Messaging (FCM)',
      category: 'Firebase',
    ),
    FlutterPackage(
      name: 'firebase_storage',
      version: '^12.3.2',
      description: 'Almacenamiento de archivos en Firebase (imágenes, PDFs, etc.)',
      category: 'Firebase',
    ),

    // ── Serialización JSON ───────────────────────────────────────────────
    FlutterPackage(
      name: 'json_annotation',
      version: '^4.9.0',
      description: 'Genera fromJson/toJson automáticamente con @JsonSerializable',
      category: 'Serialización JSON',
      devDependencies: {
        'json_serializable': '^6.8.0',
        'build_runner': '^2.4.12',
      },
    ),
  ];

  // ── Paquetes específicos por plataforma ──────────────────────────────────

  /// Paquetes recomendados para proyectos con soporte móvil (Android / iOS).
  static const mobile = <FlutterPackage>[
    FlutterPackage(
      name: 'geolocator',
      version: '^13.0.2',
      description: 'GPS y ubicación en tiempo real',
      category: 'Móvil',
    ),
    FlutterPackage(
      name: 'flutter_local_notifications',
      version: '^18.0.1',
      description: 'Notificaciones locales programadas',
      category: 'Móvil',
    ),
    FlutterPackage(
      name: 'camera',
      version: '^0.11.0+2',
      description: 'Acceso directo a la cámara del dispositivo',
      category: 'Móvil',
    ),
    FlutterPackage(
      name: 'share_plus',
      version: '^10.1.2',
      description: 'Compartir texto, archivos e imágenes con otras apps',
      category: 'Móvil',
    ),
    FlutterPackage(
      name: 'sensors_plus',
      version: '^6.1.0',
      description: 'Acelerómetro, giroscopio y magnetómetro',
      category: 'Móvil',
    ),
    FlutterPackage(
      name: 'local_auth',
      version: '^2.3.0',
      description: 'Autenticación biométrica (huella, Face ID)',
      category: 'Móvil',
    ),
  ];

  /// Paquetes recomendados para proyectos con soporte escritorio
  /// (Windows / Linux / macOS).
  static const desktop = <FlutterPackage>[
    FlutterPackage(
      name: 'window_manager',
      version: '^0.4.3',
      description: 'Control de ventana: tamaño, título, siempre al frente',
      category: 'Escritorio',
    ),
    FlutterPackage(
      name: 'file_picker',
      version: '^8.1.3',
      description: 'Selector de archivos y carpetas del sistema',
      category: 'Escritorio',
    ),
    FlutterPackage(
      name: 'desktop_drop',
      version: '^0.4.4',
      description: 'Arrastrar y soltar archivos (drag & drop)',
      category: 'Escritorio',
    ),
    FlutterPackage(
      name: 'system_tray',
      version: '^2.0.3',
      description: 'Ícono en la bandeja del sistema (system tray)',
      category: 'Escritorio',
    ),
    FlutterPackage(
      name: 'hotkey_manager',
      version: '^0.2.3',
      description: 'Atajos de teclado globales del sistema',
      category: 'Escritorio',
    ),
    FlutterPackage(
      name: 'launch_at_startup',
      version: '^0.3.0',
      description: 'Lanzar la app automáticamente al iniciar el sistema',
      category: 'Escritorio',
    ),
  ];

  /// Paquetes recomendados para proyectos con soporte web.
  static const web = <FlutterPackage>[
    FlutterPackage(
      name: 'url_strategy',
      version: '^0.2.0',
      description: 'URLs limpias sin # (path URL strategy)',
      category: 'Web',
    ),
    FlutterPackage(
      name: 'web',
      version: '^1.1.0',
      description: 'APIs web nativas: DOM, fetch, localStorage, WebSocket',
      category: 'Web',
    ),
    FlutterPackage(
      name: 'flutter_web_plugins',
      version: 'any',
      description: 'Soporte de plugins específicos para Flutter Web',
      category: 'Web',
    ),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Retorna los paquetes específicos de plataforma relevantes según la
  /// selección. Se muestran:
  ///   - Móvil   → si se incluye android o ios
  ///   - Escritorio → si se incluye windows, linux o macos
  ///   - Web     → si se incluye web
  static List<({String label, List<FlutterPackage> packages})> platformSectionsFor(List<String> platforms) {
    final hasMobile = platforms.any((p) => p == 'android' || p == 'ios');
    final hasDesktop = platforms.any((p) => p == 'windows' || p == 'linux' || p == 'macos');
    final hasWeb = platforms.contains('web');

    if (!hasMobile && !hasDesktop && !hasWeb) return [];

    final sections = <({String label, List<FlutterPackage> packages})>[];

    if (hasMobile) {
      sections.add((
        label: '📱 Móvil — Android / iOS',
        packages: mobile,
      ));
    }
    if (hasDesktop) {
      sections.add((
        label: '🖥️  Escritorio — Windows / Linux / macOS',
        packages: desktop,
      ));
    }
    if (hasWeb) {
      sections.add((
        label: '🌐 Web',
        packages: web,
      ));
    }

    return sections;
  }

  /// Devuelve todos los paquetes de una categoría dada.
  static List<FlutterPackage> byCategory(String category) => all.where((p) => p.category == category).toList();

  /// Devuelve las categorías únicas, en orden.
  static List<String> get categories => all.map((p) => p.category).toSet().toList();

  /// Busca un paquete por nombre (case-insensitive) en todos los catálogos.
  static FlutterPackage? byName(String name) {
    final combined = [...all, ...mobile, ...desktop, ...web];
    try {
      return combined.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
