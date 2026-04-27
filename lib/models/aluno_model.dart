import 'package:cloud_firestore/cloud_firestore.dart';

class Aluno {
  final String id;
  final String nome;
  final String endereco;
  final String bairro;
  final String municipio;
  final String estado;
  final String nomeEscola;
  final String escolaId;
  final String enderecoEscola;
  final String telefone;
  final String fotoUrl;
  final String responsavelUid;
  final String nomeResponsavel;
  final String vanCode;
  final String status;
  final bool vaiHoje;
  final bool cienteMotorista;
  final bool pago;
  final double valorMensalidade;
  final int ordem;
  final bool solicitacaoContato;
  final String respostaContato;
  final List<Map<String, dynamic>> logs;
  final String statusContratacao;
  final int diaPagamento;
  final String motivoRecusa;
  final String horarioEntrada;
  final int horarioEntradaMinutos;
  final String horarioSaida;
  final int horarioSaidaMinutos;
  final bool avaliadoNoCiclo;
  final Timestamp? ultimaAtualizacao;
  final Timestamp? ultimoPagamento;

  Aluno({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.bairro,
    required this.municipio,
    required this.estado,
    required this.nomeEscola,
    required this.escolaId,
    required this.enderecoEscola,
    required this.telefone,
    required this.fotoUrl,
    required this.responsavelUid,
    required this.nomeResponsavel,
    required this.vanCode,
    required this.status,
    required this.vaiHoje,
    required this.cienteMotorista,
    required this.pago,
    required this.valorMensalidade,
    required this.ordem,
    required this.solicitacaoContato,
    required this.respostaContato,
    required this.logs,
    required this.statusContratacao,
    required this.diaPagamento,
    required this.motivoRecusa,
    required this.horarioEntrada,
    required this.horarioEntradaMinutos,
    required this.horarioSaida,
    required this.horarioSaidaMinutos,
    this.avaliadoNoCiclo = false,
    this.ultimaAtualizacao,
    this.ultimoPagamento,
  });

  factory Aluno.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    double parsedValor = 0.0;
    var rawValor = data['valorMensalidade'];
    if (rawValor != null) {
      if (rawValor is String) parsedValor = double.tryParse(rawValor) ?? 0.0;
      else if (rawValor is num) parsedValor = rawValor.toDouble();
    }
    return Aluno(
      id: doc.id,
      nome: data['nome'] ?? '',
      endereco: data['endereco'] ?? '',
      bairro: data['bairro'] ?? '',
      municipio: data['municipio'] ?? '',
      estado: data['estado'] ?? '',
      nomeEscola: data['nomeEscola'] ?? '',
      escolaId: data['escolaId'] ?? '',
      enderecoEscola: data['enderecoEscola'] ?? '',
      telefone: data['telefone'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      responsavelUid: data['responsavelUid'] ?? '',
      nomeResponsavel: data['nomeResponsavel'] ?? 'Responsável',
      vanCode: data['vanCode'] ?? '',
      status: data['status'] ?? 'Aguardando',
      vaiHoje: data['vaiHoje'] ?? true,
      cienteMotorista: data['cienteMotorista'] ?? false,
      pago: data['pago'] ?? false,
      valorMensalidade: parsedValor,
      ordem: data['ordem'] ?? 0,
      solicitacaoContato: data['solicitacaoContato'] ?? false,
      respostaContato: data['respostaContato'] ?? '',
      logs: (data['logs'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      statusContratacao: data['statusContratacao'] ?? 'ativo',
      diaPagamento: data['diaPagamento'] ?? 5,
      motivoRecusa: data['motivoRecusa'] ?? '',
      horarioEntrada: data['horarioEntrada'] ?? '',
      horarioEntradaMinutos: data['horarioEntradaMinutos'] ?? 0,
      horarioSaida: data['horarioSaida'] ?? '',
      horarioSaidaMinutos: data['horarioSaidaMinutos'] ?? 0,
      avaliadoNoCiclo: data['avaliadoNoCiclo'] ?? false,
      ultimaAtualizacao: data['ultimaAtualizacao'] as Timestamp?,
      ultimoPagamento: data['ultimoPagamento'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'bairro': bairro,
      'municipio': municipio,
      'estado': estado,
      'nomeEscola': nomeEscola,
      'escolaId': escolaId,
      'enderecoEscola': enderecoEscola,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'responsavelUid': responsavelUid,
      'nomeResponsavel': nomeResponsavel,
      'vanCode': vanCode,
      'status': status,
      'vaiHoje': vaiHoje,
      'cienteMotorista': cienteMotorista,
      'pago': pago,
      'valorMensalidade': valorMensalidade,
      'ordem': ordem,
      'solicitacaoContato': solicitacaoContato,
      'respostaContato': respostaContato,
      'logs': logs,
      'statusContratacao': statusContratacao,
      'diaPagamento': diaPagamento,
      'motivoRecusa': motivoRecusa,
      'horarioEntrada': horarioEntrada,
      'horarioEntradaMinutos': horarioEntradaMinutos,
      'horarioSaida': horarioSaida,
      'horarioSaidaMinutos': horarioSaidaMinutos,
      'avaliadoNoCiclo': avaliadoNoCiclo,
      'ultimaAtualizacao': ultimaAtualizacao ?? FieldValue.serverTimestamp(),
    };
  }
}