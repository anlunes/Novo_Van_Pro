import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecaoFinanceiraWidget extends StatefulWidget {
  final double? valorMensalidadeInicial;
  final int? diaPagamentoInicial;

  final Function(double) onValorChanged;
  final Function(int) onDiaPagamentoChanged;

  const SecaoFinanceiraWidget({
    super.key,
    this.valorMensalidadeInicial,
    this.diaPagamentoInicial,
    required this.onValorChanged,
    required this.onDiaPagamentoChanged,
  });

  @override
  State<SecaoFinanceiraWidget> createState() => _SecaoFinanceiraWidgetState();
}

class _SecaoFinanceiraWidgetState extends State<SecaoFinanceiraWidget> {
  late TextEditingController _valorController;
  late int _diaPagamento;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(
      text: widget.valorMensalidadeInicial != null 
          ? widget.valorMensalidadeInicial!.toStringAsFixed(2) 
          : '',
    );
    _diaPagamento = widget.diaPagamentoInicial ?? 5;
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  double get _valorAtual => double.tryParse(_valorController.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DADOS FINANCEIROS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // --- VALOR DA MENSALIDADE ---
          TextField(
            controller: _valorController,
            decoration: InputDecoration(
              labelText: 'Valor Mensal',
              prefixIcon: const Icon(Icons.attach_money),
              prefixText: 'R\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {}); // Atualiza o resumo
              widget.onValorChanged(_valorAtual);
            },
          ),
          const SizedBox(height: 20),

          // --- DIA DE PAGAMENTO ---
          const Text('Dia de Vencimento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: DropdownButton<int>(
              value: _diaPagamento,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() => _diaPagamento = newValue);
                  widget.onDiaPagamentoChanged(newValue);
                }
              },
              items: List.generate(28, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('Dia ${(index + 1).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 14)),
              )),
            ),
          ),
          const SizedBox(height: 20),

          // --- RESUMO FINANCEIRO ---
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RESUMO FINANCEIRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildResumoRow('Valor Mensal:', 'R\$ ${_valorAtual.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildResumoRow('Vencimento:', 'Dia $_diaPagamento'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
    ],
  );
}