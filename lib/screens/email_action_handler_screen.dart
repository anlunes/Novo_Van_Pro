import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
 
class EmailActionHandlerScreen extends StatefulWidget {
  const EmailActionHandlerScreen({super.key, this.oobCode, this.mode});
 
  final String? oobCode;
  final String? mode;
 
  @override
  State<EmailActionHandlerScreen> createState() =>
      _EmailActionHandlerScreenState();
}
 
class _EmailActionHandlerScreenState extends State<EmailActionHandlerScreen> {
  bool _loading = true;
  String? _message;
  bool _success = false;
  bool _alreadyVerified = false;
 
  @override
  void initState() {
    super.initState();
    _handleAction();
  }
 
    Future<void> _handleAction() async {
    // Em web, dependendo do roteamento, os parâmetros podem não chegar via construtor.
    // Então tentamos também recuperar do URL atual.
    final params = Uri.base.queryParameters;
    final oobCode = widget.oobCode ?? params['oobCode'];
    final mode = widget.mode ?? params['mode'];
 
 
    print('🔍 _handleAction START: mode=$mode, oobCode=$oobCode');
 
    if (mode != 'verifyEmail' || oobCode == null || oobCode.isEmpty) {
      print('❌ Invalid params: mode=$mode, oobCode=$oobCode');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Link inválido ou incompleto.';
      });
      return;
    }
 
    try {
      print('🔄 Calling applyActionCode with oobCode=$oobCode');
      await FirebaseAuth.instance.applyActionCode(oobCode);
      print('✅ applyActionCode success');

      final user = FirebaseAuth.instance.currentUser;
      print('👤 Current user after applyActionCode: uid=${user?.uid} emailVerified=${user?.emailVerified}');

      if (user == null) {
        print('❌ currentUser é null após applyActionCode');
        setState(() {
          _loading = false;
          _message = 'Falha ao processar verificação: usuário não encontrado.';
        });
        return;
      }

      print('🔄 Reloading user...');
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;
      print('✅ User reloaded: uid=${refreshedUser?.uid} emailVerified=${refreshedUser?.emailVerified} email=            ${refreshedUser?.email}');

      print('📝 Syncing emailVerified to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser!.uid)
          .set({'emailVerified': refreshedUser.emailVerified}, SetOptions(merge: true));
      print('✅ Firestore sync success');

      // Importante: o AuthWrapper decide pelo Firebase Auth (emailVerified do currentUser).
      // Recarregamos novamente para garantir que o Auth atual reflita a verificação.
      print('🔄 Reloading user (post-firestore sync)...');
      await refreshedUser.reload();
      final postReloadUser = FirebaseAuth.instance.currentUser;
      print('✅ Post-reload user: uid=${postReloadUser?.uid} emailVerified=${postReloadUser?.emailVerified}');

      final emailVerifiedNow = postReloadUser?.emailVerified ?? false;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = emailVerifiedNow;
        _alreadyVerified = false;
        _message = emailVerifiedNow
            ? 'E-mail confirmado com sucesso. Clique abaixo para entrar.'
            : 'Não foi possível confirmar a verificação no Firebase Auth. Tente novamente ou reenvie o e-mail de verificação.';
      });
      print(emailVerifiedNow ? '✅ Email verification completed successfully' : '⚠️ Email verification still false after reload');
 
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (e.code == 'invalid-action-code' || e.code == 'expired-action-code') {
          _alreadyVerified = true;
          _message = 'Esta verificação já foi concluída. Clique abaixo para entrar.';
        } else {
          _message = 'Falha ao confirmar e-mail: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Erro inesperado: $e';
      });
    }
  }
 
  Future<void> _goToLogin() async {
  // Não faz signOut: senão o usuário sai e volta a ficar sem verificação.
  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const AuthScreen()),
  (route) => false,
  );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _success ? Icons.verified : Icons.email,
                    size: 72,
                    color: _success ? Colors.green : Colors.blueGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loading
                        ? 'Confirmando e-mail...'
                        : (_success ? 'Tudo certo' : 'Atenção'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message ?? 'Processando...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const CircularProgressIndicator(),
                  if (!_loading && (_success || _alreadyVerified))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        child: const Text('Voltar para o login'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 