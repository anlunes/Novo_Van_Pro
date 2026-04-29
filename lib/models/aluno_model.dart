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
  final String mesAvaliado;
  final Timestamp? ultimaAtualizacao;
  final Timestamp? ultimoPagamento;
  // statusEmbarque: 'aguardando', 'embarcado_ida', 'na_escola',
  //                 'embarcado_volta', 'em_casa', 'nao_vai_hoje'
  final String statusEmbarque;
  final Timestamp? timestampEmbarque;
  final int? servidorId;

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
    this.mesAvaliado = '',
    this.ultimaAtualizacao,
    this.ultimoPagamento,
    this.statusEmbarque = 'aguardando',
    this.timestampEmbarque,
    this.servidorId,
  });

  // ──────────────────────────────────────────────────────────
  // factory: lê de DocumentSnapshot do Firestore (camelCase)
  // ──────────────────────────────────────────────────────────
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
      nomeResponsavel: data['nomeResponsavel'] ?? 'Responsavel',
      vanCode: data['vanCode'] ?? '',
      status: data['status'] ?? 'Aguardando',
      vaiHoje: data['vaiHoje'] ?? true,
      cienteMotorista: data['cienteMotorista'] ?? false,
      pago: data['pago'] ?? false,
      valorMensalidade: parsedValor,
      ordem: data['ordem'] ?? 0,
      solicitacaoContato: data['solicitacaoContato'] ?? false,
      respostaContato: data['respostaContato'] ?? '',
      logs: (data['logs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      statusContratacao: data['statusContratacao'] ?? 'ativo',
      diaPagamento: data['diaPagamento'] ?? 5,
      motivoRecusa: data['motivoRecusa'] ?? '',
      horarioEntrada: data['horarioEntrada'] ?? '',
      horarioEntradaMinutos: data['horarioEntradaMinutos'] ?? 0,
      horarioSaida: data['horarioSaida'] ?? '',
      horarioSaidaMinutos: data['horarioSaidaMinutos'] ?? 0,
      avaliadoNoCiclo: data['avaliadoNoCiclo'] ?? false,
      mesAvaliado: data['mesAvaliado'] ?? '',
      ultimaAtualizacao: data['ultimaAtualizacao'] as Timestamp?,
      ultimoPagamento: data['ultimoPagamento'] as Timestamp?,
      statusEmbarque: data['statusEmbarque'] ?? 'aguardando',
      timestampEmbarque: data['timestampEmbarque'] as Timestamp?,
      servidorId: data['servidorId'] as int?,
    );
  }

  // ──────────────────────────────────────────────────────────
  // factory: lê do Map mesclado (camelCase) produzido por
  // _buildMergedMap() em pais_screen.dart.
  // Aceita valores bool OU int (0/1) nos campos booleanos para
  // ser robusto tanto com dados do Firestore quanto do servidor.
  // ──────────────────────────────────────────────────────────
  factory Aluno.fromMapa(String id, Map<String, dynamic> m) {
    // Helper: converte bool ou int(0/1) → bool
    bool asBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is int) return v != 0;
      return fallback;
    }

    // Helper: converte num ou String → double
    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Helper: converte num ou String → int
    int asInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return Aluno(
      id: id,
      nome:                    m['nome']                 ?? '',
      endereco:                m['endereco']             ?? '',
      bairro:                  m['bairro']               ?? '',
      municipio:               m['municipio']            ?? '',
      estado:                  m['estado']               ?? '',
      nomeEscola:              m['nomeEscola']           ?? '',
      escolaId:                m['escolaId']             ?? '',
      enderecoEscola:          m['enderecoEscola']       ?? '',
      telefone:                m['telefone']             ?? '',
      fotoUrl:                 m['fotoUrl']              ?? '',
      responsavelUid:          m['responsavelUid']       ?? '',
      nomeResponsavel:         m['nomeResponsavel']      ?? 'Responsável',
      vanCode:                 m['vanCode']              ?? '',
      status:                  m['status']               ?? 'Aguardando',
      vaiHoje:                 asBool(m['vaiHoje'],          fallback: true),
      cienteMotorista:         asBool(m['cienteMotorista']),
      pago:                    asBool(m['pago']),
      valorMensalidade:        asDouble(m['valorMensalidade']),
      ordem:                   asInt(m['ordem']),
      solicitacaoContato:      asBool(m['solicitacaoContato']),
      respostaContato:         m['respostaContato']      ?? '',
      logs: (m['logs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      statusContratacao:       m['statusContratacao']    ?? 'ativo',
      diaPagamento:            asInt(m['diaPagamento'],     fallback: 5),
      motivoRecusa:            m['motivoRecusa']         ?? '',
      horarioEntrada:          m['horarioEntrada']       ?? '',
      horarioEntradaMinutos:   asInt(m['horarioEntradaMinutos']),
      horarioSaida:            m['horarioSaida']         ?? '',
      horarioSaidaMinutos:     asInt(m['horarioSaidaMinutos']),
      avaliadoNoCiclo:         asBool(m['avaliadoNoCiclo']),
      mesAvaliado:             m['mesAvaliado']          ?? '',
      // Timestamps só existem quando vêm do Firestore
      ultimaAtualizacao:  m['ultimaAtualizacao']  as Timestamp?,
      ultimoPagamento:    m['ultimoPagamento']    as Timestamp?,
      statusEmbarque:     m['statusEmbarque']     ?? 'aguardando',
      timestampEmbarque:  m['timestampEmbarque']  as Timestamp?,
      // servidorId pode chegar como int (Firestore) ou precisar de parse
      servidorId: m['servidorId'] is int
          ? m['servidorId'] as int
          : (m['servidorId'] != null
              ? int.tryParse(m['servidorId'].toString())
              : null),
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
      'mesAvaliado': mesAvaliado,
      'ultimaAtualizacao': ultimaAtualizacao ?? FieldValue.serverTimestamp(),
      if (ultimoPagamento != null) 'ultimoPagamento': ultimoPagamento,
      'statusEmbarque': statusEmbarque,
      if (timestampEmbarque != null) 'timestampEmbarque': timestampEmbarque,
      if (servidorId != null) 'servidorId': servidorId,
    };
  }

  // Retorna true apenas quando o aluno esta dentro da van
  // Usado para abrir/fechar a janela de GPS para o pai
  bool get podeVerGps {
    return statusEmbarque == 'embarcado_ida' ||
        statusEmbarque == 'embarcado_volta';
  }

  // Label legivel do status de embarque para exibir no card do pai
  String get statusEmbarqueLabel {
    switch (statusEmbarque) {
      case 'embarcado_ida':
        return 'Na van - Escola';
      case 'na_escola':
        return 'Na escola';
      case 'embarcado_volta':
        return 'Na van - Casa';
      case 'em_casa':
        return 'Chegou em casa';
      case 'nao_vai_hoje':
        return 'Nao vai hoje';
      case 'aguardando':
      default:
        return 'Aguardando van';
    }
  }
}
