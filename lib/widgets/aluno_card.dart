import 'package:flutter/material.dart';
import '../models/aluno_model.dart';
import 'package:url_launcher/url_launcher.dart';

enum TipoRota { ida, volta }

class AlunoCard extends StatelessWidget {
  final Aluno aluno;
  final VoidCallback? onEdit;
  final bool mostrarHandleDrag;
  final TipoRota tipoRota;

  const AlunoCard({
    Key? key,
    required this.aluno,
    this.onEdit,
    this.mostrarHandleDrag = false,
    this.tipoRota = TipoRota.ida,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enderecoExibir = tipoRota == TipoRota.ida ? aluno.endereco : aluno.enderecoEscola;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mostrarHandleDrag) const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ),
        title: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                enderecoExibir.isNotEmpty ? enderecoExibir : "Endereço não informado",
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.blue),
              onPressed: () => _ligar(context, aluno.telefone),
              tooltip: 'Ligar',
            ),
            IconButton(
              icon: const Icon(Icons.navigation, color: Colors.green),
              onPressed: () => _abrirGPS(context, enderecoExibir),
              tooltip: 'Abrir GPS',
            ),
          ],
        ),
        children: [
          _buildDetalhesExpandidos(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.blue.shade200,
      child: CircleAvatar(
        radius: 23,
        backgroundImage: (aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty)
            ? NetworkImage(aluno.fotoUrl!)
            : null,
        onBackgroundImageError: (_, __) {},
        child: (aluno.fotoUrl == null || aluno.fotoUrl!.isEmpty)
            ? const Icon(Icons.person, size: 28)
            : null,
      ),
    );
  }

  Widget _buildStatusFinanceiro(int diasAtraso, Color corStatus, DateTime hoje) {
    String texto;

    if (aluno.pago) {
      texto = '✓ Pagamento em dia';
    } else if (diasAtraso > 30) {
      texto = '✗ Muito atrasado ($diasAtraso dias)';
    } else if (diasAtraso > 0) {
      texto = '⚠ Atrasado há $diasAtraso dia${diasAtraso > 1 ? 's' : ''}';
    } else {
      final diasVencer = (aluno.diaPagamento - hoje.day).clamp(0, 3650);
      texto = '⏳ Vence em $diasVencer dia${diasVencer > 1 ? 's' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: corStatus.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: corStatus, width: 1),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: corStatus,
        ),
      ),
    );
  }

  Widget _buildDetalhesExpandidos() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetalheRow('Telefone:', aluno.telefone),
          _buildDetalheRow('Endereço:', aluno.endereco),
          _buildDetalheRow('Bairro:', aluno.bairro),
          _buildDetalheRow('Município:', aluno.municipio),
          _buildDetalheRow('Escola:', aluno.nomeEscola),
        ],
      ),
    );
  }

  Widget _buildDetalheRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTexto(int diasAtraso, bool pago) {
    if (pago) return 'Pago - Pagamento em dia';
    if (diasAtraso > 30) return 'Muito atrasado ($diasAtraso dias)';
    if (diasAtraso > 0) return 'Atrasado há $diasAtraso dia${diasAtraso > 1 ? 's' : ''}';
    return 'Em dia - Próximo vencimento';
  }

  Color _getCorStatus(int diasAtraso, bool pago) {
    if (pago) return Colors.green;
    if (diasAtraso > 30) return Colors.red;
    if (diasAtraso > 0) return Colors.orange;
    return Colors.blue;
  }

  Future<void> _ligar(BuildContext context, String telefone) async {
    final tel = telefone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('tel:$tel');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Não foi possível realizar a chamada';
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _abrirGPS(BuildContext context, String endereco) async {
    if (endereco.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Endereço inválido")),
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao abrir GPS")),
      );
    }
  }
}
