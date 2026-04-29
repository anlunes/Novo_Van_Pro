import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:van_pro_novo/screens/gestao_pagamentos_screen.dart';
import 'package:van_pro_novo/models/aluno_model.dart';
import 'package:van_pro_novo/services/tracking_service.dart';
import 'package:van_pro_novo/screens/auth_screen.dart';
import 'package:van_pro_novo/widgets/aba_chamada_widget.dart';
import 'package:van_pro_novo/widgets/aba_oportunidades_widget.dart';

class AppConfig {
  static const String apiBaseUrl   = 'https://vanpro.balcao2ponto0.com.br';
  static const String apiKey       = 'VanPro2025Secret';
  static const String apiAlunosUrl = 'https://novo.balcao2ponto0.com.br/api_alunos.php';
  static const String apiAlunosKey = 'VanPro@2026#Secure';
}

class MotoristaController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> atualizarStatusAluno(
    String docId,
    String status,
    String nomeMotorista,
    String nomeAluno,
  ) async {
    final ehCiencia      = (status == 'Confirmado pelo Motorista');
    final novoStatus     = ehCiencia ? 'Não vai hoje (Confirmado)' : status;
    final cienteAtualiz  = ehCiencia || status.contains('Avisado');

    await _db.collection('alunos').doc(docId).update({
      'status': novoStatus,
      'ultimaAtualizacao': DateTime.now(),
      if (cienteAtualiz) 'cienteMotorista': true,
    });

    try {
      final doc = await _db.collection('alunos').doc(docId).get();
      final sid = doc.data()?['servidorId'];
      if (sid != null) {
        final patch = <String, dynamic>{'status': novoStatus};
        if (cienteAtualiz) patch['ciente_motorista'] = 1;
        http.patch(
          Uri.parse('${AppConfig.apiAlunosUrl}?id=$sid'),
          headers: {'Content-Type': 'application/json', 'X-Api-Key': AppConfig.apiAlunosKey},
          body: jsonEncode(patch),
        ).catchError((e) => debugPrint('>>> atualizarStatus server err: $e'));
      }
    } catch (e) {
      debugPrint('>>> atualizarStatus server fetch err: $e');
    }

    await _dispararNotificacao(
      docId,
      ehCiencia ? 'O motorista confirmou seu aviso' : status,
      nomeMotorista,
      nomeAluno,
    );
  }

  Future<void> _dispararNotificacao(
    String alunoId, String msg, String nomeMotorista, String nomeAluno,
  ) async {
    try {
      final alunoDoc = await _db.collection('alunos').doc(alunoId).get();
      final respUid  = alunoDoc.data()?['responsavelUid'];
      final respDoc  = await _db.collection('users').doc(respUid).get();
      final token    = respDoc.data()?['fcmToken'];
      if (token != null) {
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/enviar_notificacao.php'),
          body: {
            'api_key'           : AppConfig.apiKey,
            'token_responsavel' : token,
            'titulo'            : 'Van do $nomeMotorista',
            'mensagem'          : '$nomeAluno: $msg',
          },
        );
      }
    } catch (e) {
      debugPrint('Erro notificação: $e');
    }
  }
}

class MotoristaScreen extends StatefulWidget {
  final String uid;
  const MotoristaScreen({super.key, required this.uid});

  @override
  State<MotoristaScreen> createState() => _MotoristaScreenState();
}

class _MotoristaScreenState extends State<MotoristaScreen> {
  final _trackingService = TrackingService();
  final _controller      = MotoristaController();
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots();
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        // ── MIGRAÇÃO: vanCode extraído do perfil do motorista ───
        final vanCode  = userData['vanCode'] as String? ?? '';

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: TabBarView(
              children: [
                AbaChamadaWidget(
                  vanCode: vanCode, // ← NOVO: passa vanCode obrigatório
                  onStatusChanged: () => null,
                  onWhatsAppPressed: _abrirWhatsApp,
                  onReplyContact: (id) => FirebaseFirestore.instance
                      .collection('alunos')
                      .doc(id)
                      .update({'solicitacaoContato': false, 'respostaContato': 'Ciente.'}),
                  onReorder: (lista) => _salvarNovaOrdem(lista),
                  onPaymentStatusChanged: _alternarPagamento,
                ),
                AbaOportunidadesWidget(
                  motoristaUid: widget.uid,
                  cidadeMotorista: userData['atend_municipio'] ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text('VanPro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        bottom: const TabBar(tabs: [Tab(text: 'CHAMADA'), Tab(text: 'OPORTUNIDADES')]),
        actions: [
          IconButton(
            icon: const Icon(Icons.monetization_on),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GestaoPagamentosScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      );

  void _abrirWhatsApp(String? telefone, String nomeAluno) async {
    if (telefone == null || telefone.isEmpty) return;
    final url =
        'https://wa.me/55${telefone.replaceAll(RegExp(r'[^\d]'), '')}?text=Sobre o aluno $nomeAluno: ';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _alternarPagamento(String docId, bool statusAtual) async {
    final novoValor = !statusAtual;
    await FirebaseFirestore.instance
        .collection('alunos')
        .doc(docId)
        .update({'pago': novoValor});
    try {
      final doc = await FirebaseFirestore.instance.collection('alunos').doc(docId).get();
      final sid = doc.data()?['servidorId'];
      if (sid != null) {
        http.patch(
          Uri.parse('${AppConfig.apiAlunosUrl}?id=$sid'),
          headers: {'Content-Type': 'application/json', 'X-Api-Key': AppConfig.apiAlunosKey},
          body: jsonEncode({'pago': novoValor ? 1 : 0}),
        ).catchError((e) => debugPrint('>>> alternarPagamento server err: $e'));
      }
    } catch (e) {
      debugPrint('>>> alternarPagamento servidorId fetch err: $e');
    }
  }

  void _salvarNovaOrdem(List<dynamic> lista) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < lista.length; i++) {
      batch.update(
        FirebaseFirestore.instance.collection('alunos').doc(lista[i].id),
        {'ordem': i},
      );
    }
    await batch.commit();
    for (int i = 0; i < lista.length; i++) {
      final sid = (lista[i] as Aluno).servidorId;
      if (sid != null) {
        http.patch(
          Uri.parse('${AppConfig.apiAlunosUrl}?id=$sid'),
          headers: {'Content-Type': 'application/json', 'X-Api-Key': AppConfig.apiAlunosKey},
          body: jsonEncode({'ordem': i}),
        ).catchError((e) => debugPrint('>>> salvarOrdem server err: $e'));
      }
    }
  }
}
