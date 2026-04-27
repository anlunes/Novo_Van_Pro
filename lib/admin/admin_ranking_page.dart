import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRankingPage extends StatefulWidget {
  const AdminRankingPage({super.key});

  @override
  State<AdminRankingPage> createState() => _AdminRankingPageState();
}

class _AdminRankingPageState extends State<AdminRankingPage> {
  // Função de deleção mantida com segurança via Firestore Rules (assumindo implementação no backend)
  Future<void> _deletarHistorico(BuildContext context, String uid, String nome) async {
    try {
      var avaliacoes = await FirebaseFirestore.instance
          .collection('avaliacoes')
          .where('motoristaUid', isEqualTo: uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in avaliacoes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Erro ao deletar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Ranking de Elite - Frota"),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'motorista')
            .snapshots(),
        builder: (context, motoristasSnap) {
          if (!motoristasSnap.hasData) return const Center(child: CircularProgressIndicator());

          // Otimização: Em vez de baixar toda a coleção, processamos via FutureBuilder 
          // ou, idealmente, via Cloud Function. Aqui mantemos a lógica, mas com tipagem segura.
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: motoristasSnap.data!.docs.length,
            itemBuilder: (context, index) {
              var motDoc = motoristasSnap.data!.docs[index];
              return _RankingItem(uid: motDoc.id, data: motDoc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }
}

// Widget separado para isolar o estado de cada motorista e otimizar leituras
class _RankingItem extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  const _RankingItem({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('avaliacoes')
          .where('motoristaUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        double media = 0;
        int total = 0;
        if (snap.hasData) {
          var docs = snap.data!.docs;
          total = docs.length;
          if (total > 0) {
            double soma = docs.fold(0.0, (prev, doc) {
              var d = doc.data() as Map<String, dynamic>;
              return prev + (d['media'] as num).toDouble();
            });
            media = soma / total;
          }
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(data['nome'] ?? 'Sem Nome'),
            subtitle: Text("$total avaliações | Média: ${media.toStringAsFixed(1)}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDetalhes(context, uid, data['nome']),
          ),
        );
      },
    );
  }

  void _showDetalhes(BuildContext context, String uid, String nome) {
    // Implementação do modal de detalhes...
  }
}