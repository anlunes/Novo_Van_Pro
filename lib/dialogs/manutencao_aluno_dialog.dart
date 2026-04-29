import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// flutter_image_compress removido — não suporta web.

// ── Constantes da API ─────────────────────────────────────────
const String _kApiBase   = 'https://novo.balcao2ponto0.com.br/api_alunos.php';
const String _kApiUpload = 'https://novo.balcao2ponto0.com.br/upload_foto.php';
const String _kApiKey    = 'VanPro@2026#Secure';

class ManutencaoAlunoDialog extends StatefulWidget {
  final Map? alunoExistente;
  final String? docId;
  final String vanCode;
  final String nomeResponsavel;
  final String responsavelUid;
  final String cidadeResponsavel;

  const ManutencaoAlunoDialog({
    super.key,
    this.alunoExistente,
    this.docId,
    required this.vanCode,
    required this.nomeResponsavel,
    required this.responsavelUid,
    required this.cidadeResponsavel,
  });

  @override
  State<ManutencaoAlunoDialog> createState() => _ManutencaoAlunoDialogState();
}

class _ManutencaoAlunoDialogState extends State<ManutencaoAlunoDialog> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────
  late TextEditingController _nomeController;
  late TextEditingController _escolaController;
  late TextEditingController _enderecoController;
  late TextEditingController _bairroController;
  late TextEditingController _municipioController;
  late TextEditingController _estadoController;
  late TextEditingController _telefoneController;
  late TextEditingController _horarioEntradaCtrl;
  late TextEditingController _horarioSaidaCtrl;

  Uint8List? _imagemSelecionada;
  String? _fotoUrl;
  bool _isLoading = false;
  int? _servidorId; // ID retornado pelo MySQL

  // ── Init ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final a = widget.alunoExistente;

    _nomeController      = TextEditingController(text: a?['nome'] ?? '');
    _escolaController    = TextEditingController(text: a?['nomeEscola'] ?? '');
    _enderecoController  = TextEditingController(text: a?['endereco'] ?? '');
    _bairroController    = TextEditingController(text: a?['bairro'] ?? '');
    _municipioController = TextEditingController(
        text: a?['municipio'] ?? widget.cidadeResponsavel);
    _estadoController    = TextEditingController(text: a?['estado'] ?? '');
    _telefoneController  = TextEditingController(text: a?['telefone'] ?? '');
    _horarioEntradaCtrl  = TextEditingController(text: a?['horarioEntrada'] ?? '');
    _horarioSaidaCtrl    = TextEditingController(text: a?['horarioSaida'] ?? '');
    _fotoUrl    = a?['fotoUrl'];
    final sid = a?['servidorId'];
    _servidorId = sid is int ? sid : int.tryParse('${sid ?? ''}');
  }

  // ── Helpers de horário ────────────────────────────────────────
  Future<void> _selecionarHorario(TextEditingController ctrl) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      ctrl.text = '$hh:$mm';
    }
  }

  int _horarioParaMinutos(String horario) {
    if (horario.isEmpty) return 0;
    final parts = horario.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  // ── Imagem ────────────────────────────────────────────────────
  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imagemSelecionada = bytes);
    }
  }

  Future<String> _uploadFoto() async {
    if (_imagemSelecionada == null) return _fotoUrl ?? '';
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_kApiUpload));
      request.headers['X-Api-Key'] = _kApiKey;
      request.fields['tipo']       = 'alunos';
      request.fields['uid']        = widget.responsavelUid;
      request.files.add(http.MultipartFile.fromBytes(
        'foto',
        _imagemSelecionada!,
        filename: '${widget.responsavelUid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res      = await http.Response.fromStream(streamed);
      debugPrint('>>> upload_foto status: ${res.statusCode} body: ${res.body}');
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['url'] as String? ?? '';
      }
      debugPrint('>>> upload_foto falhou: ${res.body}');
    } catch (e) {
      debugPrint('>>> upload_foto erro: $e');
    }
    return _fotoUrl ?? '';
  }

  // ── Servidor PHP ──────────────────────────────────────────────
  Future<int?> _salvarNoServidor({
    required String firebaseStatusId,
    required String fotoUrl,
  }) async {
    // ── ALTERAÇÃO 1: body expandido com TODOS os campos do MySQL ──
    final body = {
      'firebase_status_id':      firebaseStatusId,
      'responsavel_uid':         widget.responsavelUid,
      'nome_responsavel':        widget.nomeResponsavel,
      'van_code':                widget.vanCode,
      'nome':                    _nomeController.text.trim(),
      'nome_escola':             _escolaController.text.trim(),
      'endereco_escola':         '',           // não há campo no form ainda; mantém vazio
      'endereco':                _enderecoController.text.trim(),
      'bairro':                  _bairroController.text.trim(),
      'municipio':               _municipioController.text.trim(),
      'estado':                  _estadoController.text.trim(),
      'telefone':                _telefoneController.text.trim(),
      'horario_entrada':         _horarioEntradaCtrl.text.trim(),
      'horario_entrada_minutos': _horarioParaMinutos(_horarioEntradaCtrl.text.trim()),
      'horario_saida':           _horarioSaidaCtrl.text.trim(),
      'horario_saida_minutos':   _horarioParaMinutos(_horarioSaidaCtrl.text.trim()),
      'foto_url':                fotoUrl,
      'status_contratacao':      'ativo',
      // ── Financeiro ──────────────────────────────────────────
      'valor_mensalidade':       widget.alunoExistente?['valorMensalidade'] ?? 0.0,
      'dia_pagamento':           widget.alunoExistente?['diaPagamento'] ?? 5,
      'pago':                    (widget.alunoExistente?['pago'] == true) ? 1 : 0,
      'ultimo_pagamento':        null,         // sem campo no form ainda; servidor ignora null
      // ── Operacional ─────────────────────────────────────────
      'ordem':                   widget.alunoExistente?['ordem'] ?? 0,
      'status':                  widget.alunoExistente?['status'] ?? 'Aguardando',
      'vai_hoje':                (widget.alunoExistente?['vaiHoje'] != false) ? 1 : 0,
      'ciente_motorista':        (widget.alunoExistente?['cienteMotorista'] == true) ? 1 : 0,
      'solicitacao_contato':     (widget.alunoExistente?['solicitacaoContato'] == true) ? 1 : 0,
      'resposta_contato':        widget.alunoExistente?['respostaContato'] ?? '',
      'motivo_recusa':           widget.alunoExistente?['motivoRecusa'] ?? '',
      // ── Avaliação ────────────────────────────────────────────
      'avaliado_no_ciclo':       (widget.alunoExistente?['avaliadoNoCiclo'] == true) ? 1 : 0,
      'mes_avaliado':            widget.alunoExistente?['mesAvaliado'] ?? '',
    };

    // Remove entradas com valor null para não sobrescrever dados no servidor
    body.removeWhere((k, v) => v == null);

    final headers = {
      'Content-Type': 'application/json',
      'X-Api-Key':    _kApiKey,
    };

    try {
      if (_servidorId != null) {
        // EDITAR
        await http.put(
          Uri.parse('$_kApiBase/alunos/$_servidorId'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));
        return _servidorId;
      } else {
        // CRIAR
        final res = await http.post(
          Uri.parse('$_kApiBase'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));

        debugPrint('>>> servidor status: ${res.statusCode} body: ${res.body}');

        if (res.statusCode == 201) {
          final json = jsonDecode(res.body);
          return json['servidorid'] as int?; // ← corrigido
        }
        debugPrint('Servidor retornou ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Servidor indisponivel (nao bloqueia): $e');
    }
    return null;
  }

  // ── Salvar ────────────────────────────────────────────────────
  Future<void> _salvarAluno() async {
    debugPrint('>>> _salvarAluno chamado');
    final isValid = _formKey.currentState!.validate();
    debugPrint('>>> formulario valido: $isValid');
    if (!isValid) return;
    setState(() => _isLoading = true);
    debugPrint('>>> isLoading = true, iniciando upload...');

    try {
      final fotoUrl = await _uploadFoto();

      // ── ALTERAÇÃO 2: Firestore recebe APENAS os 5 campos operacionais ──
      // Todos os dados cadastrais, financeiros e operacionais vão para o
      // servidor MySQL via _salvarNoServidor(). O Firestore fica só com
      // o que precisa de tempo real + chaves de ligação.
      final Map<String, dynamic> dadosFirestore = {
        'responsavelUid':    widget.responsavelUid,
        'servidorId':        _servidorId,          // null na criação; atualizado logo abaixo
        'statusEmbarque':    widget.alunoExistente?['statusEmbarque'] ?? 'aguardando',
        'timestampEmbarque': FieldValue.serverTimestamp(),
        'vaiHoje':           widget.alunoExistente?['vaiHoje'] ?? true,
      };

      final col = FirebaseFirestore.instance.collection('alunos');
      String firebaseDocId = widget.docId ?? '';

      if (widget.docId != null) {
        // ── EDITAR: atualiza só os 5 campos no doc existente ──
        await col.doc(widget.docId).update(dadosFirestore);
        firebaseDocId = widget.docId!;
      } else {
        // ── CRIAR: cria doc com os 5 campos + firebaseStatusId próprio ──
        dadosFirestore['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await col.add(dadosFirestore);
        firebaseDocId = docRef.id;
        // Registra o próprio docId como firebaseStatusId para rastreio
        await docRef.update({'firebaseStatusId': firebaseDocId});
      }

      // ── Salva TUDO no servidor (não bloqueia o fluxo se falhar) ──
      final servidorId = await _salvarNoServidor(
        firebaseStatusId: firebaseDocId,
        fotoUrl: fotoUrl,
      );

      // Grava servidorId de volta no Firestore para uso futuro
      if (servidorId != null) {
        await col.doc(firebaseDocId).update({'servidorId': servidorId});
        debugPrint('>>> servidorId salvo: $servidorId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aluno salvo com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Widgets auxiliares ────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    bool obrigatorio = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label + (obrigatorio ? ' *' : ''),
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: readOnly && onTap != null
              ? const Icon(Icons.access_time, color: Colors.blue)
              : null,
        ),
        validator: obrigatorio
            ? (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    widget.docId != null ? Icons.edit : Icons.person_add,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.docId != null ? "Editar Aluno" : "Novo Aluno",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              if (widget.vanCode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Van vinculada: ${widget.vanCode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nenhuma van vinculada ao seu perfil. '
                          'Solicite o código ao motorista.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              _buildSectionTitle('DADOS DO ALUNO'),

              _buildTextField(
                controller: _nomeController,
                label: 'Nome completo',
                icon: Icons.person,
                obrigatorio: true,
              ),

              _buildTextField(
                controller: _telefoneController,
                label: 'Telefone de contato',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              Row(
                children: [
                  GestureDetector(
                    onTap: _selecionarImagem,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imagemSelecionada != null
                          ? MemoryImage(_imagemSelecionada!)
                          : (_fotoUrl != null && _fotoUrl!.isNotEmpty
                              ? NetworkImage(_fotoUrl!) as ImageProvider
                              : null),
                      child: (_imagemSelecionada == null &&
                              (_fotoUrl == null || _fotoUrl!.isEmpty))
                          ? const Icon(Icons.camera_alt,
                              size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toque na foto para selecionar uma imagem da galeria.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),

              _buildSectionTitle('ESCOLA'),

              _buildTextField(
                controller: _escolaController,
                label: 'Nome da escola',
                icon: Icons.school,
                obrigatorio: true,
              ),

              _buildTextField(
                controller: _horarioEntradaCtrl,
                label: 'Horário de entrada',
                icon: Icons.login,
                readOnly: true,
                obrigatorio: true,
                onTap: () => _selecionarHorario(_horarioEntradaCtrl),
              ),

              _buildTextField(
                controller: _horarioSaidaCtrl,
                label: 'Horário de saída',
                icon: Icons.logout,
                readOnly: true,
                obrigatorio: true,
                onTap: () => _selecionarHorario(_horarioSaidaCtrl),
              ),

              _buildSectionTitle('ENDEREÇO DO ALUNO'),

              _buildTextField(
                controller: _enderecoController,
                label: 'Rua / Endereço',
                icon: Icons.location_on,
              ),

              _buildTextField(
                controller: _bairroController,
                label: 'Bairro',
                icon: Icons.map,
              ),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 6),
                      child: TextFormField(
                        controller: _municipioController,
                        decoration: const InputDecoration(
                          labelText: 'Município',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 6),
                      child: TextFormField(
                        controller: _estadoController,
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 2,
                        buildCounter: (_, {required currentLength,
                                required isFocused,
                                required maxLength}) =>
                            null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? const SizedBox(
                          width: 100,
                          child: Center(
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        )
                      : ElevatedButton.icon(
                          onPressed: _salvarAluno,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('SALVAR'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _escolaController.dispose();
    _enderecoController.dispose();
    _bairroController.dispose();
    _municipioController.dispose();
    _estadoController.dispose();
    _telefoneController.dispose();
    _horarioEntradaCtrl.dispose();
    _horarioSaidaCtrl.dispose();
    super.dispose();
  }
}
