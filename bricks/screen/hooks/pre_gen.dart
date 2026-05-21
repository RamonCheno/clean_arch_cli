import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final name = context.vars['name'] as String;
  final parentModule = (context.vars['parent_module'] as String?) ?? '';

  final hasParent = parentModule.isNotEmpty;
  context.vars['has_parent'] = hasParent;

  if (hasParent) {
    context.vars['import_path'] =
        'app/modules/$parentModule/screens/$name';
  } else {
    context.vars['import_path'] = 'app/screens/$name';
  }
}
