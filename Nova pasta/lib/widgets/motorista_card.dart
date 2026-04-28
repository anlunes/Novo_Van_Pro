class MotoristaModel {
  final String nome;
  final String vanCode;
  final String fotoUrl;
  final String telefone;
  final String cidade;
  final String bairro;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final bool documentosVerificados;
  final bool temSeguroAPP;

  MotoristaModel({
    required this.nome,
    required this.vanCode,
    required this.fotoUrl,
    required this.telefone,
    required this.cidade,
    required this.bairro,
    required this.mediaAvaliacoes,
    required this.totalAvaliacoes,
    required this.documentosVerificados,
    required this.temSeguroAPP,
  });

  factory MotoristaModel.fromMap(Map<String, dynamic> map) {
    return MotoristaModel(
      nome: map['nome'] ?? 'Motorista',
      vanCode: map['vanCode'] ?? '',
      fotoUrl: map['fotoUrl'] ?? '',
      telefone: map['telefone'] ?? '',
      cidade: map['municipio'] ?? '',
      bairro: map['bairro'] ?? '',
      mediaAvaliacoes: (map['mediaAvaliacoes'] ?? 0.0).toDouble(),
      totalAvaliacoes: map['totalAvaliacoes'] ?? 0,
      documentosVerificados: map['documentosVerificados'] ?? false,
      temSeguroAPP: map['temSeguroAPP'] ?? false,
    );
  }
}