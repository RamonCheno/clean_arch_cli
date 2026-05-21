import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/utils/console.dart';

/// A [GeneratorTarget] that writes generated files to a [Directory].
/// Supports dry-run (prints paths without writing) and overwrite control.
class MasonTarget extends GeneratorTarget {
  final String rootDir;
  final bool overwrite;
  final bool dryRun;

  MasonTarget(this.rootDir, {this.overwrite = false, this.dryRun = false});

  @override
  Future<GeneratedFile> createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) async {
    // Mason bundle stores paths with .mustache — strip it before writing
    final cleanPath = path.endsWith('.mustache')
        ? path.substring(0, path.length - '.mustache'.length)
        : path;
    final fullPath = p.join(rootDir, cleanPath);
    final file = File(fullPath);
    if (dryRun) {
      if (!overwrite && file.existsSync()) {
        Console.skip(fullPath);
      } else {
        Console.dryRun(fullPath);
      }
      return GeneratedFile.skipped(path: fullPath);
    }
    if (!overwrite && file.existsSync()) {
      Console.skip(fullPath);
      return GeneratedFile.skipped(path: fullPath);
    }
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(contents);
    Console.created(fullPath);
    return GeneratedFile.created(path: fullPath);
  }
}
