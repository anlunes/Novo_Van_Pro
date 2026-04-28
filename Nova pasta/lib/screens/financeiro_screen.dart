import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:van_pro_novo/models/aluno_model.dart';
import 'package:van_pro_novo/widgets/aluno_card_financeiro.dart';

class FinanceiroController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> atualizarValorMensalidade(String docId, double novoValor) async {
    await _db.collection('alunos').doc(docId).update({'valorMensalidade': novoValor});
  }

  Future<void> atualizarStatusPagamento(String docId, bool pago) async {
    await _db.collection('alunos').doc(docId).update({'pago': pago});
  }

  Map<String, double> calcularTotais(List<Aluno> alunos) {
    double totalEsperado = alunos.fold(0, (sum, item) => sum + item.valorMensalidade);
    double totalPago = alunos.where((a) => a.pago).fold(0, (sum, item) => sum + item.valorMensalidade);
    return {'esperado': totalEsperado, 'pago': totalPago};
  }
}

class FinanceiroScreen extends StatelessWidget {
  const FinanceiroScreen({super.key});

  void _definirValor(BuildContext context, String docId, double valorAtual) {
    final controller = TextEditingController(text: valorAtual.toStringAsFixed(2));
    final financeiroController = FinanceiroController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Definir Mensalidade"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: const InputDecoration(labelText: "Valor (R\$)", prefixText: "R\$ "),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              final novoValor = double.tryParse(controller.text);
              if (novoValor != null && novoValor >= 0) {
                await financeiroController.atualizarValorMensalidade(docId, novoValor);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Usuário não autenticado")));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Gestão Financeira")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final vanCode = (userSnapshot.data?.data() as Map?)?['vanCode'] ?? "";
          final controller = FinanceiroController();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('alunos').where('vanCode', isEqualTo: vanCode).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final listaAlunos = snapshot.data!.docs.map((doc) => Aluno.fromFirestore(doc)).toList();
              final totais = controller.calcularTotais(listaAlunos);

              return Column(
                children: [
                  _buildHeader(totais['esperado']!, totais['pago']!),
                  Expanded(
                    child: ListView.builder(
                      itemCount: listaAlunos.length,
                      itemBuilder: (context, index) => AlunoCardFinanceiro(
                        aluno: listaAlunos[index],
                        onEditValor: () => _definirValor(context, listaAlunos[index].id, listaAlunos[index].valorMensalidade),
                        onTogglePago: (status) => controller.atualizarStatusPagamento(listaAlunos[index].id, status),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(double esperado, double pago) => Container(
    padding: const EdgeInsets.all(15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTotalColumn("A RECEBER", esperado, Colors.blue),
        _buildTotalColumn("JÁ PAGO", pago, Colors.green),
      ],
    ),
  );

  Widget _buildTotalColumn(String label, double valor, Color cor) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      Text("R\$ ${valor.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, color: cor, fontWeight: FontWeight.bold)),
    ],
  );
}