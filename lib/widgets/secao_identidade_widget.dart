import 'package:flutter/material.dart';

// Modelo para encapsular os dados e reduzir a verbosidade do construtor
class AlunoData {
  String nome, email, telefone, nomeEscola, endereco, bairro, municipio, estado;

  AlunoData({
    this.nome = '',
    this.email = '',
    this.telefone = '',
    this.nomeEscola = '',
    this.endereco = '',
    this.bairro = '',
    this.municipio = '',
    this.estado = '',
  });
}

class SecaoIdentidadeWidget extends StatefulWidget {
  final AlunoData dados;
  final Function(AlunoData) onChanged;

  const SecaoIdentidadeWidget({
    super.key,
    required this.dados,
    required this.onChanged,
  });

  @override
  State<SecaoIdentidadeWidget> createState() => _SecaoIdentidadeWidgetState();
}

class _SecaoIdentidadeWidgetState extends State<SecaoIdentidadeWidget> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'nome': TextEditingController(text: widget.dados.nome),
      'email': TextEditingController(text: widget.dados.email),
      'telefone': TextEditingController(text: widget.dados.telefone),
      'escola': TextEditingController(text: widget.dados.nomeEscola),
      'endereco': TextEditingController(text: widget.dados.endereco),
      'bairro': TextEditingController(text: widget.dados.bairro),
      'municipio': TextEditingController(text: widget.dados.municipio),
      'estado': TextEditingController(text: widget.dados.estado),
    };
  }

  void _handleUpdate() {
    final novosDados = AlunoData(
      nome: _controllers['nome']!.text,
      email: _controllers['email']!.text,
      telefone: _controllers['telefone']!.text,
      nomeEscola: _controllers['escola']!.text,
      endereco: _controllers['endereco']!.text,
      bairro: _controllers['bairro']!.text,
      municipio: _controllers['municipio']!.text,
      estado: _controllers['estado']!.text,
    );
    widget.onChanged(novosDados);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTextField(String key, String label, IconData? icon, {TextInputType? type, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        keyboardType: type,
        maxLength: maxLength,
        onChanged: (_) => _handleUpdate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DADOS PESSOAIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          _buildTextField('nome', 'Nome do Aluno(a)', Icons.person),
          _buildTextField('email', 'Email (opcional)', Icons.email, type: TextInputType.emailAddress),
          _buildTextField('telefone', 'Telefone / WhatsApp', Icons.phone, type: TextInputType.phone),
          const SizedBox(height: 24),
          const Text('DADOS ESCOLARES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          _buildTextField('escola', 'Nome da Escola', Icons.school),
          const SizedBox(height: 24),
          const Text('ENDEREÇO RESIDENCIAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          _buildTextField('endereco', 'Rua e Número', Icons.location_on),
          _buildTextField('bairro', 'Bairro', null),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField('municipio', 'Município', null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('estado', 'UF', null, maxLength: 2)),
            ],
          ),
        ],
      ),
    );
  }
}