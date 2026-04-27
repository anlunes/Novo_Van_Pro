import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListaChamadaScreen extends StatefulWidget {
  const ListaChamadaScreen({super.key});

  @override
  State<ListaChamadaScreen> createState() => _ListaChamadaScreenState();
}

class _ListaChamadaScreenState extends State<ListaChamadaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isReordering = false;

  Future<void> _marcarEmbarque(String alunoId, String alunoNome) async {
    try {
      await _firestore.collection('alunos').doc(alunoId).update({
        'status_embarque': 'embarcado',
        'timestamp_embarque': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao embarcar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Usuário não autenticado")));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lista de Chamada'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String vanCode = userData['vanCode'] ?? "";
          final String nomeMotorista = userData['nome'] ?? "Motorista";

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('alunos')
                .where('vanCode', isEqualTo: vanCode)
                .orderBy('ordem')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final alunos = snapshot.data!.docs;
              final int embarcados = alunos.where((d) => (d['status_embarque'] ?? '') == 'embarcado').length;

              return Column(
                children: [
                  _buildHeader(nomeMotorista, alunos.length, embarcados),
                  Expanded(
                    child: _isReordering 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildListaAlunos(alunos),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(String nome, int total, int embarcados) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    color: Colors.amber.shade100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Motorista: $nome", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total: $total", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
              child: Text("Embarcados: $embarcados", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildListaAlunos(List<QueryDocumentSnapshot> alunos) {
    if (alunos.isEmpty) return const Center(child: Text("Nenhum aluno cadastrado."));

    return ReorderableListView.builder(
      itemCount: alunos.length,
      padding: const EdgeInsets.all(12),
      onReorder: (oldIndex, newIndex) async {
        setState(() => _isReordering = true);
        if (newIndex > oldIndex) newIndex--;
        final alunosList = alunos.toList();
        final item = alunosList.removeAt(oldIndex);
        alunosList.insert(newIndex, item);
        
        final batch = _firestore.batch();
        for (int i = 0; i < alunosList.length; i++) {
          batch.update(_firestore.collection('alunos').doc(alunosList[i].id), {'ordem': i});
        }
        await batch.commit();
        setState(() => _isReordering = false);
      },
      itemBuilder: (context, index) => AlunoCard(key: ValueKey(alunos[index].id), doc: alunos[index], onEmbarcar: _marcarEmbarque),
    );
  }
}

class AlunoCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Function(String, String) onEmbarcar;

  const AlunoCard({super.key, required this.doc, required this.onEmbarcar});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final bool embarcado = (data['status_embarque'] ?? '') == 'embarcado';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(embarcado ? '✓ Embarcado' : '⏳ Aguardando', style: TextStyle(color: embarcado ? Colors.green : Colors.orange)),
        trailing: embarcado ? const Icon(Icons.check_circle, color: Colors.green) : ElevatedButton(
          onPressed: () => onEmbarcar(doc.id, data['nome']),
          child: const Text('EMBARCAR'),
        ),
      ),
    );
  }
}