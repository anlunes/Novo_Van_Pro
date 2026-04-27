import 'package:flutter/material.dart';
import 'dart:convert'; // ← ADICIONADO
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminBrasilEscolasPage extends StatefulWidget {
  const AdminBrasilEscolasPage({super.key});
  @override
  State<AdminBrasilEscolasPage> createState() => _AdminBrasilEscolasPageState();
}

class _AdminBrasilEscolasPageState extends State<AdminBrasilEscolasPage> {
  String _termoBusca = "";
  final TextEditingController _buscaController = TextEditingController();

  // Função utilitária para sanitizar dados para CSV
  String _sanitizarCsv(String? valor) {
    if (valor == null) return "";
    return valor.replaceAll('"', '""').replaceAll(';', ',');
  }

  Future<void> _exportarBase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('colegios')
          .where('status', isEqualTo: 'homologado')
          .get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma escola para exportar")));
        return;
      }

      String csvContent = "Nome;Bairro;Cidade;Endereco\n";
      for (var doc in snapshot.docs) {
        var d = doc.data();
        csvContent += "${_sanitizarCsv(d['nome'])};${_sanitizarCsv(d['bairro'])};${_sanitizarCsv(d['cidade'])};${_sanitizarCsv(d['endereco'])}\n";
      }

      // ← CORRIGIDO: Removido const Utf8Codec()
      final Uri uri = Uri.dataFromString(
        csvContent, 
        mimeType: 'text/csv', 
        encoding: utf8, // ← SEM const
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao exportar: $e")));
    }
  }

  Future<void> _excluirEscola(String docId, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Escola?"),
        content: Text("Deseja remover '$nome' definitivamente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('colegios').doc(docId).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escola excluída com sucesso!")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao excluir: $e")));
      }
    }
  }

  void _abrirEdicao(Map<String, dynamic> dados, String docId) {
    final formKey = GlobalKey<FormState>();
    final nomeC = TextEditingController(text: dados['nome']);
    final bairroC = TextEditingController(text: dados['bairro']);
    final cidadeC = TextEditingController(text: dados['cidade']);
    final enderecoC = TextEditingController(text: dados['endereco']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Escola Nacional"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nomeC, decoration: const InputDecoration(labelText: "Nome"), validator: (v) => v!.isEmpty ? "Campo obrigatório" : null),
                TextFormField(controller: bairroC, decoration: const InputDecoration(labelText: "Bairro")),
                TextFormField(controller: cidadeC, decoration: const InputDecoration(labelText: "Cidade")),
                TextFormField(controller: enderecoC, decoration: const InputDecoration(labelText: "Endereço")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance.collection('colegios').doc(docId).update({
                    'nome': nomeC.text.trim(),
                    'bairro': bairroC.text.trim(),
                    'cidade': cidadeC.text.trim(),
                    'endereco': enderecoC.text.trim()
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escola atualizada!")));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao atualizar: $e")));
                }
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão Nacional de Escolas"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: _exportarBase, tooltip: "Exportar CSV")],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _buscaController,
              onChanged: (val) => setState(() => _termoBusca = val.toLowerCase()),
              decoration: InputDecoration(hintText: "Pesquisar escola...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('colegios').where('status', isEqualTo: 'homologado').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var escolas = snapshot.data!.docs.where((doc) => (doc['nome'] ?? "").toString().toLowerCase().contains(_termoBusca)).toList();
                escolas.sort((a, b) => (a['nome'] ?? "").toString().toLowerCase().compareTo((b['nome'] ?? "").toString().toLowerCase()));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: escolas.length,
                  itemBuilder: (context, index) {
                    var e = escolas[index].data() as Map<String, dynamic>;
                    String id = escolas[index].id;
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.school, color: Colors.orangeAccent),
                        title: Text((e['nome'] ?? 'Sem Nome').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${e['cidade'] ?? ''} - ${e['bairro'] ?? ''}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _abrirEdicao(e, id), icon: const Icon(Icons.edit, color: Colors.blue)),
                            IconButton(onPressed: () => _excluirEscola(id, e['nome']), icon: const Icon(Icons.delete, color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }
}