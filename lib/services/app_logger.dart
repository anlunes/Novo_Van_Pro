import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static bool _initialized = false;
  static final List<String> _buffer = [];

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await log('LOGGER', 'INIT', message: 'Logger inicializado');
  }

  static Future<void> log(
    String scope,
    String step, {
    String? message,
    Map<String, dynamic>? data,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final line = jsonEncode({
      'timestamp': timestamp,
      'scope': scope,
      'step': step,
      'message': message ?? '',
      'data': data ?? <String, dynamic>{},
    });
    _buffer.add(line);
    print(line);
    debugPrint(line);
    developer.log(line, name: 'VANPRO.LOG');
  }

  static String dumpBuffer() => _buffer.join('\n');

  static void downloadLog({String? filename}) {
    // mobile/desktop: não faz nada
    // (web ficará sem essa funcionalidade por enquanto)
  }

  static String? get filePath => null;
}