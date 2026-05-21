import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final name = context.vars['name'] as String;
  final plural = _toPlural(name);
  context.vars['plural'] = plural;
  context.vars['plural_pascal'] = _toPascalCase(plural);
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
