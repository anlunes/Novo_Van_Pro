import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- CAMADA DE SERVIÃ‡O (REPOSITÃ“RIO) ---
class IbgeRepository {
  static const String _baseUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  Future<List<dynamic>> fetchEstados() async {
    final res = await http.get(Uri.parse('$_baseUrl/estados?orderBy=nome'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Falha ao carregar estados');
  }

  Future<List<dynamic>> fetchCidades(String ufId) async {
    final res = await http.get(Uri.parse('$_baseUrl/estados/$ufId/municipios?orderBy=nome'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Falha ao carregar cidades');
  }
}

class OperacaoMotoristaWidget extends StatefulWidget {
  final String uid;
  const OperacaoMotoristaWidget({super.key, required this.uid});

  @override
  State<OperacaoMotoristaWidget> createState() => _OperacaoMotoristaWidgetState();
}

class _OperacaoMotoristaWidgetState extends State<OperacaoMotoristaWidget> {
  final IbgeRepository _repository = IbgeRepository();
  List<dynamic> _listaEstados = [];
  List<dynamic> _listaCidades = [];
  String? _ufSelecionada;
  String? _cidadeSelecionada;
  final List<String> _bairros = [];
  final List<String> _escolas = [];
  final TextEditingController _bairroController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final estados = await _repository.fetchEstados();
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      
      setState(() {
        _listaEstados = estados;
        if (doc.exists) {
          var data = doc.data()!;
          _ufSelecionada = data['atend_uf'];
          _cidadeSelecionada = data['atend_municipio'];
          _bairros.addAll(List<String>.from(data['bairros_tags'] ?? []));
          _escolas.addAll(List<String>.from(data['escolas_tags'] ?? []));
        }
      });

      if (_ufSelecionada != null) {
        var estadoObj = _listaEstados.firstWhere((e) => e['nome'] == _ufSelecionada, orElse: () => null);
        if (estadoObj != null) await _buscarCidades(estadoObj['id'].toString());
      }
    } catch (e) {
      debugPrint("Erro inicial: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buscarCidades(String ufId) async {
    setState(() => _isLoading = true);
    try {
      final cidades = await _repository.fetchCidades(ufId);
      setState(() => _listaCidades = cidades);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _salvar() async {
    if (_ufSelecionada == null || _cidadeSelecionada == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'atend_uf': _ufSelecionada,
        'atend_municipio': _cidadeSelecionada,
        'bairros_tags': _bairros,
        'escolas_tags': _escolas,
      }, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo com sucesso!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _listaEstados.isEmpty) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _ufSelecionada,
            decoration: const InputDecoration(labelText: "Estado (UF)"),
            items: _listaEstados.map((e) => DropdownMenuItem(value: e['nome'].toString(), child: Text(e['nome']))).toList(),
            onChanged: (val) {
              var estadoObj = _listaEstados.firstWhere((e) => e['nome'] == val);
              setState(() { _ufSelecionada = val; _cidadeSelecionada = null; });
              _buscarCidades(estadoObj['id'].toString());
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _cidadeSelecionada,
            decoration: const InputDecoration(labelText: "Cidade"),
            items: _listaCidades.map((e) => DropdownMenuItem(value: e['nome'].toString(), child: Text(e['nome']))).toList(),
            onChanged: (val) => setState(() => _cidadeSelecionada = val),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _bairroController, decoration: const InputDecoration(labelText: "Bairro"))),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  final text = _bairroController.text.trim();
                  if (text.isNotEmpty && !_bairros.contains(text)) {
                    setState(() { _bairros.add(text); _bairroController.clear(); });
                  }
                },
              ),
            ],
          ),
          Wrap(children: _bairros.map((b) => Chip(label: Text(b), onDeleted: () => setState(() => _bairros.remove(b)))).toList()),
          const SizedBox(height: 20),
          _isSaving ? const CircularProgressIndicator() : ElevatedButton(onPressed: _salvar, child: const Text("SALVAR")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bairroController.dispose();
    super.dispose();
  }
}