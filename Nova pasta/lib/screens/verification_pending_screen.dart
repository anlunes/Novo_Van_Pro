import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
 
class VerificationPendingScreen extends StatefulWidget {
  final String? email;
  final Duration checkInterval;
 
  const VerificationPendingScreen({
    Key? key,
    this.email,
    this.checkInterval = const Duration(seconds: 3),
  }) : super(key: key);
 
  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}
 
class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  late Timer _verificationTimer;
  bool _isChecking = false;
  String _statusMessage = 'Verificando email...';
  bool _hasError = false;
  String _userEmail = '';
 
  @override
  void initState() {
    super.initState();
    // ✅ Pega o email do usuário atual do Firebase, ou do parâmetro
    _userEmail = widget.email ?? 
        FirebaseAuth.instance.currentUser?.email ?? 
        'seu.email@exemplo.com';
    _startVerificationCheck();
  }
 
  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(widget.checkInterval, (_) async {
      await _checkEmailVerification();
    });
  }
 
  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;
 
    try {
      _isChecking = true;
 
      // ✅ CRUCIAL: Recarrega o usuário do Firebase para atualizar o status
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          _verificationTimer.cancel();

          // ✅ Atualizar Firestore com status verificado
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'emailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
          }).catchError((e) {
            // Se falhar, continua mesmo assim
            print('Erro ao atualizar Firestore: $e');
          });

          if (mounted) {
            setState(() {
              _statusMessage = '✅ Email verificado com sucesso!';
            });

            await Future.delayed(const Duration(seconds: 1));

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AuthScreen()),
    );
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar email: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Erro ao verificar: ${e.toString()}';
        });
      }
    } finally {
      _isChecking = false;
    }
  }
 
  // Para quando o usuário clica em "Já verifiquei" ou similar
  Future<void> _forceCheckVerification() async {
    setState(() {
      _statusMessage = 'Verificando...';
      _hasError = false;
    });
    await _checkEmailVerification();
  }
 
  @override
  void dispose() {
    _verificationTimer.cancel();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone animado
              _hasError
                  ? const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    )
                  : const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                      ),
                    ),
              const SizedBox(height: 32),
 
              // Título
              Text(
                _hasError ? 'Erro na Verificação' : 'Verificando Email',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
 
              // Status message
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
 
              // Email display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _userEmail,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
 
              // Instruções
              Text(
                'Clique no link de verificação no seu email.\n'
                'Estamos verificando automaticamente...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
 
              // Botão de força check (se o usuário já clicou no link)
              ElevatedButton.icon(
                onPressed: _hasError ? _forceCheckVerification : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Já verifiquei meu email'),
              ),
              const SizedBox(height: 16),
 
              // Botão para voltar
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthScreen()),
                  (route) => false,
                ),
                child: const Text('Voltar para Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 