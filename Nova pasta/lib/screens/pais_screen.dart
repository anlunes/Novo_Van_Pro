import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/aluno_model.dart';
import '../widgets/aluno_card_pai.dart';
import '../dialogs/manutencao_aluno_dialog.dart';

class PaisScreen extends StatefulWidget {
  const PaisScreen({super.key});

  @override
  State<PaisScreen> createState() => _PaisScreenState();
}

class _PaisScreenState extends State<PaisScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String _nomeResponsavel = '';
  String _vanCode = '';
  String _cidade = '';
  bool _carregandoPerfil = true;

  // Cache de motoristas para nao buscar repetidamente o mesmo vanCode
  final Map<String, Map<String, dynamic>?> _motoristasCache = {};

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nomeResponsavel = data['nome'] ?? data['name'] ?? '';
          _vanCode = data['vanCode'] ?? '';
          _cidade = data['cidade'] ?? data['municipio'] ?? data['city'] ?? '';
          _carregandoPerfil = false;
        });
      } else {
        if (mounted) setState(() => _carregandoPerfil = false);
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  Future<Map<String, dynamic>?> _buscarMotorista(String vanCode) async {
    if (vanCode.isEmpty) return null;
    if (_motoristasCache.containsKey(vanCode)) {
      return _motoristasCache[vanCode];
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('vanCode', isEqualTo: vanCode)
          .where('role', isEqualTo: 'motorista')
          .limit(1)
          .get();
      final resultado =
          snap.docs.isNotEmpty ? snap.docs.first.data() : null;
      _motoristasCache[vanCode] = resultado;
      return resultado;
    } catch (e) {
      _motoristasCache[vanCode] = null;
      return null;
    }
  }

  Future<void> _toggleVaiHoje(Aluno aluno, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(aluno.id)
          .update({
        'vaiHoje': value,
        'cienteMotorista': false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  Future<void> _deletarAluno(Aluno aluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text(
            'Tem certeza que deseja excluir ${aluno.nome}? Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(aluno.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aluno excluido com sucesso.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  void _abrirCadastro() {
    showDialog(  
      context: context,
      builder: (_) => ManutencaoAlunoDialog(
        responsavelUid: uid,
        docId: null,
        vanCode: _vanCode,
        nomeResponsavel: _nomeResponsavel,
        cidadeResponsavel: _cidade,
      ),
    );
  }

  void _abrirEdicao(Aluno aluno) {
    showDialog(
      context: context,
      builder: (_) => ManutencaoAlunoDialog(
        responsavelUid: uid,
        docId: aluno.id,
       alunoExistente: aluno.toMap(),
        vanCode: _vanCode,
        nomeResponsavel: _nomeResponsavel,
        cidadeResponsavel: _cidade,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoPerfil) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meus Alunos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            if (_nomeResponsavel.isNotEmpty)
              Text(
                _nomeResponsavel,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (_vanCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 4),
              child: Chip(
                label: Text(
                  'Van: $_vanCode',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _motoristasCache.clear();
          });
          await _carregarPerfil();
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('alunos')
              .where('responsavelUid', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erro ao carregar alunos.'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_outlined,
                        size: 72,
                        color: Colors.blue.shade200),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum aluno cadastrado ainda.',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque em + Cadastrar para adicionar.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _abrirCadastro,
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Aluno'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Ordenar por campo 'ordem' em memoria para evitar
            // indice composto no Firestore (where + orderBy)
            final alunos = docs
                .map((doc) => Aluno.fromFirestore(doc))
                .toList()
              ..sort((a, b) => a.ordem.compareTo(b.ordem));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alunos.length,
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _buscarMotorista(aluno.vanCode),
                  builder: (context, motoristaSnap) {
                    final motorista =
                        motoristaSnap.data;
                    return AlunoCardPai(
                      aluno: aluno,
                      motorista: motorista,
                      onToggleVaiHoje: (value) =>
                          _toggleVaiHoje(aluno, value),
                      onEdit: () => _abrirEdicao(aluno),
                      onDelete: () => _deletarAluno(aluno),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Cadastrar',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
