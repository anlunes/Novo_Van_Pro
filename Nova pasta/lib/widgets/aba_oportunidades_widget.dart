import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/aluno_model.dart';

class AlunoService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> aceitarAluno(String docId, String motoristaUid) async {
    final motoristaDoc = await _db.collection('users').doc(motoristaUid).get();
    final vanCode = motoristaDoc.data()?['vanCode'] ?? '';
    
    await _db.collection('alunos').doc(docId).update({
      'vanCode': vanCode,
      'statusContratacao': 'ativo',
    });
  }

  static Future<void> recusarAluno(String docId, String motivo) async {
    await _db.collection('alunos').doc(docId).update({
      'statusContratacao': 'recusado',
      'motivoRecusa': motivo.isEmpty ? 'Recusado pelo motorista' : motivo,
    });
  }
}

class AbaOportunidadesWidget extends StatefulWidget {
  final String motoristaUid;
  final String cidadeMotorista;

  const AbaOportunidadesWidget({super.key, required this.motoristaUid, required this.cidadeMotorista});

  @override
  State<AbaOportunidadesWidget> createState() => _AbaOportunidadesWidgetState();
}

class _AbaOportunidadesWidgetState extends State<AbaOportunidadesWidget> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alunos')
                .where('municipio', isEqualTo: widget.cidadeMotorista)
                .where('vanCode', isEqualTo: '')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs;

              if (docs.isEmpty) return const Center(child: Text('Nenhuma oportunidade encontrada.'));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildOportunidadeCard(Aluno.fromFirestore(docs[index]), docs[index].id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOportunidadeCard(Aluno aluno, String id) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aluno.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Cidade: ${aluno.municipio}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Endereço: ${aluno.endereco ?? 'Não informado'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _isProcessing ? null : () => _aceitarAluno(aluno, id),
                            child: const Text('ACEITAR', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _isProcessing ? null : () => _recusarAluno(aluno, id),
                            child: const Text('RECUSAR', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aceitarAluno(Aluno aluno, String docId) async {
    setState(() => _isProcessing = true);
    try {
      await AlunoService.aceitarAluno(docId, widget.motoristaUid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aluno aceito!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _recusarAluno(Aluno aluno, String docId) async {
    setState(() => _isProcessing = true);
    final controller = TextEditingController();
    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recusar Aluno'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Motivo da recusa (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Recusar'),
            ),
          ],
        ),
      );
      if (result != null) {
        await AlunoService.recusarAluno(docId, result);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno recusado!'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
