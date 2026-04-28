import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFinanceiroGeralPage extends StatefulWidget {
  const AdminFinanceiroGeralPage({super.key});

  @override
  State<AdminFinanceiroGeralPage> createState() => _AdminFinanceiroGeralPageState();
}

class _AdminFinanceiroGeralPageState extends State<AdminFinanceiroGeralPage> {
  String _filtroStatus = 'ativo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("BI - Faturamento Geral"),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEstatisticas(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  const Text("Filtrar por status:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ativo', label: Text('Ativos')),
                        ButtonSegment(value: 'inadimplente', label: Text('Inadimplentes')),
                        ButtonSegment(value: 'todos', label: Text('Todos')),
                      ],
                      selected: {_filtroStatus},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _filtroStatus = newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildListaAlunos(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alunos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados."));
        if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

        final docs = snapshot.data!.docs;
        double totalFaturamento = 0, faturamentoAtivo = 0, faturamentoInadimplente = 0;
        int totalAlunos = docs.length, alunosAtivos = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final valor = (data['valorMensalidade'] ?? 0.0).toDouble();
          final status = data['statusContratacao'] ?? 'desconhecido';

          totalFaturamento += valor;
          if (status == 'ativo') {
            faturamentoAtivo += valor;
            alunosAtivos++;
          } else if (status == 'inadimplente') {
            faturamentoInadimplente += valor;
          }
        }

        return Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: _buildCard("FATURAMENTO TOTAL", "R\$ ${totalFaturamento.toStringAsFixed(2)}", Colors.deepPurple, Icons.account_balance_wallet)),
                const SizedBox(width: 12),
                Expanded(child: _buildCard("TAXA DE OCUPAÃ‡ÃƒO", "${((alunosAtivos / (totalAlunos > 0 ? totalAlunos : 1)) * 100).toStringAsFixed(1)}%", Colors.green, Icons.trending_up)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCard("ATIVO", "R\$ ${faturamentoAtivo.toStringAsFixed(2)}", Colors.green.shade700, Icons.check_circle)),
                const SizedBox(width: 12),
                Expanded(child: _buildCard("INADIMPLENTE", "R\$ ${faturamentoInadimplente.toStringAsFixed(2)}", Colors.red.shade700, Icons.warning)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: Column(children: [
        Icon(icone, size: 32, color: cor),
        const SizedBox(height: 10),
        Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
        Text(titulo, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildListaAlunos() {
    Query query = FirebaseFirestore.instance.collection('alunos');
    if (_filtroStatus != 'todos') query = query.where('statusContratacao', isEqualTo: _filtroStatus);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar lista."));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final alunos = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: alunos.length,
          itemBuilder: (context, index) {
            final a = alunos[index].data() as Map<String, dynamic>;
            final status = a['statusContratacao'] ?? 'desconhecido';
            final valor = (a['valorMensalidade'] ?? 0.0).toDouble();
            final color = status == 'ativo' ? Colors.green.shade700 : (status == 'inadimplente' ? Colors.red.shade700 : Colors.grey);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(a['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("R\$ ${valor.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ),
            );
          },
        );
      },
    );
  }
}