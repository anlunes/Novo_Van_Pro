import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'basic_login_screen.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({super.key, required this.email});

  final String? email;

  @override
  State<EmailVerificationPendingScreen> createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Se estiver logado (após login), checa.
      if (user == null) {
        setState(() {
          _message = 'Faça login novamente após verificar o e-mail.';
        });
        return;
      }

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed?.emailVerified == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BasicLoginScreen()),
        );
      } else {
        setState(() {
          _message = 'Ainda não verificado. Aguarde e tente novamente.';
        });
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação de e-mail')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 72, color: Colors.blueGrey.shade700),
                    const SizedBox(height: 16),
                    Text(
                      'Verifique seu e-mail${widget.email != null ? ' (${widget.email})' : ''}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Depois de verificar, volte e clique em "Já verifiquei".',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_message != null)
                      Text(_message!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _check,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Já verifiquei'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
