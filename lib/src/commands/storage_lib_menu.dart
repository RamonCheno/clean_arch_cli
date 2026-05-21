import 'dart:io';

/// Menú interactivo de selección de librería(s) de almacenamiento local.
///
/// Retorna:
///   - 1 lib:  `"hive"`
///   - 2 libs: `"hive:database,shared_preferences:settings"`
String storageLibMenu() {
  const bold = '\x1B[1m';
  const yellow = '\x1B[33m';
  const cyan = '\x1B[36m';
  const gray = '\x1B[90m';
  const reset = '\x1B[0m';

  const options = [
    ('get_storage',            'Síncrono, ligero — recomendado con GetX'),
    ('hive',                   'NoSQL, tipado, muy rápido'),
    ('shared_preferences',     'Key-value async, estándar Flutter'),
    ('flutter_secure_storage', 'Encriptado, para datos sensibles'),
    ('sqflite',                'SQL relacional, ampliamente usado'),
    ('isar',                   'NoSQL tipado, muy rápido, code-gen'),
    ('drift',                  'ORM SQLite con code-gen'),
    ('objectbox',              'NoSQL de alto rendimiento, code-gen'),
    ('floor',                  'ORM SQLite estilo Room, code-gen'),
  ];

  print('');
  print('  $bold Librería(s) de almacenamiento local:$reset');
  print('  $gray Puedes elegir 1 o 2 opciones separadas por coma (ej: 1  o  1,3)$reset');
  print('');
  for (var i = 0; i < options.length; i++) {
    final (pkg, desc) = options[i];
    print('$yellow  ${i + 1}.$reset ${pkg.padRight(26)} $gray$desc$reset');
  }
  print('$yellow  ${options.length + 1}.$reset Otra'
      '                       $gray→ escribe el nombre del paquete (provider CRUD genérico)$reset');
  print('');
  stdout.write('  Selecciona opción(es) [1]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  print('');

  // Parsear 1 o 2 números separados por coma
  final parts = input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) parts.add('1');
  if (parts.length > 2) parts.length = 2;

  String resolveLib(String raw) {
    final n = int.tryParse(raw) ?? 1;
    if (n >= 1 && n <= options.length) return options[n - 1].$1;
    stdout.write('  Nombre del paquete: ');
    final pkg = stdin.readLineSync()?.trim() ?? '';
    return pkg.isEmpty ? 'get_storage' : pkg;
  }

  if (parts.length == 1) {
    return resolveLib(parts[0]);
  }

  // 2 selecciones
  final lib1 = resolveLib(parts[0]);
  final lib2 = resolveLib(parts[1]);

  if (lib1 == lib2) {
    print('  $yellow⚠$reset Las dos opciones son la misma librería. Se usará solo una.');
    return lib1;
  }

  const purposes = [
    ('database', 'Base de datos principal (CRUD completo)'),
    ('cache',    'Caché temporal'),
    ('settings', 'Persistencia de configuración'),
    ('secure',   'Datos sensibles / tokens'),
  ];

  String askPurpose(String lib) {
    print('  $cyan¿Para qué usarás $bold$lib$reset$cyan?$reset');
    for (var i = 0; i < purposes.length; i++) {
      final (_, desc) = purposes[i];
      print('  $yellow${i + 1}.$reset $desc');
    }
    stdout.write('  Selecciona [1]: ');
    final n = int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 1;
    print('');
    final idx = (n >= 1 && n <= purposes.length) ? n - 1 : 0;
    return purposes[idx].$1;
  }

  final purpose1 = askPurpose(lib1);
  final purpose2 = askPurpose(lib2);

  return '$lib1:$purpose1,$lib2:$purpose2';
}
