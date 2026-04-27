import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

class AppLoggerWeb {
  static void downloadLog({String? filename}) {
    if (!kIsWeb) return;

    final content = utf8.encode(AppLogger.dumpBuffer());
    final blob = html.Blob([content], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final a = html.AnchorElement(href: url)
      ..download = filename ??
          'vanpro_auth_debug_${DateTime.now().toIso8601String().replaceAll(':', '-')}.log'
      ..style.display = 'none';

    html.document.body?.children.add(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  }
}