import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:van_pro_novo/models/aluno_model.dart';

class GestaoPagamentosController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> confirmarPagamento(String docId) async {
    await _db.collection('alunos').doc(docId).update({
      'pago': true,
      'ultimoPagamento': Timestamp.now(),
    });
  }
}

class GestaoPagamentosScreen extends StatelessWidget {
  const GestaoPagamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gestão de Pagamentos'),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alunos')
            .orderBy('ordem', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!.docs
              .map((doc) => Aluno.fromFirestore(doc))
              .toList();

          // Só entra nas colunas quem ainda NÃO pagou
          final naoPageram = todos.where((a) => !a.pago).toList();

          final aVencer  = _getAVencer(naoPageram);
          final vencidos = _getVencidos(naoPageram);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── COLUNA ESQUERDA – A VENCER ──────────────────────
                  Expanded(
                    child: _buildColuna(
                      context,
                      titulo: 'A VENCER',
                      alunos: aVencer,
                      corHeader: Colors.blue,
                      icone: Icons.schedule,
                    ),
                  ),
                  Container(width: 1, color: Colors.grey.shade300),
                  // ── COLUNA DIREITA – VENCIDOS ────────────────────────
                  Expanded(
                    child: _buildColuna(
                      context,
                      titulo: 'VENCIDOS',
                      alunos: vencidos,
                      corHeader: Colors.red,
                      icone: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              );
        },
      ),
    );
  }

  List<Aluno> _getAVencer(List<Aluno> alunos) {
    final diaAtual = DateTime.now().day;
    return alunos
        .where((a) => a.diaPagamento > diaAtual)
        .toList()
      ..sort((a, b) => a.diaPagamento.compareTo(b.diaPagamento));
  }

  List<Aluno> _getVencidos(List<Aluno> alunos) {
    final diaAtual = DateTime.now().day;
    return alunos
        .where((a) => a.diaPagamento <= diaAtual)
        .toList()
      ..sort((a, b) => a.diaPagamento.compareTo(b.diaPagamento));
  }

  Widget _buildColuna(
    BuildContext context, {
    required String titulo,
    required List<Aluno> alunos,
    required Color corHeader,
    required IconData icone,
  }) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          color: corHeader.withValues(alpha: 0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, color: corHeader, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: corHeader,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: corHeader,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alunos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Lista ────────────────────────────────────────────────────────
        Expanded(
          child: alunos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Tudo certo!',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: alunos.length,
                  itemBuilder: (context, index) => _AlunoCard(
                    aluno: alunos[index],
                    corHeader: corHeader,
                  ),
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Card minimalista - apenas foto e nome
// ════════════════════════════════════════════════════════════════════════════
class _AlunoCard extends StatelessWidget {
  final Aluno aluno;
  final Color corHeader;

  const _AlunoCard({
    required this.aluno,
    required this.corHeader,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _mostrarConfirmacao(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corHeader.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fundo colorido no topo
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: corHeader.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            // Conteúdo centralizado
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Foto (avatar grande)
                CircleAvatar(
                  radius: 32,
                  backgroundColor: corHeader.withValues(alpha: 0.2),
                  backgroundImage: aluno.fotoUrl.isNotEmpty
                      ? NetworkImage(aluno.fotoUrl)
                      : null,
                  child: aluno.fotoUrl.isEmpty
                      ? Icon(Icons.person, color: corHeader, size: 32)
                      : null,
                ),
                const SizedBox(height: 8),
                // Nome
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    aluno.nome,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Hint de duplo toque
                Text(
                  '2x para confirmar',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Pagamento',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: corHeader.withValues(alpha: 0.2),
              backgroundImage: aluno.fotoUrl.isNotEmpty
                  ? NetworkImage(aluno.fotoUrl)
                  : null,
              child: aluno.fotoUrl.isEmpty
                  ? Icon(Icons.person, color: corHeader, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              aluno.nome,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ ${aluno.valorMensalidade.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vencimento: dia ${aluno.diaPagamento}',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final controller = GestaoPagamentosController();
              await controller.confirmarPagamento(aluno.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✓ Pagamento de ${aluno.nome} confirmado!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }
}
