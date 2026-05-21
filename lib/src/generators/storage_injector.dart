import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/utils/console.dart';
import 'package:clean_arch_cli/src/templates/service_templates.dart';

/// Inyecta registros de servicios en initial_binding.dart.
///
/// Usa marcadores de texto para saber dónde insertar:
///   // cleanarch:import  → imports de nuevos servicios
///   // cleanarch:service → Get.put<Service>(...) en dependencies()
class StorageInjector {
  static const _serviceMarker = '// cleanarch:service';
  static const _importMarker = '// cleanarch:import';

  static String _bindingPath(String root) =>
      p.join(root, 'lib', 'app', 'core', 'bindings', 'initial_binding.dart');

  static bool _fileExists(String root) =>
      File(_bindingPath(root)).existsSync();

  // ── API service (REST) ────────────────────────────────────────────────────

  static bool injectApiService(
    String projectRoot,
    String httpLib, {
    required String packageName,
  }) {
    if (!_fileExists(projectRoot)) return false;

    final entry = apiServiceBindingEntry(httpLib, packageName: packageName);
    final bindingFile = _bindingPath(projectRoot);
    final content = File(bindingFile).readAsStringSync();

    if (content.contains(entry.registration.trim())) {
      Console.warning(
          'ApiService ya registrado en initial_binding.dart — saltando.');
      return true;
    }

    _injectImports(bindingFile, [entry.import]);
    _insertBeforeMarker(bindingFile, _serviceMarker, [
      entry.comment.trim(),
      entry.registration.trim(),
      '',
    ]);
    return true;
  }

  // ── Storage services (local / both) ──────────────────────────────────────

  static bool injectStorageService(
    String projectRoot,
    String storageLib, {
    required String packageName,
  }) {
    if (!_fileExists(projectRoot)) return false;

    final entries =
        serviceBindingEntries(storageLib, packageName: packageName);
    if (entries.isEmpty) return false;

    final bindingFile = _bindingPath(projectRoot);
    final content = File(bindingFile).readAsStringSync();

    final toInject =
        entries.where((e) => !content.contains(e.registration.trim())).toList();

    if (toInject.isEmpty) {
      Console.warning(
          'Servicios de storage ya registrados en initial_binding.dart — saltando.');
      return true;
    }

    _injectImports(bindingFile, toInject.map((e) => e.import).toList());
    for (final entry in toInject) {
      _insertBeforeMarker(bindingFile, _serviceMarker, [
        entry.comment.trim(),
        entry.registration.trim(),
        '',
      ]);
    }
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _injectImports(String filePath, List<String> imports) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final toAdd = imports.where((i) => !content.contains(i)).toList();
    if (toAdd.isEmpty) return;

    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (line.trim() == _importMarker) {
        result.addAll(toAdd);
      }
      result.add(line);
    }
    file.writeAsStringSync(result.join('\n'));
  }

  /// Inserta [newLines] justo antes de la línea que contiene [marker],
  /// usando la misma indentación que esa línea en el archivo.
  static void _insertBeforeMarker(
    String filePath,
    String marker,
    List<String> newLines,
  ) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final result = <String>[];
    bool found = false;

    for (final line in lines) {
      if (!found && line.trim() == marker) {
        found = true;
        final indent = ' ' * (line.length - line.trimLeft().length);
        for (final newLine in newLines) {
          result.add(newLine.isEmpty ? '' : '$indent$newLine');
        }
      }
      result.add(line);
    }

    if (!found) {
      Console.warning(
        'No se encontró el marcador "$marker" en ${p.basename(filePath)}. '
        'Registra el servicio manualmente en InitialBinding.',
      );
    } else {
      file.writeAsStringSync(result.join('\n'));
    }
  }
}
