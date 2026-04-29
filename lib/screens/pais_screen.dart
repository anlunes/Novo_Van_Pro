import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/aluno_model.dart';
import '../widgets/aluno_card_pai.dart';
import '../dialogs/manutencao_aluno_dialog.dart';

// ── Constantes da API ─────────────────────────────────────────
const String _kApiBasePais  = 'https://novo.balcao2ponto0.com.br/api_alunos.php';
const String _kApiKeyPais   = 'VanPro@2026#Secure';

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

  // ── MIGRAÇÃO 1: Cache dos dados completos do servidor ────────
  // Chave: servidorId.toString() — sobrepõe Firestore para alunos novos
  final Map<String, Map<String, dynamic>> _dadosServidor = {};

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
    _carregarAlunosDoServidor(); // ── MIGRAÇÃO 2: carrega junto com o perfil
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

  // ── MIGRAÇÃO 3: Busca lista completa do servidor ──────────────
  Future<void> _carregarAlunosDoServidor() async {
    try {
      final uri = Uri.parse('$_kApiBasePais?responsavel_uid=$uid');
      final res = await http
          .get(uri, headers: {'X-Api-Key': _kApiKeyPais})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List lista = jsonDecode(res.body);
        final novo = <String, Map<String, dynamic>>{};
        for (final item in lista) {
          final sid = item['id']?.toString();
          if (sid != null) novo[sid] = Map<String, dynamic>.from(item);
        }
        if (mounted) setState(() { _dadosServidor..clear()..addAll(novo); });
      }
    } catch (e) {
      debugPrint('>>> _carregarAlunosDoServidor erro: $e');
    }
  }

  // ── MIGRAÇÃO 4: Converte JSON snake_case do servidor ─────────
  // + mescla com campos operacionais do Firestore (camelCase)
  // REQUER Aluno.fromMapa(String id, Map<String, dynamic> m)
  // → solicite aluno_model.dart para adicionar essa factory
  Map<String, dynamic> _buildMergedMap(
    Map<String, dynamic> fs, // Firestore — 5 campos operacionais (camelCase)
    Map<String, dynamic> s,  // Servidor  — dados completos (snake_case)
  ) {
    return {
      // ── Cadastral do servidor ──────────────────────────────
      'nome':                  s['nome']                     ?? '',
      'nomeEscola':            s['nome_escola']              ?? '',
      'endereco':              s['endereco']                 ?? '',
      'bairro':                s['bairro']                   ?? '',
      'municipio':             s['municipio']                ?? '',
      'estado':                s['estado']                   ?? '',
      'telefone':              s['telefone']                 ?? '',
      'fotoUrl':               s['foto_url']                 ?? '',
      'horarioEntrada':        s['horario_entrada']          ?? '',
      'horarioEntradaMinutos': s['horario_entrada_minutos']  ?? 0,
      'horarioSaida':          s['horario_saida']            ?? '',
      'horarioSaidaMinutos':   s['horario_saida_minutos']    ?? 0,
      'nomeResponsavel':       s['nome_responsavel']         ?? '',
      'vanCode':               s['vanCode']                  ?? '',
      'statusContratacao':     s['status_contratacao']       ?? 'ativo',
      'motivoRecusa':          s['motivo_recusa']            ?? '',
      'valorMensalidade':      s['valor_mensalidade']        ?? 0.0,
      'diaPagamento':          s['dia_pagamento']            ?? 5,
      'pago':                  s['pago'] == 1,
      'ordem':                 s['ordem']                    ?? 0,
      'solicitacaoContato':    s['solicitacao_contato'] == 1,
      'respostaContato':       s['resposta_contato']         ?? '',
      'cienteMotorista':       s['ciente_motorista'] == 1,
      'avaliadoNoCiclo':       s['avaliado_no_ciclo'] == 1,
      'mesAvaliado':           s['mes_avaliado']             ?? '',
      'status':                s['status']                   ?? 'Aguardando',
      'escolaId':              s['escola_id']                ?? '',
      'enderecoEscola':        s['endereco_escola']          ?? '',
      // ── Operacional do Firestore (tempo real) ─────────────
      'responsavelUid':        fs['responsavelUid']          ?? '',
      'servidorId':            fs['servidorId'],
      'statusEmbarque':        fs['statusEmbarque']          ?? 'aguardando',
      'vaiHoje':               fs['vaiHoje']                 ?? true,
    };
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
    // vaiHoje é um dos 5 campos operacionais — permanece no Firestore
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
      // ── Firestore ─────────────────────────────────────────
      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(aluno.id)
          .delete();

      // ── MIGRAÇÃO 5: também apaga no servidor (não bloqueia)
      final sid = aluno.servidorId;
      if (sid != null) {
        http.delete(
          Uri.parse('$_kApiBasePais?id=$sid'),
          headers: {'X-Api-Key': _kApiKeyPais},
        ).catchError((e) => debugPrint('>>> deletarAluno server err: $e'));
        _dadosServidor.remove(sid.toString());
      }

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
    // ── MIGRAÇÃO 6: usa dados merged (servidor + Firestore) na edição ──
    final sid = aluno.servidorId?.toString();
    final serverData = sid != null ? _dadosServidor[sid] : null;
    final fsData = {
      'responsavelUid': aluno.responsavelUid,
      'servidorId':     aluno.servidorId,
      'statusEmbarque': aluno.statusEmbarque,
      'vaiHoje':        aluno.vaiHoje,
    };
    final mapaEdicao = serverData != null
        ? _buildMergedMap(fsData, serverData)
        : aluno.toMap();

    showDialog(
      context: context,
      builder: (_) => ManutencaoAlunoDialog(
        responsavelUid: uid,
        docId: aluno.id,
        alunoExistente: mapaEdicao,
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
        title: const Text('Sair da conta'),
        content: const Text('Deseja mesmo sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

  if (confirmar == true) {
    await FirebaseAuth.instance.signOut();
    // Sem Navigator aqui — o AuthWrapper redireciona automaticamente
  }
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
          // ── MIGRAÇÃO 7: refresh recarrega servidor + limpa caches ──
          _motoristasCache.clear();
          _dadosServidor.clear();
          await Future.wait([
            _carregarPerfil(),
            _carregarAlunosDoServidor(),
          ]);
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

            // ── MIGRAÇÃO 8: monta lista mesclando servidor + Firestore ──
            // Para alunos NOVOS (Firestore só tem 5 campos): usa dados do servidor
            // Para alunos ANTIGOS (Firestore tem tudo): usa Aluno.fromFirestore
            // REQUER Aluno.fromMapa(String id, Map<String, dynamic> m) no model
            final alunos = docs.map((doc) {
              final fsData = doc.data() as Map<String, dynamic>;
              final sid = fsData['servidorId']?.toString();
              if (sid != null && _dadosServidor.containsKey(sid)) {
                final merged = _buildMergedMap(fsData, _dadosServidor[sid]!);
                return Aluno.fromMapa(doc.id, merged);
              }
              // Fallback: aluno antigo com todos os campos no Firestore
              return Aluno.fromFirestore(doc);
            }).toList()
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
