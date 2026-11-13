import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/entrega.dart';
import '../models/pedido.dart';
import '../models/pizza.dart';

/// Erro da API já com a mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  final int status;
  final String mensagem;

  const ApiException(this.status, this.mensagem);

  @override
  String toString() => mensagem;
}

/// Acesso à API do back-end (mesmas rotas que o site usa em assets/js/api.js).
/// Preços, descontos, frete e total são sempre calculados pelo servidor.
class ApiService {
  ApiService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  static const _tempoLimite = Duration(seconds: 15);

  String get _base => '${AppConfig.apiUrl}/api/v1';

  Future<List<Pizza>> cardapio() async {
    final dados = await _requisitar('GET', '/pizzas') as List;
    return dados.map((e) => Pizza.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Promocao>> promocoesVigentes() async {
    final dados = await _requisitar('GET', '/promocoes/vigentes') as List;
    return dados.map((e) => Promocao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Simulacao> simular(List<Map<String, dynamic>> itens) async {
    final dados = await _requisitar('POST', '/pedidos/simular', corpo: {'itens': itens});
    return Simulacao.fromJson(dados as Map<String, dynamic>);
  }

  Future<PedidoCriado> criarPedido(DadosCliente cliente, List<Map<String, dynamic>> itens) async {
    final dados = await _requisitar('POST', '/pedidos', corpo: {'cliente': cliente.toJson(), 'itens': itens});
    return PedidoCriado.fromJson(dados as Map<String, dynamic>);
  }

  Future<Acompanhamento> acompanhar(String codigo) async {
    final dados = await _requisitar('GET', '/pedidos/acompanhar/${Uri.encodeComponent(codigo)}');
    return Acompanhamento.fromJson(dados as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------- área do entregador (JWT)

  /// POST /auth/login: devolve o token e os dados do funcionário.
  Future<SessaoFuncionario> login(String email, String senha) async {
    final dados = await _requisitar('POST', '/auth/login', corpo: {'email': email, 'senha': senha});
    return SessaoFuncionario.fromJson(dados as Map<String, dynamic>);
  }

  /// Fila do entregador logado: pedidos aguardando coleta e os que ele levou.
  /// Quem filtra pelo cargo é o servidor, a partir do token.
  Future<List<Entrega>> filaDeEntregas(String token) async {
    final dados = await _requisitar('GET', '/admin/pedidos', token: token) as List;
    return dados.map((e) => Entrega.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Avança o pedido um passo ("Saiu para Entrega" ou "Entregue").
  Future<Entrega> avancarStatus(String token, int pedidoId, String novoStatus) async {
    final dados =
        await _requisitar('PATCH', '/admin/pedidos/$pedidoId/status', corpo: {'status': novoStatus}, token: token);
    return Entrega.fromJson(dados as Map<String, dynamic>);
  }

  /// Testa se há uma API LaVaiPizza no endereço informado (GET /health responde "Healthy").
  Future<bool> testarServidor(String endereco) async {
    try {
      final r = await _cliente.get(Uri.parse('$endereco/health')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 && r.body.contains('Healthy');
    } catch (_) {
      return false;
    }
  }

  /// Endereço completo de uma foto enviada pelo admin ("/uploads/...").
  static String urlDaApi(String caminho) => '${AppConfig.apiUrl}$caminho';

  Future<Object?> _requisitar(String metodo, String caminho, {Object? corpo, String? token}) async {
    final uri = Uri.parse('$_base$caminho');
    final cabecalhos = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response resposta;
    try {
      final envio = switch (metodo) {
        'POST' => _cliente.post(uri, headers: cabecalhos, body: jsonEncode(corpo)),
        'PATCH' => _cliente.patch(uri, headers: cabecalhos, body: jsonEncode(corpo)),
        _ => _cliente.get(uri, headers: cabecalhos),
      };
      resposta = await envio.timeout(_tempoLimite);
    } on TimeoutException {
      throw const ApiException(0, 'O servidor demorou para responder. Tente novamente em instantes.');
    } catch (_) {
      throw const ApiException(0, 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.');
    }

    final texto = utf8.decode(resposta.bodyBytes);
    Object? dados;
    try {
      dados = texto.isEmpty ? null : jsonDecode(texto);
    } catch (_) {
      dados = null;
    }

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ApiException(resposta.statusCode, _mensagemDeErro(resposta.statusCode, dados));
    }
    return dados;
  }

  /// Junta as mensagens de validação (ProblemDetails) em um texto só.
  static String _mensagemDeErro(int status, Object? dados) {
    if (dados is Map<String, dynamic>) {
      final erros = dados['errors'];
      if (erros is Map) {
        final mensagens = erros.values.expand((v) => v is List ? v : [v]).map((v) => '$v').toList();
        if (mensagens.isNotEmpty) return mensagens.join(' ');
      }
      final detalhe = dados['detail'];
      if (detalhe is String && detalhe.isNotEmpty) return detalhe;
    }
    if (status == 401) return 'Sua sessão expirou. Entre novamente.';
    if (status == 403) return 'Você não tem permissão para esta operação.';
    if (status == 429) return 'Muitas tentativas em pouco tempo. Aguarde um instante e tente de novo.';
    if (status == 404) return 'Não encontrado.';
    if (status >= 500) return 'O servidor teve um problema. Tente novamente em instantes.';
    return 'Não foi possível concluir a operação.';
  }
}
