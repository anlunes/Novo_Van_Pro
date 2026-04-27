import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';

// Classe de suporte para encapsular a lógica de negócio
class DashboardData {
  final int motoristas;
  final int alunosAtivos;
  final int alunosInadimplentes;
  final int totalAlunos;
  final int escolasHomologadas;
  final int escolasPendentes;
  final double taxaConversao;

  DashboardData(List<QuerySnapshot> snapshots)
      : motoristas = snapshots[0].docs.length,
        totalAlunos = snapshots[1].docs.length,
        alunosAtivos = snapshots[1].docs.where((d) => (d.data() as Map)['statusContratacao'] == 'ativo').length,
        alunosInadimplentes = snapshots[1].docs.where((d) => (d.data() as Map)['statusContratacao'] == 'inadimplente').length,
        escolasHomologadas = snapshots[2].docs.where((d) => (d.data() as Map)['status'] == 'homologado').length,
        escolasPendentes = snapshots[2].docs.where((d) => (d.data() as Map)['status'] == 'pendente').length,
        taxaConversao = snapshots[0].docs.isNotEmpty ? ((snapshots[1].docs.where((d) => (d.data() as Map)['statusContratacao'] == 'ativo').length / snapshots[0].docs.length) * 100) : 0.0;
}

class AdminInteligenciaPage extends StatelessWidget {
  const AdminInteligenciaPage({super.key});

  Stream<DashboardData> get _dashboardStream {
    return StreamZip([
      FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'motorista').snapshots(),
      FirebaseFirestore.instance.collection('alunos').snapshots(),
      FirebaseFirestore.instance.collection('colegios').snapshots(),
    ]).map((snapshots) => DashboardData(snapshots));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Inteligência & Expansão"),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DashboardData>(
        stream: _dashboardStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildIndicadoresGrid(data),
                const SizedBox(height: 25),
                _buildAnaliseAlunos(data),
                const SizedBox(height: 25),
                _buildGestaoEscolas(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Dashboard de Inteligência", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text("Métricas e insights do sistema VanPro", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 20),
    ],
  );

  Widget _buildIndicadoresGrid(DashboardData data) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.2,
    children: [
      _buildMetricaCard("VANS ATIVAS", data.motoristas.toString(), Colors.blue, Icons.directions_bus),
      _buildMetricaCard("ALUNOS TOTAIS", data.totalAlunos.toString(), Colors.green, Icons.person),
      _buildMetricaCard("ESCOLAS HOMOLOGADAS", data.escolasHomologadas.toString(), Colors.deepPurple, Icons.school),
      _buildMetricaCard("TAXA DE CONVERSÃO", "${data.taxaConversao.toStringAsFixed(1)}%", Colors.orange, Icons.trending_up),
    ],
  );

  Widget _buildAnaliseAlunos(DashboardData data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Column(children: [
            Text("Ativos: ${data.alunosAtivos}"),
            Text("Inadimplentes: ${data.alunosInadimplentes}"),
          ])),
          Text("${((data.alunosAtivos / (data.totalAlunos > 0 ? data.totalAlunos : 1)) * 100).toStringAsFixed(1)}% Saúde")
        ],
      ),
    ),
  );

  Widget _buildGestaoEscolas(DashboardData data) => Card(
    child: Column(children: [
      ListTile(title: const Text("Homologadas"), trailing: Text("${data.escolasHomologadas}")),
      ListTile(title: const Text("Pendentes"), trailing: Text("${data.escolasPendentes}")),
    ]),
  );

  Widget _buildMetricaCard(String t, String v, Color c, IconData i) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c)), Text(t, style: const TextStyle(fontSize: 9))]),
  );
}