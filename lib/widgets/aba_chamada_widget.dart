import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/aluno_model.dart';
import 'aluno_card.dart';

const String _kApiBaseAba = 'https://novo.balcao2ponto0.com.br/api_alunos.php';
const String _kApiKeyAba  = 'VanPro@2026#Secure';

class StatusAluno {
  static const String aguardando = 'Aguardando a Van';
  static const String embarcado  = 'embarcado';
  static const String naoVai     = 'Não vai hoje (Avisado)';
}

class AbaChamadaWidget extends StatefulWidget {
  final String vanCode;
  final VoidCallback?              onStatusChanged;
  final Function(String?, String)? onWhatsAppPressed;
  final Function(String)?          onReplyContact;
  final Function(List<Aluno>)?     onReorder;
  final Function(String, bool)?    onPaymentStatusChanged;

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
  // Índice 1: chave = servidorId (alunos novos)
  final Map<String, Map<String, dynamic>> _dadosServidor = {};
  // Índice 2: chave = firebase_status_id (alunos antigos sem servidorId no Firestore)
  final Map<String, Map<String, dynamic>> _dadosServidorPorFirebaseId = {};

  @override
  void initState() {
    super.initState();
    if (widget.vanCode.isNotEmpty) _carregarAlunosDoServidor();
  }

  @override
  void didUpdateWidget(AbaChamadaWidget old) {
    super.didUpdateWidget(old);
    if (old.vanCode != widget.vanCode && widget.vanCode.isNotEmpty) {
      _dadosServidor.clear();
      _dadosServidorPorFirebaseId.clear();
      _carregarAlunosDoServidor();
    }
  }

  Future<void> _carregarAlunosDoServidor() async {
    try {
      final uri = Uri.parse('$_kApiBaseAba?van_code=${widget.vanCode}');
      final res = await http
          .get(uri, headers: {'X-Api-Key': _kApiKeyAba})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List lista = jsonDecode(res.body);
        final novoPorSid = <String, Map<String, dynamic>>{};
        final novoPorFid = <String, Map<String, dynamic>>{};
        for (final item in lista) {
          final map = Map<String, dynamic>.from(item);
          final sid = item['id']?.toString();
          if (sid != null) novoPorSid[sid] = map;
          final fid = item['firebase_status_id']?.toString();
          if (fid != null && fid.isNotEmpty) novoPorFid[fid] = map;
        }
        if (mounted) {
          setState(() {
            _dadosServidor..clear()..addAll(novoPorSid);
            _dadosServidorPorFirebaseId..clear()..addAll(novoPorFid);
          });
        }
      }
    } catch (e) {
      debugPrint('>>> AbaChamada _carregarServidor erro: $e');
    }
  }

  Map<String, dynamic>? _resolverServidor(Map<String, dynamic> fsData, String docId) {
    final sid = fsData['servidorId']?.toString();
    if (sid != null) return _dadosServidor[sid];
    return _dadosServidorPorFirebaseId[docId];
  }

  Map<String, dynamic> _buildMergedMap(
    Map<String, dynamic> fs,
    Map<String, dynamic> s,
  ) {
    return {
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
      'responsavelUid': fs['responsavelUid'] ?? '',
      // servidorId: prefere o do Firestore; usa s['id'] para alunos antigos
      'servidorId':     fs['servidorId'] ?? s['id'],
      'statusEmbarque': fs['statusEmbarque'] ?? 'aguardando',
      'vaiHoje':        fs['vaiHoje'] ?? true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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

              final alunos = snapshot.data!.docs.map((doc) {
                final fsData     = doc.data() as Map<String, dynamic>;
                final serverData = _resolverServidor(fsData, doc.id);
                if (serverData != null) {
                  return Aluno.fromMapa(doc.id, _buildMergedMap(fsData, serverData));
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
