import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/app_logger.dart';
 
import '../admin/admin_dashboard.dart';
import '../screens/auth_screen.dart';
import '../screens/motorista_screen.dart';
import '../screens/pais_screen.dart';
import '../screens/verification_pending_screen.dart';
import '../services/notification_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
 
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}
 
class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  Widget? _resolvedScreen;
  bool _notificationReady = false;
 
  @override
  void initState() {
    super.initState();
    _resolveUser();
  }
 
  Future<void> _resolveUser() async {
    setState(() {
      _loading = true;
      _resolvedScreen = null;
    });
 
    final user = FirebaseAuth.instance.currentUser;
 
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _resolvedScreen = const AuthScreen();
        _loading = false;
        _notificationReady = false;
      });
      return;
    }
 
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
 
    if (refreshed == null) {
      if (!mounted) return;
      setState(() {
        _resolvedScreen = const AuthScreen();
        _loading = false;
        _notificationReady = false;
      });
      return;
    }
 
    if (!refreshed.emailVerified) {
      if (!mounted) return;
      // ✅ CORRIGIDO: Removido 'const' e adicionado email
      setState(() {
        _resolvedScreen = VerificationPendingScreen(
          email: refreshed.email,
        );
        _loading = false;
      });
      return;
    }
 
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshed.uid)
        .get();
 
    if (!mounted) return;
 
    if (userDoc.exists) {
            final data = userDoc.data();
      final role = data?['role'] ?? 'responsavel';
      AppLogger.log('AUTH_WRAPPER', 'ROLE_RESOLVED', data: {
        'uid': refreshed.uid,
        'role': role,
        'rawRole': data?['role'],
      });

      _setupNotificationsOnce(refreshed.uid);
 
      if (role == 'admin') {
        AppLogger.log('AUTH_WRAPPER', 'NAV_TARGET', data: {'target': 'admin'});

        setState(() {
          _resolvedScreen = const AdminDashboardPage();
          _loading = false;
        });
        return;
      }
 
      if (role == 'motorista') {
        AppLogger.log('AUTH_WRAPPER', 'NAV_TARGET',
            data: {'target': 'motorista'});

        setState(() {
          _resolvedScreen = MotoristaScreen(uid: refreshed.uid);
          _loading = false;
        });
        return;
      }
 
      AppLogger.log('AUTH_WRAPPER', 'NAV_TARGET',
          data: {'target': 'responsavel'});
      setState(() {
        _resolvedScreen = PaisScreen();
        _loading = false;
      });
      return;
    }
 
    setState(() {
      _resolvedScreen = const Scaffold(
        body: Center(child: Text('Dados do usuário não encontrados')),
      );
      _loading = false;
    });
  }
 
  Future<void> _setupNotificationsOnce(String uid) async {
    if (_notificationReady) return;
    _notificationReady = true;
    await NotificationService.onUserSignedIn(uid, context);
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading || _resolvedScreen == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
 
    return Scaffold(
      body: _resolvedScreen!,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppLogger.downloadLog();
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
