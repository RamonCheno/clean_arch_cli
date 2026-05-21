import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final name = context.vars['name'] as String;
  final datasource = (context.vars['datasource'] as String?) ?? 'rest';
  final storageLib = (context.vars['storage_lib'] as String?) ?? 'get_storage';

  // Compute plural and plural_pascal from name
  context.vars['plural'] = _toPlural(name);
  context.vars['plural_pascal'] = _toPascalCase(_toPlural(name));

  // Datasource boolean flags
  context.vars['is_rest'] = datasource == 'rest';
  context.vars['is_local'] = datasource == 'local';
  context.vars['is_both'] = datasource == 'both';

  // Sync storage libs: get_storage and hive use synchronous APIs
  final syncLibs = ['get_storage', 'hive', 'hive_flutter'];
  final normLib = storageLib.split(':').first.trim().toLowerCase();
  context.vars['is_local_sync'] =
      datasource == 'local' && syncLibs.contains(normLib);
}

String _toPlural(String name) {
  if (name.endsWith('s')) return '${name}es';
  if (name.endsWith('y') && name.length > 1) {
    return '${name.substring(0, name.length - 1)}ies';
  }
  return '${name}s';
}

String _toPascalCase(String snake) {
  return snake
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join();
}
