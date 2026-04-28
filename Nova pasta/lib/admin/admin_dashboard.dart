import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart'; // Adicionado para combinar streams
import 'admin_escolas_page.dart';
import 'admin_documentos_page.dart';
import 'admin_ranking_page.dart';
import 'admin_inteligencia_page.dart';
import 'admin_brasil_escolas_page.dart';

// Modelo para itens do menu
class MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;
  final bool isEnabled;

  MenuItem(this.title, this.icon, this.color, {this.page, this.isEnabled = true});
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  List<MenuItem> _getMenuItems() => [
        MenuItem("Novas Escolas", Icons.school, Colors.blue, page: const AdminEscolasPage()),
        MenuItem("Documentos", Icons.verified_user, Colors.green, page: const AdminDocumentosPage()),
        MenuItem("Ranking", Icons.star, Colors.amber, page: const AdminRankingPage()),
        MenuItem("InteligÃªncia", Icons.insights, Colors.teal, page: const AdminInteligenciaPage()),
        MenuItem("Brasil Escolas", Icons.public, Colors.orange, page: const AdminBrasilEscolasPage()),
        MenuItem("Financeiro", Icons.account_balance_wallet, Colors.deepPurple, isEnabled: false),
        MenuItem("AnÃºncios", Icons.ads_click, Colors.redAccent, isEnabled: false),
      ];

  @override
  Widget build(BuildContext context) {
    double largura = MediaQuery.of(context).size.width;
    int colunas = largura > 900 ? 6 : (largura > 600 ? 4 : 3);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Central VanPro - EscritÃ³rio"),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _confirmarSaida(context),
            tooltip: "Sair",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickStats(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _getMenuItems().length,
              itemBuilder: (context, index) {
                final item = _getMenuItems()[index];
                return _cardMenu(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        decoration: BoxDecoration(color: Colors.blueGrey.shade800),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PAINEL DE COMANDO", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("GestÃ£o de Elite VanPro", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _buildQuickStats() {
    final motoristasStream = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'motorista').snapshots();
    final alunosStream = FirebaseFirestore.instance.collection('alunos').snapshots();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade800,
      child: StreamBuilder<List<QuerySnapshot>>(
        stream: CombineLatestStream.list([motoristasStream, alunosStream]),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text("Erro ao carregar dados", style: TextStyle(color: Colors.white));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

          final totalVans = snapshot.data![0].docs.length;
          final totalAlunos = snapshot.data![1].docs.length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("VANS ATIVAS", totalVans.toString(), Icons.directions_bus),
              _statItem("ALUNOS TOTAIS", totalAlunos.toString(), Icons.person),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String valor, IconData icone) => Column(
        children: [
          Icon(icone, color: Colors.amber, size: 28),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _cardMenu(BuildContext context, MenuItem item) => InkWell(
        onTap: item.isEnabled && item.page != null
            ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => item.page!))
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: item.isEnabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: item.isEnabled ? item.color : Colors.grey),
              const SizedBox(height: 8),
              Text(item.title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: item.isEnabled ? Colors.black87 : Colors.grey)),
            ],
          ),
        ),
      );

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(children: [Icon(Icons.exit_to_app, color: Colors.redAccent), SizedBox(width: 10), Text("Encerrar SessÃ£o?")]),
        content: const Text("Deseja realmente sair da Central Administrativa VanPro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("SAIR AGORA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}