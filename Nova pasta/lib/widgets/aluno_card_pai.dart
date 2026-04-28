import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aluno_model.dart';

typedef OnToggleVaiHoje = Function(bool);
typedef OnEdit = Function();
typedef OnDelete = Function();

class AlunoCardPai extends StatefulWidget {
  final Aluno aluno;
  final Map<String, dynamic>? motorista; // Dados injetados
  final OnToggleVaiHoje onToggleVaiHoje;
  final OnEdit onEdit;
  final OnDelete onDelete;

  const AlunoCardPai({
    super.key,
    required this.aluno,
    this.motorista,
    required this.onToggleVaiHoje,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AlunoCardPai> createState() => _AlunoCardPaiState();
}

class _AlunoCardPaiState extends State<AlunoCardPai> {
  void _solicitarContato() async {
    try {
      await FirebaseFirestore.instance
          .collection('alunos')
          .doc(widget.aluno.id)
          .update({
            'solicitacaoContato': true,
            'respostaContato': '',
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada ao motorista !'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar solicitação: $e')),
        );
      }
    }
  }

  void _abrirProntuarioFamilia(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text(widget.aluno.nome.split(' ').first,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _itemProntuario(Icons.location_city, "Escola", widget.aluno.nomeEscola),
            _itemProntuario(Icons.access_time, "Horário Entrada", widget.aluno.horarioEntrada),
            _itemProntuario(Icons.exit_to_app, "Horário Saí­da", widget.aluno.horarioSaida),
            const Divider(height: 20),
            _itemProntuario(Icons.person, "Motorista", widget.motorista?['nome'] ?? "Não informado"),
            _itemProntuario(Icons.phone, "Telefone Van", widget.motorista?['telefone'] ?? "Não informado"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR")),
        ],
      ),
    );
  }

  Widget _itemProntuario(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text("$label: $value", style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    // Apenas banners com campos que existem no Aluno (vaiHoje/cienteMotorista/status/pago)
    if (!widget.aluno.vaiHoje && widget.aluno.cienteMotorista) {
      return _bannerStatus("Motorista ciente que não vai hoje", Colors.green);
    }

    if (widget.aluno.pago) {
      return _bannerStatus("Pago ✅", Colors.green.shade600);
    }

    return const SizedBox.shrink();
  }

  Widget _bannerStatus(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildComunicacaoSection() {
    if (widget.aluno.respostaContato.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.message, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Motorista: ${widget.aluno.respostaContato}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (widget.aluno.solicitacaoContato) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text('Aguardando resposta do motorista...',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextButton.icon(
        onPressed: _solicitarContato,
        icon: const Icon(Icons.phone, size: 16),
        label: const Text('Solicitar contato do motorista'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildTopBanner(),
          ExpansionTile(
            leading: GestureDetector(
              onTap: () => _abrirProntuarioFamilia(context),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: widget.aluno.fotoUrl.isNotEmpty ? NetworkImage(widget.aluno.fotoUrl) : null,
                child: widget.aluno.fotoUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
              ),
            ),
            title: Text(widget.aluno.nome, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: InkWell(
              onTap: widget.motorista != null
                  ? () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Detalhes do Motorista'),
                          content: Text(widget.motorista?['nome'] ?? 'Motorista não localizado'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      )
                  : null,
              child: Text(
                widget.motorista?['nome'] ?? "Motorista não localizado",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailing: Switch(value: widget.aluno.vaiHoje, activeThumbColor: Colors.green, onChanged: widget.onToggleVaiHoje),
            children: [
              _buildComunicacaoSection(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Excluir',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ... (mÃ©todos _buildComunicacaoSection e _buildHorariosSection mantidos)
}