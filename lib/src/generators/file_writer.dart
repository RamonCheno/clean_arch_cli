import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:clean_arch_cli/src/utils/console.dart';

class FileWriter {
  final bool overwrite;
  final bool dryRun;

  FileWriter({this.overwrite = false, this.dryRun = false});

  void write(String filePath, String content) {
    final file = File(filePath);
    if (dryRun) {
      if (file.existsSync() && !overwrite) {
        Console.skip(filePath);
      } else {
        Console.dryRun(filePath);
      }
      return;
    }
    if (file.existsSync() && !overwrite) {
      Console.skip(filePath);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    Console.created(filePath);
  }

  void createDir(String dirPath) {
    if (dryRun) { return; }
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  String join(List<String> parts) => p.joinAll(parts);
}
