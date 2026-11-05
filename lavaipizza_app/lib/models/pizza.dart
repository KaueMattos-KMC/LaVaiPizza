enum Tamanho {
  pequena('PEQUENA'),
  medio('MÉDIO'),
  grande('GRANDE');

  final String label;
  const Tamanho(this.label);
}

class Pizza {
  final String id;
  final String nome;
  final String descricao;
  final String imagemUrl;
  final Map<Tamanho, double> precos;

  const Pizza({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imagemUrl,
    required this.precos,
  });

  /// AJUSTE AQUI os nomes dos campos conforme o JSON do seu back-end.
  factory Pizza.fromJson(Map<String, dynamic> json) {
    double p(dynamic v) => (v as num).toDouble();
    return Pizza(
      id: '${json['id']}',
      nome: json['nome'] as String,
      descricao: (json['descricao'] ?? '') as String,
      imagemUrl: (json['imagem'] ?? '') as String,
      precos: {
        Tamanho.pequena: p(json['precoPequena']),
        Tamanho.medio: p(json['precoMedio']),
        Tamanho.grande: p(json['precoGrande']),
      },
    );
  }
}
