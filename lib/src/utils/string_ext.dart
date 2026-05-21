extension StringExt on String {
  /// hello_world → HelloWorld
  String toPascalCase() {
    return split(RegExp(r'[_\-\s]+'))
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join();
  }

  /// hello_world → helloWorld
  String toCamelCase() {
    final pascal = toPascalCase();
    if (pascal.isEmpty) return pascal;
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  /// helloWorld / HelloWorld → hello_world
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '_${m[0]!.toLowerCase()}',
    )
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }

  /// hello_world → hello-world
  String toKebabCase() => toSnakeCase().replaceAll('_', '-');

  bool get isValidIdentifier =>
      RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(this);

  /// Basic English pluralization for snake_case names.
  String toPlural() {
    if (endsWith('s') || endsWith('x') || endsWith('z') ||
        endsWith('ch') || endsWith('sh')) {
      return '${this}es';
    }
    if (endsWith('y') && length > 1) {
      final beforeY = this[length - 2];
      const vowels = 'aeiou';
      if (!vowels.contains(beforeY)) {
        return '${substring(0, length - 1)}ies';
      }
    }
    return '${this}s';
  }
}
