class Motorista {
  final String nome;
  final String telefone;
  final String fotoUrl;
  final String vanCode;
  final bool docsVerificados;
  final String cnhUrl;
  final String vistoriaUrl;
  final String crlvUrl;

  Motorista({
    required this.nome,
    required this.telefone,
    required this.fotoUrl,
    required this.vanCode,
    required this.docsVerificados,
    required this.cnhUrl,
    required this.vistoriaUrl,
    required this.crlvUrl,
  });

  factory Motorista.fromMap(Map<String, dynamic> map) {
    return Motorista(
      nome: map['nome'] ?? 'Sem nome',
      telefone: map['telefone'] ?? '',
      fotoUrl: map['fotoUrl'] ?? '',
      vanCode: map['vanCode'] ?? 'N/A',
      docsVerificados: map['docsVerificados'] ?? false,
      cnhUrl: map['cnhUrl'] ?? '',
      vistoriaUrl: map['vistoriaUrl'] ?? '',
      crlvUrl: map['crlvUrl'] ?? '',
    );
  }
}