import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verification_pending_screen.dart';
import '../wrappers/auth_wrapper.dart';
 
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
 
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
 
class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
 
  bool _isCadastro = false;
  bool _loading = false;
  bool _senhaVisivel = false;
  String _roleSelecionado = 'responsavel';
 
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
 
  void _toggleModo() {
    setState(() {
      _isCadastro = !_isCadastro;
      _formKey.currentState?.reset();
      _roleSelecionado = 'responsavel';
    });
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
 
    if (_isCadastro) {
      final error = await _authService.signUp(
        name: _nomeController.text,
        phone: _telefoneController.text,
        email: _emailController.text,
        password: _senhaController.text,
        role: _roleSelecionado,
      );
 
      if (!mounted) return;
 
      setState(() => _loading = false);
 
      if (error != null) {
        _showError(error);
        return;
      }
 
      // ✅ CORRIGIDO: Removido 'const' e adicionado email
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerificationPendingScreen(
            email: _emailController.text,
          ),
        ),
      );
      return;
    }
 
    final error = await _authService.login(
      email: _emailController.text,
      password: _senhaController.text,
    );
 
    if (!mounted) return;
 
    setState(() => _loading = false);
 
        if (error != null) {
      if (error == 'E-mail não verificado.') {
        // ✅ CORRIGIDO: Removido 'const' e adicionado email
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationPendingScreen(
              email: _emailController.text,
            ),
          ),
        );
        return;
      }
      _showError(error);
      return;
    }

    // ✅ Login OK: redireciona para o gate que decide Motorista vs Responsável
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthWrapper(),
      ),
    );
  }
 
  Future<void> _resetSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Informe o e-mail para redefinir a senha.');
      return;
    }
 
    setState(() => _loading = true);
    try {
      final error = await _authService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'E-mail de redefinição enviado para $email.'),
          backgroundColor: error != null ? Colors.redAccent : Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildLogo() => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.directions_bus, size: 52, color: Colors.blueGrey),
          ),
          const SizedBox(height: 16),
          const Text(
            'VanPro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestão inteligente de transporte escolar',
            style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
 
  Widget _buildCard() => Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isCadastro ? 'Criar conta' : 'Entrar',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isCadastro) ...[
                  _campo(
                    controller: _nomeController,
                    label: 'Nome completo',
                    icone: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.trim().length < 3 ? 'Informe seu nome completo.' : null,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _telefoneController,
                    label: 'Telefone / WhatsApp',
                    icone: Icons.phone_outlined,
                    teclado: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.trim().length < 8 ? 'Informe um telefone válido.' : null,
                  ),
                  const SizedBox(height: 14),
                ],
                _campo(
                  controller: _emailController,
                  label: 'E-mail',
                  icone: Icons.email_outlined,
                  teclado: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Informe um e-mail válido.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres.' : null,
                ),
                const SizedBox(height: 14),
                if (_isCadastro) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Você é:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text('Responsável'),
                    value: 'responsavel',
                    groupValue: _roleSelecionado,
                    onChanged: (value) {
                      setState(() {
                        _roleSelecionado = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Motorista'),
                    value: 'motorista',
                    groupValue: _roleSelecionado,
                    onChanged: (value) {
                      setState(() {
                        _roleSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (!_isCadastro)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _resetSenha,
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.blueGrey.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            _isCadastro ? 'CRIAR CONTA' : 'ENTRAR',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCadastro ? 'Já tem uma conta?' : 'Não tem conta ainda?',
                    ),
                    TextButton(
                      onPressed: _loading ? null : _toggleModo,
                      child: Text(
                        _isCadastro ? 'Entrar' : 'Criar conta',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
 
  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icone),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator,
      );
}