import '../utils/formato.dart';

/// Os três tamanhos, na ordem de exibição. O valor é o mesmo usado pela API.
class Tamanhos {
  Tamanhos._();

  static const pequena = 'Pequena';
  static const media = 'Media';
  static const grande = 'Grande';

  static const todos = [pequena, media, grande];

  static const _rotulo = {pequena: 'PEQUENA', media: 'MÉDIA', grande: 'GRANDE'};
  static const _sigla = {pequena: 'P', media: 'M', grande: 'G'};
  static const _gramas = {pequena: '320g', media: '530g', grande: '860g'};

  static String rotulo(String t) => _rotulo[t] ?? t;
  static String sigla(String t) => _sigla[t] ?? t;
  static String gramas(String t) => _gramas[t] ?? '';
}

/// Preço de um tamanho. [precoPromocional] só vem quando há promoção (GET /api/v1/pizzas).
class PizzaPreco {
  final String tamanho;
  final double preco;
  final double? precoPromocional;

  const PizzaPreco({required this.tamanho, required this.preco, this.precoPromocional});

  bool get emPromocao => precoPromocional != null;

  factory PizzaPreco.fromJson(Map<String, dynamic> json) => PizzaPreco(
        tamanho: json['tamanho'] as String,
        preco: (json['preco'] as num).toDouble(),
        precoPromocional: (json['precoPromocional'] as num?)?.toDouble(),
      );
}

/// Promoção de uma pizza, para o selo do cardápio.
class PromocaoResumo {
  final int id;
  final String nome;
  final String tipo;
  final double valor;

  const PromocaoResumo({required this.id, required this.nome, required this.tipo, required this.valor});

  /// Mesmo texto do selo do site: "-20%", "-R$ 5,00" ou "Promoção".
  String get selo => switch (tipo) {
        'PERCENTUAL' => '-${numero(valor)}%',
        'VALOR_FIXO' => '-${brl(valor)}',
        _ => 'Promoção',
      };

  factory PromocaoResumo.fromJson(Map<String, dynamic> json) => PromocaoResumo(
        id: json['id'] as int,
        nome: json['nome'] as String,
        tipo: json['tipo'] as String,
        valor: (json['valor'] as num).toDouble(),
      );
}

class Pizza {
  final int id;
  final String nome;
  final String descricao;
  final String? imagemUrl;
  final List<PizzaPreco> precos;
  final PromocaoResumo? promocao;

  const Pizza({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imagemUrl,
    required this.precos,
    required this.promocao,
  });

  PizzaPreco? precoDe(String tamanho) {
    for (final p in precos) {
      if (p.tamanho == tamanho) return p;
    }
    return null;
  }

  /// A API já devolve os preços do menor para o maior tamanho.
  PizzaPreco get menorPreco => precos.first;

  factory Pizza.fromJson(Map<String, dynamic> json) => Pizza(
        id: json['id'] as int,
        nome: json['nome'] as String,
        descricao: (json['descricao'] as String?) ?? '',
        imagemUrl: json['imagemUrl'] as String?,
        precos: (json['precos'] as List).map((p) => PizzaPreco.fromJson(p as Map<String, dynamic>)).toList(),
        promocao: json['promocao'] == null ? null : PromocaoResumo.fromJson(json['promocao'] as Map<String, dynamic>),
      );
}

/// Promoção vigente (GET /api/v1/promocoes/vigentes), para a faixa "Promoções de hoje".
class Promocao {
  final int id;
  final String nome;
  final String tipo;
  final double? valorMinimo;

  const Promocao({required this.id, required this.nome, required this.tipo, this.valorMinimo});

  factory Promocao.fromJson(Map<String, dynamic> json) => Promocao(
        id: json['id'] as int,
        nome: json['nome'] as String,
        tipo: json['tipo'] as String,
        valorMinimo: (json['valorMinimo'] as num?)?.toDouble(),
      );
}
