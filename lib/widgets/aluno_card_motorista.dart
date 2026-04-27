import 'package:flutter/material.dart';
import '../models/aluno_model.dart';

class StatusTransporte {
  static const String aguardando = 'Aguardando';
  static const String aCaminhoEscola = 'A caminho da Escola';
  static const String entregueEscola = 'Entregue na Escola';
  static const String aCaminhoCasa = 'A caminho de Casa';
  static const String entregueCasa = 'Entregue em Casa';
}

class AlunoCardMotorista extends StatefulWidget {
  final Aluno aluno;
  final Function(String docId, String novoStatus, String nomeAluno)? onStatusChanged;
  final Function(String? telefone, String nomeAluno)? onWhatsAppPressed;
  final Function(String docId)? onReplyContact;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AlunoCardMotorista({
    super.key,
    required this.aluno,
    this.onStatusChanged,
    this.onWhatsAppPressed,
    this.onReplyContact,
    this.onTap,
    this.onDelete,
  });

  @override
  State<AlunoCardMotorista> createState() => _AlunoCardMotoristaState();
}

class _AlunoCardMotoristaState extends State<AlunoCardMotorista> {
  Color _getFinanceiroColor() {
    if (widget.aluno.pago) return Colors.green;
    final int diaHoje = DateTime.now().day;
    final int vencimento = widget.aluno.diaPagamento;
    if (diaHoje > vencimento) return Colors.red;
    if (diaHoje >= (vencimento - 3)) return Colors.orange;
    return Colors.blueGrey.shade400;
  }

  void _abrirProntuario(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Prontuário do Aluno",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _itemProntuario(Icons.phone, "Telefone", widget.aluno.telefone),
              _itemProntuario(Icons.place, "Endereço", widget.aluno.endereco),
              _itemProntuario(Icons.school, "Escola", widget.aluno.nomeEscola),
              _itemProntuario(Icons.family_restroom, "Responsável", widget.aluno.nomeResponsavel),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => widget.onWhatsAppPressed?.call(
                  widget.aluno.telefone,
                  widget.aluno.nome,
                ),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text("WHATSAPP DO RESPONSÁVEL"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemProntuario(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAcao(String texto, Color cor, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: cor),
      onPressed: onPressed,
      child: Text(texto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.aluno.status;

    Color corCard = Colors.grey.shade100;
    late Widget acaoMotorista;

    if (widget.aluno.pago) {
      corCard = Colors.green.shade50;
      acaoMotorista = _buildBotaoAcao(
        "DAR CIÊNCIA",
        Colors.red.shade400,
        () => widget.onStatusChanged?.call(widget.aluno.id, status, widget.aluno.nome),
      );
    } else {
      switch (status) {
        case StatusTransporte.aguardando:
        case '':
          corCard = Colors.green.shade50;
          acaoMotorista = _buildBotaoAcao(
            "IDA ESCOLA",
            Colors.orange.shade800,
            () => widget.onStatusChanged?.call(
              widget.aluno.id,
              StatusTransporte.aCaminhoEscola,
              widget.aluno.nome,
            ),
          );
          break;
        case StatusTransporte.aCaminhoEscola:
          corCard = Colors.blue.shade50;
          acaoMotorista = _buildBotaoAcao(
            "ENTREGUE ESCOLA",
            Colors.blue.shade700,
            () => widget.onStatusChanged?.call(
              widget.aluno.id,
              StatusTransporte.entregueEscola,
              widget.aluno.nome,
            ),
          );
          break;
        case StatusTransporte.entregueEscola:
          corCard = Colors.amber.shade50;
          acaoMotorista = _buildBotaoAcao(
            "IDA CASA",
            Colors.deepOrange,
            () => widget.onStatusChanged?.call(
              widget.aluno.id,
              StatusTransporte.aCaminhoCasa,
              widget.aluno.nome,
            ),
          );
          break;
        case StatusTransporte.aCaminhoCasa:
          corCard = Colors.blue.shade100;
          acaoMotorista = _buildBotaoAcao(
            "ENTREGUE CASA",
            Colors.indigo.shade800,
            () => widget.onStatusChanged?.call(
              widget.aluno.id,
              StatusTransporte.entregueCasa,
              widget.aluno.nome,
            ),
          );
          break;
        default:
          corCard = Colors.grey.shade100;
          acaoMotorista = const Icon(Icons.check_circle, color: Colors.green);
      }
    }

    return Card(
      elevation: 4,
      color: corCard,
      child: ListTile(
        title: Text(widget.aluno.nome),
        subtitle: Text(status),
        onTap: widget.onTap ?? () => _abrirProntuario(context),
        trailing: IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: () => _abrirProntuario(context),
        ),
      ),
    );
  }
}