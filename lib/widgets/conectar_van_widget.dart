import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef OnProcurarVan = Function(
  Map<String, dynamic>,
  String,
  String,
  String,
  String,
);

class ConectarVanWidget extends StatefulWidget {
  final String uid;
  final String nomeResp;
  final String cidadeResp;
  final TextEditingController codeController;
  final OnProcurarVan onProcurarVan;

  const ConectarVanWidget({
    super.key,
    required this.uid,
    required this.nomeResp,
    required this.cidadeResp,
    required this.codeController,
    required this.onProcurarVan,
  });

  @override
  State<ConectarVanWidget> createState() => _ConectarVanWidgetState();
}

class _ConectarVanWidgetState extends State<ConectarVanWidget> {
  bool _estaBuscando = false;
  String? _mensagemErro;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.directions_bus, size: 80, color: Colors.blue.shade200),
          const SizedBox(height: 30),
          Text(
            'Conecte-se a uma Van',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Você ainda não está conectado a nenhuma van de transporte',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 40),
          _buildCardInstrucoes(),
          const SizedBox(height: 30),
          TextField(
            controller: widget.codeController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Código da Van',
              hintText: 'Ex: ABC123',
              prefixIcon: const Icon(Icons.qr_code_2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _procurarVan(),
          ),
          if (_mensagemErro != null) _buildMensagemErro(),
          const SizedBox(height: 20),
          _buildBotaoBusca(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCardInstrucoes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Como conectar-se:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            _buildInstrucao('1', 'Receba o código da van do motorista'),
            _buildInstrucao('2', 'Digite o código no campo abaixo'),
            _buildInstrucao('3', 'Clique em "Procurar" para validar'),
            _buildInstrucao('4', 'Preencha os dados do seu filho(a)'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrucao(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: Text(numero, style: const TextStyle(fontSize: 10, color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: Colors.blueGrey))),
        ],
      ),
    );
  }

  Widget _buildMensagemErro() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
        child: Row(children: [Icon(Icons.error, color: Colors.red.shade700, size: 20), const SizedBox(width: 10), Expanded(child: Text(_mensagemErro!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)))]),
      ),
    );
  }

  Widget _buildBotaoBusca() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: _estaBuscando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
        label: Text(_estaBuscando ? 'BUSCANDO...' : 'PROCURAR VAN'),
        onPressed: _estaBuscando ? null : _procurarVan,
      ),
    );
  }

  Future<void> _procurarVan() async {
    String codigo = widget.codeController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      setState(() => _mensagemErro = 'Por favor, digite o código da van.');
      return;
    }

    setState(() {
      _estaBuscando = true;
      _mensagemErro = null;
    });

    try {
      var vanQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'motorista')
          .where('vanCode', isEqualTo: codigo)
          .limit(1)
          .get();

      if (vanQuery.docs.isEmpty) {
        setState(() => _mensagemErro = 'Van não encontrada. Verifique o código.');
      } else {
        var vanDoc = vanQuery.docs.first;
        // A persistência foi removida daqui para evitar dados órfãos.
        // O callback agora é responsável por disparar o fluxo de cadastro.
        widget.onProcurarVan(vanDoc.data(), vanDoc.id, codigo, widget.nomeResp, widget.cidadeResp);
      }
    } on FirebaseException catch (e) {
      setState(() => _mensagemErro = 'Erro de conexão: ${e.message}');
    } catch (e) {
      setState(() => _mensagemErro = 'Ocorreu um erro inesperado.');
    } finally {
      if (mounted) setState(() => _estaBuscando = false);
    }
  }
}