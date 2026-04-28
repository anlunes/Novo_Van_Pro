import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum EscolaStatus { pendente, homologado }

class AdminEscolasPage extends StatefulWidget {
  const AdminEscolasPage({super.key});

  @override
  State<AdminEscolasPage> createState() => _AdminEscolasPageState();
}

class _AdminEscolasPageState extends State<AdminEscolasPage> {
  String _filtroBusca = "";
  final TextEditingController _buscaController = TextEditingController();

  // --- LÃ“GICA DE GESTÃƒO: HOMOLOGAÃ‡ÃƒO ---
  Future<void> _homologar(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('colegios').doc(docId).update({
        'status': EscolaStatus.homologado.name,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escola homologada!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao homologar: $e")));
    }
  }

  // --- LÃ“GICA DE GESTÃƒO: EXCLUSÃƒO ---
  void _rejeitarOuExcluir(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Escola?"),
        content: const Text("Esta aÃ§Ã£o removerÃ¡ a escola permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('colegios').doc(docId).delete();
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
              }
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LÃ“GICA DE EDIÃ‡ÃƒO: FORMULÃRIO COM VALIDAÃ‡ÃƒO ---
  void _abrirEdicao(BuildContext context, Map<String, dynamic> dados, String docId) {
    final formKey = GlobalKey<FormState>();
    final nomeCtrl = TextEditingController(text: dados['nome']);
    final bairroCtrl = TextEditingController(text: dados['bairro']);
    final cidadeCtrl = TextEditingController(text: dados['cidade']);
    final endCtrl = TextEditingController(text: dados['endereco']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Escola"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome"), validator: (v) => v!.isEmpty ? "ObrigatÃ³rio" : null),
                TextFormField(controller: bairroCtrl, decoration: const InputDecoration(labelText: "Bairro")),
                TextFormField(controller: cidadeCtrl, decoration: const InputDecoration(labelText: "Cidade")),
                TextFormField(controller: endCtrl, decoration: const InputDecoration(labelText: "EndereÃ§o")),
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
                    'nome': nomeCtrl.text.trim(),
                    'bairro': bairroCtrl.text.trim(),
                    'cidade': cidadeCtrl.text.trim(),
                    'endereco': endCtrl.text.trim(),
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("GestÃ£o de Escolas"), bottom: const TabBar(tabs: [Tab(text: "PENDENTES"), Tab(text: "HOMOLOGADAS")])),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _buscaController,
                decoration: const InputDecoration(hintText: "Buscar...", prefixIcon: Icon(Icons.search)),
                onChanged: (val) => setState(() => _filtroBusca = val.toLowerCase()),
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                _buildListaEscolas(status: EscolaStatus.pendente.name),
                _buildListaEscolas(status: EscolaStatus.homologado.name),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaEscolas({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('colegios').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((d) => (d['nome'] ?? "").toString().toLowerCase().contains(_filtroBusca)).toList();
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var e = docs[i].data() as Map<String, dynamic>;
            return Card(child: ListTile(title: Text(e['nome']), subtitle: Text(e['cidade'] ?? ""), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _abrirEdicao(context, e, docs[i].id))));
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }
}