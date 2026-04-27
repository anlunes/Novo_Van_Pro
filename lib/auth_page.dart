import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _loading = false;
  String? _errorMessage;
  User? _user;
  bool _emailVerified = false;
  String _role = 'motorista';
  bool _showSignup = false;
  
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('🔄 Auth state changed: ${user?.email}');
            if (user != null) {
        print('📧 User email verified: ${user.emailVerified}');
        print('AUTH_PAGE_AUTHSTATE uid=${user.uid} email=${user.email} verified=${user.emailVerified}');
        final wasVerified = _emailVerified;
        setState(() {
          _user = user;
          _emailVerified = user.emailVerified;
        });
        _updateFirestoreVerification(user);
        
        if (!user.emailVerified) {
          _startVerificationCheck();
        } else if (wasVerified != user.emailVerified) {
          _stopVerificationCheck();
        }
      } else {
        setState(() {
          _user = null;
          _emailVerified = false;
        });
        _stopVerificationCheck();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _stopVerificationCheck();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _role = 'motorista';
    _errorMessage = null;
  }

  void _startVerificationCheck() {
    print('🔄 Starting automatic verification check...');
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_user != null && !_emailVerified) {
        print('🔍 Auto-checking verification status...');
        await _user!.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified != _emailVerified) {
          print('✅ Email verification status changed: ${updatedUser.emailVerified}');
          setState(() {
            _emailVerified = updatedUser.emailVerified;
          });
          await _updateFirestoreVerification(updatedUser);
          if (_emailVerified) {
            timer.cancel();
            await _showSnack('E-mail verificado com sucesso!');
          }
        }
      } else if (_emailVerified) {
        timer.cancel();
      }
    });
  }

  void _stopVerificationCheck() {
    print('🛑 Stopping automatic verification check...');
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = null;
  }

  Future<void> _updateFirestoreVerification(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'emailVerified': user.emailVerified,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore verification updated for ${user.email}: ${user.emailVerified}');
    } catch (e) {
      print('❌ Failed to update Firestore verification: $e');
    }
  }

  Future<void> _showSnack(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _authenticate({required bool createAccount}) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (createAccount) {
        print('👤 Creating account for: $email');
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Account created: ${userCredential.user?.uid}');
        print('📧 Initial emailVerified: ${userCredential.user?.emailVerified}');

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });
        await _sendVerificationEmail();
            } else {
        print('🔐 Signing in: $email');
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Sign in successful');

        // ✅ logs para confirmar que a autenticação foi aplicada no app
        final current = FirebaseAuth.instance.currentUser;
        print('AUTH_PAGE_AFTER_SIGNIN currentUser null? ${current == null}');
        print('AUTH_PAGE_AFTER_SIGNIN uid=${current?.uid} email=${current?.email} emailVerified=${current?.emailVerified}');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Auth error: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('❌ Unexpected error: $e');
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Usuário não autenticado.');
      }
      if (user.emailVerified) {
        await _showSnack('E-mail já verificado.');
        return;
      }
      await user.sendEmailVerification();
      await _showSnack('E-mail de verificação enviado. Confira sua caixa de entrada.');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar verificação: $e';
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    setState(() {
      _user = null;
      _emailVerified = false;
      _errorMessage = null;
      _showSignup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VanPro - Autenticação'),
      ),
      body: _user == null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_showSignup) ...[
                          const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (_errorMessage != null)
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _authenticate(createAccount: false),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              setState(() => _showSignup = true);
                              _clearForm();
                            },
                            child: const Text('Criar nova conta'),
                          ),
                        ] else ...[
                          const Text(
                            'Criar conta',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nome completo'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration:
                                const InputDecoration(labelText: 'Celular/Telefone (WhatsApp)'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Informe o telefone' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            items: const [
                              DropdownMenuItem(value: 'motorista', child: Text('motorista')),
                              DropdownMenuItem(
                                  value: 'responsavel', child: Text('responsavel')),
                            ],
                            onChanged: (v) => setState(() => _role = v ?? 'motorista'),
                            decoration: const InputDecoration(labelText: 'Tipo de usuário'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (_errorMessage != null)
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _authenticate(createAccount: true),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Cadastrar e enviar verificação'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              setState(() => _showSignup = false);
                              _clearForm();
                            },
                            child: const Text('Voltar para login'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Usuário: ${_user!.email ?? 'sem e-mail'}'),
                  const SizedBox(height: 12),
                  Text(
                    _emailVerified ? 'E-mail verificado ✅' : 'E-mail não verificado ❌',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _emailVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_emailVerified) ...[
                    const Text('Verificação automática em andamento...'),
                    const SizedBox(height: 8),
                    const Text('Clique no link enviado para seu e-mail.'),
                    const SizedBox(height: 8),
                    const Text('O status será atualizado automaticamente assim que você confirmar.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _sendVerificationEmail,
                      child: const Text('Reenviar e-mail de verificação'),
                    ),
                  ],
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _signOut,
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
    );
  }
}
