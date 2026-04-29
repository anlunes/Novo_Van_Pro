import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/aluno_model.dart';
import 'aluno_card.dart';

// ── Constantes da API ─────────────────────────────────────────
const String _kApiBaseAba = 'https://novo.balcao2ponto0.com.br/api_alunos.php';
const String _kApiKeyAba  = 'VanPro@2026#Secure';

class StatusAluno {
  static const String aguardando = 'Aguardando a Van';
  static const String embarcado  = 'embarcado';
  static const String naoVai     = 'Não vai hoje (Avisado)';
}

class AbaChamadaWidget extends StatefulWidget {
  // ── MIGRAÇÃO 1: vanCode agora obrigatório ────────────────────
  // Necessário para filtrar alunos da van correta no Firestore e
  // no servidor. Antes, o query buscava TODOS os alunos da coleção.
  final String vanCode;

  final VoidCallback?            onStatusChanged;
  final Function(String?, String)? onWhatsAppPressed;
  final Function(String)?        onReplyContact;
  final Function(List<Aluno>)?   onReorder;
  final Function(String, bool)?  onPaymentStatusChanged;

  const AbaChamadaWidget({
    super.key,
    required this.vanCode,
    this.onStatusChanged,
    this.onWhatsAppPressed,
    this.onReplyContact,
    this.onReorder,
    this.onPaymentStatusChanged,
  });

  @override
  State<AbaChamadaWidget> createState() => _AbaChamadaWidgetState();
}

class _AbaChamadaWidgetState extends State<AbaChamadaWidget> {
  // ── MIGRAÇÃO 2: cache dos dados completos do servidor ─────────
  // Chave: servidorId.toString()
  final Map<String, Map<String, dynamic>> _dadosServidor = {};

  @override
  void initState() {
    super.initState();
    if (widget.vanCode.isNotEmpty) _carregarAlunosDoServidor();
  }

  @override
  void didUpdateWidget(AbaChamadaWidget old) {
    super.didUpdateWidget(old);
    // Se o vanCode mudou (troca de conta etc.), recarrega do servidor
    if (old.vanCode != widget.vanCode && widget.vanCode.isNotEmpty) {
      _dadosServidor.clear();
      _carregarAlunosDoServidor();
    }
  }

  // ── MIGRAÇÃO 3: busca lista por van_code no servidor ──────────
  Future<void> _carregarAlunosDoServidor() async {
    try {
      final uri = Uri.parse('$_kApiBaseAba?van_code=${widget.vanCode}');
      final res = await http
          .get(uri, headers: {'X-Api-Key': _kApiKeyAba})
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
      debugPrint('>>> AbaChamada _carregarServidor erro: $e');
    }
  }

  // ── MIGRAÇÃO 4: mescla servidor (snake_case) + Firestore (operacional) ──
  Map<String, dynamic> _buildMergedMap(
    Map<String, dynamic> fs, // Firestore — 5 campos operacionais
    Map<String, dynamic> s,  // Servidor  — dados completos
  ) {
    return {
      // Cadastral do servidor
      'nome':                  s['nome']                    ?? '',
      'nomeEscola':            s['nome_escola']             ?? '',
      'endereco':              s['endereco']                ?? '',
      'bairro':                s['bairro']                  ?? '',
      'municipio':             s['municipio']               ?? '',
      'estado':                s['estado']                  ?? '',
      'telefone':              s['telefone']                ?? '',
      'fotoUrl':               s['foto_url']                ?? '',
      'horarioEntrada':        s['horario_entrada']         ?? '',
      'horarioEntradaMinutos': s['horario_entrada_minutos'] ?? 0,
      'horarioSaida':          s['horario_saida']           ?? '',
      'horarioSaidaMinutos':   s['horario_saida_minutos']   ?? 0,
      'nomeResponsavel':       s['nome_responsavel']        ?? '',
      'vanCode':               s['vanCode']                 ?? widget.vanCode,
      'statusContratacao':     s['status_contratacao']      ?? 'ativo',
      'motivoRecusa':          s['motivo_recusa']           ?? '',
      'valorMensalidade':      s['valor_mensalidade']       ?? 0.0,
      'diaPagamento':          s['dia_pagamento']           ?? 5,
      'pago':                  s['pago'] == 1,
      'ordem':                 s['ordem']                   ?? 0,
      'solicitacaoContato':    s['solicitacao_contato'] == 1,
      'respostaContato':       s['resposta_contato']        ?? '',
      'cienteMotorista':       s['ciente_motorista'] == 1,
      'avaliadoNoCiclo':       s['avaliado_no_ciclo'] == 1,
      'mesAvaliado':           s['mes_avaliado']            ?? '',
      'status':                s['status']                  ?? 'Aguardando',
      'escolaId':              s['escola_id']               ?? '',
      'enderecoEscola':        s['endereco_escola']         ?? '',
      // Operacional do Firestore (tempo real)
      'responsavelUid':        fs['responsavelUid']         ?? '',
      'servidorId':            fs['servidorId'],
      'statusEmbarque':        fs['statusEmbarque']         ?? 'aguardando',
      'vaiHoje':               fs['vaiHoje']                ?? true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // ── MIGRAÇÃO 5: filtro por vanCode (antes sem filtro!) ──
            // Ordenação feita em memória para evitar índice composto
            stream: FirebaseFirestore.instance
                .collection('alunos')
                .where('vanCode', isEqualTo: widget.vanCode)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nenhum aluno encontrado'));
              }

              final docs = snapshot.data!.docs;

              // ── MIGRAÇÃO 6: mescla servidor + Firestore ───────────
              // Alunos NOVOS: Firestore só tem 5 campos → usa servidor
              // Alunos ANTIGOS: Firestore tem tudo → fromFirestore
              final alunos = docs.map((doc) {
                final fsData = doc.data() as Map<String, dynamic>;
                final sid = fsData['servidorId']?.toString();
                if (sid != null && _dadosServidor.containsKey(sid)) {
                  return Aluno.fromMapa(
                    doc.id,
                    _buildMergedMap(fsData, _dadosServidor[sid]!),
                  );
                }
                return Aluno.fromFirestore(doc);
              }).toList()
                ..sort((a, b) => a.ordem.compareTo(b.ordem));

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final lista = List<Aluno>.from(alunos);
                  final item  = lista.removeAt(oldIndex);
                  lista.insert(newIndex, item);
                  setState(() {});
                  widget.onReorder?.call(lista);
                },
                children: alunos.asMap().entries.map((entry) {
                  final aluno = entry.value;
                  return AlunoCard(
                    key: Key(aluno.id),
                    aluno: aluno,
                    mostrarHandleDrag: true,
                    tipoRota: TipoRota.ida,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
