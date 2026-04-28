import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminDocumentosPage extends StatefulWidget {
  const AdminDocumentosPage({super.key});

  @override
  State<AdminDocumentosPage> createState() => _AdminDocumentosPageState();
}

class _AdminDocumentosPageState extends State<AdminDocumentosPage>
    with TickerProviderStateMixin {
  String _termoBusca = "";
  final TextEditingController _buscaController = TextEditingController();
  bool _isProcessing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  // --- CAMADA DE SEGURANÇA E TRATAMENTO DE ERROS ---
  Future<void> _executarAcaoSegura(Future<void> Function() acao, String mensagemSucesso) async {
    setState(() => _isProcessing = true);
    try {
      await acao();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagemSucesso)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString()}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _aprovar(String uid) => _executarAcaoSegura(
        () => FirebaseFirestore.instance.collection('users').doc(uid).update({'docsVerificados': true}),
        "Motorista homologado com sucesso!",
      );

  void _reverterHomologacao(String uid, String nome) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reverter Verificação?"),
        content: Text("O motorista $nome perderá o selo de verificado."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _executarAcaoSegura(
                () => FirebaseFirestore.instance.collection('users').doc(uid).update({'docsVerificados': false}),
                "Verificação revertida.",
              );
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI OTIMIZADOS ---
  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 33,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url ?? '',
          fit: BoxFit.cover,
          width: 66,
          height: 66,
          errorWidget: (context, url, error) => const Icon(Icons.person, size: 40),
        ),
      ),
    );
  }

  Widget _buildResumoOperacional() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Resumo Operacional", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text("Pendente: 0 | Aprovados: 0 | Rejeitados: 0", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(Icons.dashboard, color: Colors.green.shade700, size: 32),
        ],
      ),
    );
  }

  Widget _buildListaSolicitacoes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('docsVerificados', isEqualTo: false)
          .where('role', isEqualTo: 'motorista')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nenhuma solicitação pendente"));
        }

        final docs = snapshot.data!.docs
            .where((doc) => doc['nome']?.toLowerCase().contains(_termoBusca) ?? false)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _buildAvatar(data['fotoUrl']),
                title: Text(data['nome'] ?? 'Sem nome'),
                subtitle: Text('CPF: ${data['cpf'] ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue),
                      onPressed: () => _falarComMotorista(uid, data['nome']),
                    ),
                    ElevatedButton(
                      onPressed: () => _aprovar(uid),
                      child: const Text("APROVAR"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListaAuditoriaAtiva() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('docsVerificados', isEqualTo: true)
          .where('role', isEqualTo: 'motorista')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nenhum motorista verificado"));
        }

        final docs = snapshot.data!.docs
            .where((doc) => doc['nome']?.toLowerCase().contains(_termoBusca) ?? false)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _buildAvatar(data['fotoUrl']),
                title: Text(data['nome'] ?? 'Sem nome'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CPF: ${data['cpf'] ?? 'N/A'}'),
                    Text('Verificado em: ${data['dataVerificacao'] ?? 'N/A'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.undo, color: Colors.orange.shade700),
                  onPressed: () => _reverterHomologacao(uid, data['nome']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _falarComMotorista(String uid, String? nome) {
    // Implementar chat ou notas internas
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat com $nome aberto")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Gestão e Auditoria"),
        backgroundColor: Colors.green.shade900,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "PARA APROVAR"), Tab(text: "MONITORAMENTO")],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildResumoOperacional(),
              _buildSearchBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildListaSolicitacoes(), _buildListaAuditoriaAtiva()],
                ),
              ),
            ],
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        controller: _buscaController,
        onChanged: (val) => setState(() => _termoBusca = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Localizar motorista...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}