import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RankingMotoristaWidget extends StatelessWidget {
  final String motoristaUid;
  final String nomeMotorista;

  const RankingMotoristaWidget({
    super.key,
    required this.motoristaUid,
    required this.nomeMotorista,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('motoristas').doc(motoristaUid).snapshots(),
      builder: (context, motoristaSnapshot) {
        if (motoristaSnapshot.hasError) return const Center(child: Text('Erro ao carregar dados.'));
        if (!motoristaSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final motoristaData = motoristaSnapshot.data!.data() as Map<String, dynamic>?;
        final double mediaGeral = (motoristaData?['mediaGeral'] ?? 0.0).toDouble();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('avaliacoes')
              .where('motoristaUid', isEqualTo: motoristaUid)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Erro ao carregar avaliações.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var avaliacoes = snapshot.data!.docs;

            return Column(
              children: [
                _CardRanking(nome: nomeMotorista, media: mediaGeral, total: avaliacoes.length),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('AVALIAÇÕES RECENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                avaliacoes.isEmpty 
                  ? const Text('Nenhuma avaliação recente.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: avaliacoes.length,
                      itemBuilder: (context, index) => _AvaliacaoItem(data: avaliacoes[index].data() as Map<String, dynamic>),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CardRanking extends StatelessWidget {
  final String nome;
  final double media;
  final int total;

  const _CardRanking({required this.nome, required this.media, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade600]), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.white, size: 32),
              const SizedBox(width: 10),
              Text(media.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text(' / 5.0', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ]),
            Text('$total avaliações', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AvaliacaoItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AvaliacaoItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final double nota = (data['media'] ?? 0).toDouble();
    final String comentario = data['comentario'] ?? '';
    final Timestamp ts = data['timestamp'] ?? Timestamp.now();
    final String dataFormatada = DateFormat('dd/MM/yyyy').format(ts.toDate());

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: List.generate(5, (i) => Icon(i < nota.toInt() ? Icons.star : Icons.star_outline, color: Colors.amber, size: 18))),
              Text(dataFormatada, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
            if (comentario.isNotEmpty) ...[const SizedBox(height: 8), Text(comentario, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic))],
          ],
        ),
      ),
    );
  }
}