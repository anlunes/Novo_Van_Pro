import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Assumindo uso de dotenv

// Modelos simplificados para tipagem
class Estado {
  final int id;
  final String nome;
  final String sigla;
  Estado({required this.id, required this.nome, required this.sigla});
  factory Estado.fromJson(Map<String, dynamic> json) => 
      Estado(id: json['id'], nome: json['nome'], sigla: json['sigla']);
}

class Cidade {
  final int id;
  final String nome;
  Cidade({required this.id, required this.nome});
  factory Cidade.fromJson(Map<String, dynamic> json) => 
      Cidade(id: json['id'], nome: json['nome']);
}

class AlunoService {
  final http.Client _client;
  final String _apiKey = dotenv.env['API_KEY'] ?? '';
  final String _baseUrl = dotenv.env['BASE_URL'] ?? '';
  final Duration _timeout = const Duration(seconds: 10);

  AlunoService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Estado>> buscarEstados() async {
    try {
      final res = await _client.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      ).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Estado.fromJson(e)).toList();
      }
      throw Exception('Falha ao buscar estados: ${res.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão ao buscar estados: $e');
    }
  }

  Future<List<Cidade>> buscarCidades(String ufId) async {
    try {
      final res = await _client.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$ufId/municipios?orderBy=nome'),
      ).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Cidade.fromJson(e)).toList();
      }
      throw Exception('Falha ao buscar cidades: ${res.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão ao buscar cidades: $e');
    }
  }

  Future<String?> uploadFoto(Uint8List bytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload_foto.php'));
      request.fields['api_key'] = _apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: 'aluno_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      var response = await request.send().timeout(_timeout);
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      
      return jsonResponse['status'] == 'success' ? jsonResponse['url'] : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> salvarAluno({required Map<String, dynamic> dados, String? docId}) async {
    final collection = FirebaseFirestore.instance.collection('alunos');
    if (docId == null) {
      await collection.add(dados);
    } else {
      await collection.doc(docId).update(dados);
    }
  }
}