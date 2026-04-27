import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aluno_model.dart';
import 'aluno_card.dart';

class StatusAluno {
  static const String aguardando = 'Aguardando a Van';
  static const String embarcado = 'embarcado';
  static const String naoVai = 'Não vai hoje (Avisado)';
}

class AbaChamadaWidget extends StatefulWidget {
  final VoidCallback? onStatusChanged;
  final Function(String?, String)? onWhatsAppPressed;
  final Function(String)? onReplyContact;
  final Function(List<Aluno>)? onReorder;
  final Function(String, bool)? onPaymentStatusChanged;

  const AbaChamadaWidget({
    super.key,
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista de Alunos
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alunos')
                .orderBy('ordem', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nenhum aluno encontrado'));
              }

              final docs = snapshot.data!.docs;

              final alunos = docs.map((doc) => Aluno.fromFirestore(doc)).toList();

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final lista = List<Aluno>.from(alunos);
                  final item = lista.removeAt(oldIndex);
                  lista.insert(newIndex, item);
                  
                  setState(() {}); // Update UI
                  widget.onReorder?.call(lista); // Persist order
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
