
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicionado para formatação de moeda
import '../models/aluno_model.dart';

class AlunoCardFinanceiro extends StatelessWidget {
  final Aluno aluno;
  final VoidCallback? onTap;
  final VoidCallback? onPaymentToggle;
  final VoidCallback? onEditValor;
  final ValueChanged<bool>? onTogglePago; // ← PARAMETRO CORRIGIDO PARA FINANCEIRO_SCREEN

  const AlunoCardFinanceiro({
    super.key,
    required this.aluno,
    this.onTap,
    this.onPaymentToggle,
    this.onEditValor,
    this.onTogglePago, // ← ADICIONADO
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool pago = aluno.pago;

    // Uso de cores baseadas no tema para consistência
    Color corBorda = pago ? Colors.green.shade300 : Colors.orange.shade300;
    Color corFundo = pago ? Colors.green.shade50 : Colors.orange.shade50;

    // Formatação de moeda utilizando intl - CORRIGIDO O R$
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: corBorda, width: 1.5),
        ),
        color: corFundo,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // --- HEADER ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: aluno.fotoUrl.isNotEmpty
                        ? NetworkImage(aluno.fotoUrl)
                        : null,
                    // Tratamento de erro de imagem
                    child: aluno.fotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aluno.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          aluno.nomeResponsavel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- BADGE STATUS PAGAMENTO ---
                  GestureDetector(
                    onTap: () {
                      if (onTogglePago != null) {
                        onTogglePago!(!pago);
                      } else if (onPaymentToggle != null) {
                        onPaymentToggle!();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: pago ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pago ? Icons.check_circle : Icons.schedule, color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            pago ? 'PAGO' : 'PENDENTE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),

              // --- DETALHES FINANCEIROS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mensalidade', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(
                        formatadorMoeda.format(aluno.valorMensalidade),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vencimento', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text('Dia ${aluno.diaPagamento}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  if (onEditValor != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEditValor,
                      tooltip: 'Editar valor',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}