import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../widgets/operacao_motorista_widget.dart';

// --- SERVIÇO DE UPLOAD (EXTRAÍDO PARA SEPARAÇÃO DE RESPONSABILIDADES) ---
class DocumentService {
  static Future<String> uploadDocumento(Uint8List bytes, String tipoDoc) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    String pastaDestino = tipoDoc == 'fotoPerfil' ? 'motoristas/perfil' : 'motoristas/$tipoDoc';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://vanpro.balcao2ponto0.com.br/upload_foto.php'),
    );

    request.fields['api_key'] = apiKey;
    request.fields['pasta'] = pastaDestino;
    request.files.add(http.MultipartFile.fromBytes(
      'foto',
      bytes,
      filename: '${tipoDoc}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ));

    var response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') return jsonResponse['url'];
    }
    throw Exception("Falha ao enviar documento: ${response.statusCode}");
  }
}

class PerfilMotoristaScreen extends StatefulWidget {
  const PerfilMotoristaScreen({super.key});

  @override
  State<PerfilMotoristaScreen> createState() => _PerfilMotoristaScreenState();
}

class _PerfilMotoristaScreenState extends State<PerfilMotoristaScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  Future<void> _visualizarDocumento(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não foi possível abrir o link.")));
    }
  }

  Future<void> _subirImagem(String tipoDoc) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 40);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      Uint8List fileBytes = await image.readAsBytes();
      String urlFinal = await DocumentService.uploadDocumento(fileBytes, tipoDoc);

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        '${tipoDoc}Url': urlFinal,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Documento enviado com sucesso!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao processar upload. Tente novamente.")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ... (Demais métodos como _mostrarDialogCapacidade, _buildAvatarHeader, etc. mantidos conforme original)
  
  // Nota: Para brevidade, os métodos de UI foram omitidos aqui, mas devem ser mantidos como no original.
  // O foco da correção foi a lógica de rede e segurança.

  @override
  Widget build(BuildContext context) {
    // ... (Estrutura de build mantida conforme original)
    return Scaffold(appBar: AppBar(title: const Text("Meu Perfil")), body: const Center(child: Text("Conteúdo da tela")));
  }
}