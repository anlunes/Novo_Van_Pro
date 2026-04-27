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

// Centralização de Configurações
class AppConfig {
  static const String apiBaseUrl = 'https://vanpro.balcao2ponto0.com.br';
  static const String apiKey = 'VanPro2025Secret'; // Recomendado mover para Firebase Remote Config ou Cloud Function
}

// Controller para isolar lógica de negócio
class MotoristaController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> atualizarStatusAluno(String docId, String status, String nomeMotorista, String nomeAluno) async {
    final ehCiencia = (status == 'Confirmado pelo Motorista');
    await _db.collection('alunos').doc(docId).update({
      'status': ehCiencia ? 'Não vai hoje (Confirmado)' : status,
      'ultimaAtualizacao': DateTime.now(),
      if (ehCiencia || status.contains('Avisado')) 'cienteMotorista': true,
    });
    
    // Disparo de notificação (Idealmente via Cloud Function)
    await _dispararNotificacao(docId, ehCiencia ? 'O motorista confirmou seu aviso' : status, nomeMotorista, nomeAluno);
  }

  Future<void> _dispararNotificacao(String alunoId, String msg, String nomeMotorista, String nomeAluno) async {
    try {
      final alunoDoc = await _db.collection('alunos').doc(alunoId).get();
      final respUid = alunoDoc.data()?['responsavelUid'];
      final respDoc = await _db.collection('users').doc(respUid).get();
      final token = respDoc.data()?['fcmToken'];

      if (token != null) {
        await http.post(Uri.parse('${AppConfig.apiBaseUrl}/enviar_notificacao.php'), body: {
          'api_key': AppConfig.apiKey,
          'token_responsavel': token,
          'titulo': 'Van do $nomeMotorista',
          'mensagem': '$nomeAluno: $msg',
        });
      }
    } catch (e) { debugPrint('Erro notificação: $e'); }
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
  final _controller = MotoristaController();
  
  // Stream para evitar múltiplas leituras do FutureBuilder
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots();
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
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: TabBarView(
              children: [
                AbaChamadaWidget(
                  // ← CORRIGIDO: vanCode removido (não existe no widget)
                  onStatusChanged: () => null, // ← temporário até aluno_model ter telefone
                  onWhatsAppPressed: _abrirWhatsApp,
                  onReplyContact: (id) => FirebaseFirestore.instance.collection('alunos').doc(id).update({'solicitacaoContato': false, 'respostaContato': 'Ciente.'}),
                  onReorder: (lista) => _salvarNovaOrdem(lista),
                  onPaymentStatusChanged: _alternarPagamento,
                ),
                AbaOportunidadesWidget(motoristaUid: widget.uid, cidadeMotorista: userData['atend_municipio'] ?? ''),
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
      IconButton(icon: const Icon(Icons.monetization_on), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GestaoPagamentosScreen())); }),
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
    final url = 'https://wa.me/55${telefone.replaceAll(RegExp(r'[^\\d]'), '')}?text=Sobre o aluno $nomeAluno: ';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _alternarPagamento(String docId, bool statusAtual) async {
    await FirebaseFirestore.instance.collection('alunos').doc(docId).update({'pago': !statusAtual});
  }

  void _salvarNovaOrdem(List<dynamic> lista) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < lista.length; i++) {
      batch.update(FirebaseFirestore.instance.collection('alunos').doc(lista[i].id), {'ordem': i});
    }
    await batch.commit();
  }
}