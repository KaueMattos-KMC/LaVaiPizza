// Modelos da área do entregador (respostas de /auth/login e /admin/pedidos).

/// Resposta do login: token JWT e quem entrou. Fica só na memória do app
/// (ao fechar o app, o entregador entra de novo).
class SessaoFuncionario {
  final String token;
  final DateTime expiraEm;
  final String nome;
  final String cargo;

  const SessaoFuncionario({required this.token, required this.expiraEm, required this.nome, required this.cargo});

  static const cargoEntregador = 'Entregador';

  bool get ehEntregador => cargo == cargoEntregador;

  factory SessaoFuncionario.fromJson(Map<String, dynamic> j) {
    final funcionario = j['funcionario'] as Map<String, dynamic>;
    return SessaoFuncionario(
      token: j['token'] as String,
      expiraEm: DateTime.parse(j['expiraEm'] as String),
      nome: funcionario['nome'] as String,
      cargo: funcionario['cargo'] as String,
    );
  }
}

class ItemEntrega {
  final String pizza;
  final String tamanho;
  final int quantidade;

  const ItemEntrega({required this.pizza, required this.tamanho, required this.quantidade});

  factory ItemEntrega.fromJson(Map<String, dynamic> j) => ItemEntrega(
        pizza: j['pizza'] as String,
        tamanho: j['tamanho'] as String,
        quantidade: j['quantidade'] as int,
      );
}

/// Pedido na fila do entregador. "proximoStatusPermitido" vem do servidor:
/// é o único botão que a tela mostra (nulo = nada a fazer neste pedido).
class Entrega {
  final int id;
  final String codigoAcompanhamento;
  final String status;
  final String cliente;
  final String? telefone;
  final String? endereco;
  final String bairro;
  final List<ItemEntrega> itens;
  final double total;
  final String? proximoStatusPermitido;
  final int minutosDesdeCriacao;

  const Entrega({
    required this.id,
    required this.codigoAcompanhamento,
    required this.status,
    required this.cliente,
    required this.telefone,
    required this.endereco,
    required this.bairro,
    required this.itens,
    required this.total,
    required this.proximoStatusPermitido,
    required this.minutosDesdeCriacao,
  });

  factory Entrega.fromJson(Map<String, dynamic> j) => Entrega(
        id: j['id'] as int,
        codigoAcompanhamento: j['codigoAcompanhamento'] as String,
        status: j['status'] as String,
        cliente: j['cliente'] as String,
        telefone: j['telefone'] as String?,
        endereco: j['endereco'] as String?,
        bairro: j['bairro'] as String,
        itens: (j['itens'] as List).map((e) => ItemEntrega.fromJson(e as Map<String, dynamic>)).toList(),
        total: (j['total'] as num).toDouble(),
        proximoStatusPermitido: j['proximoStatusPermitido'] as String?,
        minutosDesdeCriacao: j['minutosDesdeCriacao'] as int,
      );
}
