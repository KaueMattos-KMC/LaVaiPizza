// Modelos das respostas de pedido da API (os nomes seguem o JSON).

double _d(Object? v) => (v as num).toDouble();

/// Linha calculada pelo servidor (simulação e pedido criado).
class ItemCalculado {
  final int pizzaId;
  final String pizza;
  final String tamanho;
  final int quantidade;
  final double precoUnitario;
  final double? precoPromocional;
  final double totalItem;

  const ItemCalculado({
    required this.pizzaId,
    required this.pizza,
    required this.tamanho,
    required this.quantidade,
    required this.precoUnitario,
    required this.precoPromocional,
    required this.totalItem,
  });

  factory ItemCalculado.fromJson(Map<String, dynamic> j) => ItemCalculado(
        pizzaId: j['pizzaId'] as int,
        pizza: j['pizza'] as String,
        tamanho: j['tamanho'] as String,
        quantidade: j['quantidade'] as int,
        precoUnitario: _d(j['precoUnitario']),
        precoPromocional: (j['precoPromocional'] as num?)?.toDouble(),
        totalItem: _d(j['totalItem']),
      );
}

class PromocaoAplicada {
  final int id;
  final String nome;
  final double desconto;

  const PromocaoAplicada({required this.id, required this.nome, required this.desconto});

  factory PromocaoAplicada.fromJson(Map<String, dynamic> j) =>
      PromocaoAplicada(id: j['id'] as int, nome: j['nome'] as String, desconto: _d(j['desconto']));
}

/// Resposta de POST /api/v1/pedidos/simular: valores do carrinho calculados pelo servidor.
class Simulacao {
  final List<ItemCalculado> itens;
  final List<PromocaoAplicada> promocoes;
  final double subtotal;
  final double desconto;
  final double taxaEntrega;
  final double total;
  final int tempoEstimado;

  const Simulacao({
    required this.itens,
    required this.promocoes,
    required this.subtotal,
    required this.desconto,
    required this.taxaEntrega,
    required this.total,
    required this.tempoEstimado,
  });

  ItemCalculado? itemDe(int pizzaId, String tamanho) {
    for (final i in itens) {
      if (i.pizzaId == pizzaId && i.tamanho == tamanho) return i;
    }
    return null;
  }

  factory Simulacao.fromJson(Map<String, dynamic> j) => Simulacao(
        itens: (j['itens'] as List).map((e) => ItemCalculado.fromJson(e as Map<String, dynamic>)).toList(),
        promocoes: (j['promocoes'] as List).map((e) => PromocaoAplicada.fromJson(e as Map<String, dynamic>)).toList(),
        subtotal: _d(j['subtotal']),
        desconto: _d(j['desconto']),
        taxaEntrega: _d(j['taxaEntrega']),
        total: _d(j['total']),
        tempoEstimado: j['tempoEstimado'] as int,
      );
}

/// Dados do cliente enviados no pedido (sem login).
class DadosCliente {
  final String nome;
  final String telefone;
  final String? email;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String? cidade;
  final String cep;

  const DadosCliente({
    required this.nome,
    required this.telefone,
    this.email,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    this.cidade,
    required this.cep,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
        'email': email,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'cep': cep,
      };
}

/// Resposta de POST /api/v1/pedidos.
class PedidoCriado {
  final int id;
  final String codigoAcompanhamento;
  final double total;
  final int tempoEstimado;

  const PedidoCriado({
    required this.id,
    required this.codigoAcompanhamento,
    required this.total,
    required this.tempoEstimado,
  });

  factory PedidoCriado.fromJson(Map<String, dynamic> j) => PedidoCriado(
        id: j['id'] as int,
        codigoAcompanhamento: j['codigoAcompanhamento'] as String,
        total: _d(j['total']),
        tempoEstimado: j['tempoEstimado'] as int,
      );
}

/// Etapa da linha do tempo do acompanhamento.
class Etapa {
  final String status;
  final bool concluida;
  final bool atual;
  final DateTime? horario;

  const Etapa({required this.status, required this.concluida, required this.atual, this.horario});

  factory Etapa.fromJson(Map<String, dynamic> j) => Etapa(
        status: j['status'] as String,
        concluida: j['concluida'] as bool,
        atual: j['atual'] as bool,
        horario: j['horario'] == null ? null : DateTime.parse(j['horario'] as String),
      );
}

class ItemAcompanhamento {
  final String pizza;
  final String tamanho;
  final int quantidade;

  const ItemAcompanhamento({required this.pizza, required this.tamanho, required this.quantidade});

  factory ItemAcompanhamento.fromJson(Map<String, dynamic> j) => ItemAcompanhamento(
        pizza: j['pizza'] as String,
        tamanho: j['tamanho'] as String,
        quantidade: j['quantidade'] as int,
      );
}

/// Resposta de GET /api/v1/pedidos/acompanhar/{codigo}. Só o primeiro nome e o bairro do cliente.
class Acompanhamento {
  static const entregue = 'Entregue';

  final String codigoAcompanhamento;
  final String status;
  final DateTime dataHora;
  final int? tempoEstimado;
  final String cliente;
  final String bairro;
  final List<ItemAcompanhamento> itens;
  final double total;
  final List<Etapa> etapas;

  const Acompanhamento({
    required this.codigoAcompanhamento,
    required this.status,
    required this.dataHora,
    required this.tempoEstimado,
    required this.cliente,
    required this.bairro,
    required this.itens,
    required this.total,
    required this.etapas,
  });

  bool get foiEntregue => status == entregue;

  factory Acompanhamento.fromJson(Map<String, dynamic> j) => Acompanhamento(
        codigoAcompanhamento: j['codigoAcompanhamento'] as String,
        status: j['status'] as String,
        dataHora: DateTime.parse(j['dataHora'] as String),
        tempoEstimado: j['tempoEstimado'] as int?,
        cliente: j['cliente'] as String,
        bairro: j['bairro'] as String,
        itens: (j['itens'] as List).map((e) => ItemAcompanhamento.fromJson(e as Map<String, dynamic>)).toList(),
        total: _d(j['total']),
        etapas: (j['etapas'] as List).map((e) => Etapa.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
