import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuscaEscolaWidget extends StatefulWidget {
  final String cidade;
  final Function(Map<String, dynamic> escola) onEscolaSelecionada;

  const BuscaEscolaWidget({
    super.key,
    required this.cidade,
    required this.onEscolaSelecionada,
  });

  @override
  State<BuscaEscolaWidget> createState() => _BuscaEscolaWidgetState();
}

class _BuscaEscolaWidgetState extends State<BuscaEscolaWidget> {
  final TextEditingController _buscaController = TextEditingController();
  List<Map<String, dynamic>> _escolasEncontradas = [];
  bool _isSearching = false;
  String? _errorMessage;
  Timer? _debounce;

  // --- BUSCA COM DEBOUNCE E LIMITAÇÃO ---
  void _onSearchChanged(String termo) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscarEscolas(termo);
    });
  }

  Future<void> _buscarEscolas(String termo) async {
    if (termo.isEmpty) {
      setState(() {
        _escolasEncontradas = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Limitamos a 20 resultados para evitar over-fetching
      final snapshot = await FirebaseFirestore.instance
          .collection('colegios')
          .where('cidade', isEqualTo: widget.cidade)
          .where('status', isEqualTo: 'homologado')
          .limit(20)
          .get();

      final escolas = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final nome = data['nome'];
            return nome is String && nome.toLowerCase().contains(termo.toLowerCase());
          })
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();

      setState(() => _escolasEncontradas = escolas);
    } catch (e) {
      debugPrint("Erro ao buscar escolas: $e");
      setState(() => _errorMessage = "Erro ao conectar com o servidor.");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _buscaController,
          decoration: InputDecoration(
            labelText: "Buscar escola em ${widget.cidade}...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching 
                ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) 
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),
        
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),

        if (_escolasEncontradas.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _escolasEncontradas.length,
              itemBuilder: (context, index) {
                var escola = _escolasEncontradas[index];
                return InkWell(
                  onTap: () {
                    _buscaController.clear();
                    setState(() => _escolasEncontradas = []);
                    widget.onEscolaSelecionada(escola);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(escola['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${escola['bairro'] ?? ''} - ${escola['cidade'] ?? ''}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else if (_buscaController.text.isNotEmpty && !_isSearching && _errorMessage == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Text("Nenhuma escola encontrada."),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    super.dispose();
  }
}