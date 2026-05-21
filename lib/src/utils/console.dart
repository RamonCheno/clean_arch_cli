import 'dart:io';

class Console {
  static const _reset = '\x1B[0m';
  static const _green = '\x1B[32m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _bold = '\x1B[1m';
  static const _gray = '\x1B[90m';
  static const _magenta = '\x1B[35m';

  static bool _quiet = false;

  static void setQuiet(bool value) => _quiet = value;

  static void success(String msg) => print('$_green✔$_reset $msg');
  static void info(String msg) {
    if (_quiet) { return; }
    print('$_cyan ℹ$_reset $msg');
  }

  static void warning(String msg) => print('$_yellow⚠$_reset $msg');
  static void error(String msg) => print('$_red✘$_reset $msg');
  static void created(String path) {
    if (_quiet) { return; }
    print('$_green  create$_reset $path');
  }

  static void skip(String path) {
    if (_quiet) { return; }
    print('$_gray  skip$_reset   $path');
  }

  static void dryRun(String path) =>
      print('$_magenta  dry-run$_reset $path');

  static void header(String title) {
    if (_quiet) { return; }
    final line = '─' * (title.length + 4);
    print('');
    print('$_cyan$_bold┌$line┐$_reset');
    print('$_cyan$_bold│  $title  │$_reset');
    print('$_cyan$_bold└$line┘$_reset');
    print('');
  }

  static void step(int n, String msg) {
    if (_quiet) { return; }
    print('$_cyan$_bold[$n]$_reset $msg');
  }

  static bool confirm(String question) {
    stdout.write('$_yellow?$_reset $question (y/N): ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    return input == 'y' || input == 'yes';
  }

  /// Muestra un salto de línea y pregunta si se deben crear los archivos
  /// listados por un dry-run anterior. Devuelve true si el usuario confirma.
  static bool confirmDryRun() {
    print('');
    return confirm('¿Crear estos archivos?');
  }

  static String? prompt(String question, {String? defaultValue}) {
    final hint = defaultValue != null ? ' ($_gray$defaultValue$_reset)' : '';
    stdout.write('$_cyan?$_reset $question$hint: ');
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) { return defaultValue; }
    return input;
  }
}
