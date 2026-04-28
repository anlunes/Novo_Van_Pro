import 'package:flutter/material.dart';
import 'package:van_pro/widgets/busca_escola_widget.dart';
import 'package:van_pro/services/aluno_service.dart';

class SecaoLocalidadeWidget extends StatefulWidget {
  final Function(Map<String, dynamic> localidade) onLocalidadeChange;
  final String? estadoInicial;
  final String? cidadeInicial;
  final Map<String, dynamic>? escolaInicial;

  const SecaoLocalidadeWidget({
    super.key,
    required this.onLocalidadeChange,
    this.estadoInicial,
    this.cidadeInicial,
    this.escolaInicial,
  });

  @override
  State<SecaoLocalidadeWidget> createState() => _SecaoLocalidadeWidgetState();
}

class _SecaoLocalidadeWidgetState extends State<SecaoLocalidadeWidget> {
  final AlunoService _alunoService = AlunoService();
  
    List<Estado> _estados = [];
  List<Cidade> _cidades = [];

  
  String? _estadoSelecionado;
  String? _cidadeSelecionada;
  Map<String, dynamic>? _escolaSelecionada;
  
  bool _isLoadingEstados = true;
  bool _isLoadingCidades = false;

  @override
  void initState() {
    super.initState();
    _estadoSelecionado = widget.estadoInicial;
    _cidadeSelecionada = widget.cidadeInicial;
    _escolaSelecionada = widget.escolaInicial;
    
    _carregarEstados();
  }

  void _resetarCampos({required bool resetarCidade, required bool resetarEscola}) {
    setState(() {
      if (resetarCidade) _cidadeSelecionada = null;
      if (resetarEscola) _escolaSelecionada = null;
    });
  }

  Future<void> _carregarEstados() async {
    try {
      final estados = await _alunoService.buscarEstados();
      if (mounted) {
        setState(() {
          _estados = estados;
          _isLoadingEstados = false;
          if (_estadoSelecionado != null) {
                        final estado = _estados.firstWhere((e) => e.nome == _estadoSelecionado);
            _carregarCidades(estado.id.toString(), cidadeParaSelecionar: _cidadeSelecionada);

          }
        });
      }
    } catch (e) {
      _mostrarErro("Erro ao carregar estados: $e");
      if (mounted) setState(() => _isLoadingEstados = false);
    }
  }

  Future<void> _carregarCidades(String estado, {String? cidadeParaSelecionar}) async {
    setState(() => _isLoadingCidades = true);
    try {
      final cidades = await _alunoService.buscarCidades(estado);
      if (mounted) {
        setState(() {
                    _cidades = cidades;
          _cidadeSelecionada = (cidades.any((c) => c.nome == cidadeParaSelecionar)) ? cidadeParaSelecionar : null;

          _isLoadingCidades = false;
        });
      }
    } catch (e) {
      _mostrarErro("Erro ao carregar cidades: $e");
      if (mounted) setState(() => _isLoadingCidades = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), action: SnackBarAction(label: 'Tentar', onPressed: _carregarEstados)),
      );
    }
  }

  void _aoEscolaSelecionada(Map<String, dynamic> escola) {
    setState(() => _escolaSelecionada = escola);
    _notificarMudancas();
  }

  void _notificarMudancas() {
    widget.onLocalidadeChange({
      'estado': _estadoSelecionado,
      'cidade': _cidadeSelecionada,
      'escola': _escolaSelecionada,
    });
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Estado", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        if (_isLoadingEstados) const Center(child: CircularProgressIndicator())
        else DropdownButtonFormField<String>(
          value: _estadoSelecionado,
          decoration: _buildInputDecoration("Selecione um estado"),
                    items: _estados.map((e) => DropdownMenuItem(value: e.nome, child: Text(e.nome))).toList(),

          onChanged: (estado) {
            if (estado != null) {
              setState(() => _estadoSelecionado = estado);
              _resetarCampos(resetarCidade: true, resetarEscola: true);
                            final estadoModel = _estados.firstWhere((e) => e.nome == estado);
              _carregarCidades(estadoModel.id.toString());

            }
          },
        ),
        const SizedBox(height: 16),
        const Text("Cidade", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        if (_isLoadingCidades) const Center(child: CircularProgressIndicator())
        else if (_estadoSelecionado == null) const Text("Selecione um estado primeiro", style: TextStyle(color: Colors.grey))
        else DropdownButtonFormField<String>(
          value: _cidadeSelecionada,
          decoration: _buildInputDecoration("Selecione uma cidade"),
                    items: _cidades.map((c) => DropdownMenuItem(value: c.nome, child: Text(c.nome))).toList(),

          onChanged: (cidade) {
            if (cidade != null) {
              setState(() { _cidadeSelecionada = cidade; _escolaSelecionada = null; });
              _notificarMudancas();
            }
          },
        ),
        if (_cidadeSelecionada != null) ...[
          const SizedBox(height: 16),
          const Text("Escola", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          BuscaEscolaWidget(cidade: _cidadeSelecionada!, onEscolaSelecionada: _aoEscolaSelecionada),
          if (_escolaSelecionada != null) _buildCardEscola(),
        ],
      ],
    );
  }

  Widget _buildCardEscola() => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade300), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.check_circle, color: Colors.green.shade700, size: 20), const SizedBox(width: 8), Expanded(child: Text(_escolaSelecionada!['nome'] ?? 'Escola', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade900)))]),
      Text(_escolaSelecionada!['endereco'] ?? '', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
    ]),
  );
}