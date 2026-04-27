import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'basic_login_screen.dart';
import 'basic_signup_screen.dart';
import 'email_verification_pending_screen.dart';

class BasicAuthGate extends StatefulWidget {
  const BasicAuthGate({super.key});

  @override
  State<BasicAuthGate> createState() => _BasicAuthGateState();
}

class _BasicAuthGateState extends State<BasicAuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Garantir que o Firebase esteja inicializado antes de tocar no FirebaseAuth (web).
    // Se já estiver inicializado, FirebaseCore não faz nada.
    await Future<void>.delayed(Duration.zero);

    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // atualiza emailVerified
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (refreshed == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // por simplicidade começamos no login
      return const BasicLoginScreen();
    }

    if (!user.emailVerified) {
      return EmailVerificationPendingScreen(email: user.email);
    }

    // Se verificado, manda para login (vamos manter simples por enquanto)
    return const BasicLoginScreen();
  }
}
