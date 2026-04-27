import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VotarMensalDialog extends StatefulWidget {
  final String motoristaUid;
  final String paiUid;
  final String vanCode;
  final String nomeMotorista;
  final String paiNome;
  final String alunoNome;

  const VotarMensalDialog({
    super.key,
    required this.motoristaUid,
    required this.paiUid,
    required this.vanCode,
    required this.nomeMotorista,
    required this.paiNome,
    required this.alunoNome,
  });

  @override
  State<VotarMensalDialog> createState() => _VotarMensalDialogState();
}

class _VotarMensalDialogState extends State<VotarMensalDialog> {
  double _pontualidade = 5;
  double _seguranca = 5;
  double _cordialidade = 5;
  bool _enviando = false;
  final TextEditingController _comentarioController = TextEditingController();

  // --- ENVIAR AVALIAÇÃO ---
  void _enviarRespostas() async {
    if (_enviando) return;
    setState(() => _enviando = true);

    String mesAnoAtual = "${DateTime.now().month}-${DateTime.now().year}";
    
    try {
      // 1. Verificação de duplicidade
      final querySnapshot = await FirebaseFirestore.instance
          .collection('avaliacoes')
          .where('paiUid', isEqualTo: widget.paiUid)
          .where('motoristaUid', isEqualTo: widget.motoristaUid)
          .where('mes_referencia', isEqualTo: mesAnoAtual)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception("Você já avaliou este motorista neste mês.");
      }

      double mediaFinal = (_pontualidade + _seguranca + _cordialidade) / 3;

      // 2. Salva avaliação
      await FirebaseFirestore.instance.collection('avaliacoes').add({
        'motoristaUid': widget.motoristaUid,
        'vanCode': widget.vanCode,
        'mes_referencia': mesAnoAtual,
        'paiUid': widget.paiUid,
        'paiNome': widget.paiNome,
        'alunoNome': widget.alunoNome,
        'comentario': _comentarioController.text.trim(),
        'notas': {
          'pontualidade': _pontualidade,
          'seguranca': _seguranca,
          'cordialidade': _cordialidade,
        },
        'media': double.parse(mediaFinal.toStringAsFixed(1)),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Atualiza perfil
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.paiUid)
          .update({'ultimo_mes_avaliado': mesAnoAtual});

      if (mounted) {
        Navigator.pop(context, true); // Retorna sucesso
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Avaliação Mensal"),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Motorista: ${widget.nomeMotorista}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            _buildStarRow("Pontualidade", _pontualidade, (v) => setState(() => _pontualidade = v), "Sai e chega no horário?"),
            const SizedBox(height: 16),
            _buildStarRow("Segurança", _seguranca, (v) => setState(() => _seguranca = v), "Dirige com segurança?"),
            const SizedBox(height: 16),
            _buildStarRow("Cordialidade", _cordialidade, (v) => setState(() => _cordialidade = v), "Trata bem o aluno?"),
            const SizedBox(height: 20),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: "Elogio ou crítica (opcional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _enviando 
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _enviarRespostas,
              child: const Text("ENVIAR AVALIAÇÃO"),
            ),
      ],
    );
  }

  Widget _buildStarRow(String label, double valor, Function(double) onChanged, String subLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(subLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Slider(value: valor, min: 1, max: 5, divisions: 4, onChanged: onChanged),
      ],
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
}