import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'wrappers/auth_wrapper.dart';
import 'services/app_logger.dart';
import 'screens/email_action_handler_screen.dart';
import 'screens/auth_screen.dart';
 
class VanProApp extends StatelessWidget {
  const VanProApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final uri = Uri.base;
      final verified = uri.queryParameters['verified'] == 'true';
 
      if (verified) {
        AppLogger.log('APP', 'RETURNING_FROM_EMAIL_VERIFICATION', data: {
          'verified': true,
        });
      }
    }
 
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VanPro - Transporte Escolar',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      // ✅ Processa deep links diretamente pela URL (Flutter web)
      home: Builder(
        builder: (context) => _buildHomeFromDeepLink(context),
      ),
      onGenerateRoute: _handleRoute,
    );
  }
 
    Widget _buildHomeFromDeepLink(BuildContext context) {
    final uri = Uri.base;
    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'];

    final isVerifyEmail = mode == 'verifyEmail' && oobCode != null && oobCode.isNotEmpty;

    // No Firebase web, a URL costuma conter /__/auth/action
    final path = uri.path;
    final looksLikeFirebaseAction =
        path.contains('__') && path.contains('auth') && path.contains('action');

    if (kIsWeb && isVerifyEmail && looksLikeFirebaseAction) {
      // Debug: confirmar que estamos montando a tela ao abrir o link
      debugPrint('DEBUG montando EmailActionHandlerScreen: mode=$mode oobCodePresent=${oobCode != null}');
      return EmailActionHandlerScreen(oobCode: oobCode, mode: mode);
    }

    return const AuthWrapper();
  }

  /// Intercepta rotas (fallback). Em web, o caminho mais confiável é via Uri.base em [_buildHomeFromDeepLink].
  Route<dynamic>? _handleRoute(RouteSettings settings) {
    try {
      final uri = Uri.tryParse(settings.name ?? '');
      if (uri == null) return null;

      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];

      final looksLikeFirebaseAction = (uri.path.contains('__') && uri.path.contains('auth') && uri.path.contains('action'));

      if (mode == 'verifyEmail' && oobCode != null && oobCode.isNotEmpty && looksLikeFirebaseAction) {
        return MaterialPageRoute(
          builder: (context) => EmailActionHandlerScreen(oobCode: oobCode, mode: mode),
        );
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
}

 