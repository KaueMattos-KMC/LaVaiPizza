import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/pedido.dart';
import '../models/pizza.dart';
import '../services/api_service.dart';
import '../services/preferencias.dart';

class ItemCarrinho {
  final int pizzaId;
  final String tamanho;
  int quantidade;

  ItemCarrinho({required this.pizzaId, required this.tamanho, required this.quantidade});

  Map<String, dynamic> paraSalvar() => {'pizzaId': pizzaId, 'tamanho': tamanho, 'qt': quantidade};

  Map<String, dynamic> paraApi() => {'pizzaId': pizzaId, 'tamanho': tamanho, 'quantidade': quantidade};
}

/// Carrinho do cliente. Fica salvo no aparelho e, a cada mudança, pede ao servidor
/// o cálculo de subtotal, descontos, frete e total (POST /pedidos/simular).
class CarrinhoProvider extends ChangeNotifier {
  CarrinhoProvider(this._api);

  final ApiService _api;
  final List<ItemCarrinho> _itens = [];
  final Map<int, Pizza> _pizzas = {};

  Simulacao? _simulacao;
  bool _calculando = false;
  String? _erro;
  Timer? _espera;
  int _sequencia = 0;

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  bool get vazio => _itens.isEmpty;
  int get totalPizzas => _itens.fold(0, (soma, i) => soma + i.quantidade);
  Simulacao? get simulacao => _simulacao;
  bool get calculando => _calculando;
  String? get erro => _erro;

  /// Só deixa finalizar quando o servidor já devolveu os valores do carrinho atual.
  bool get prontoParaFinalizar => !vazio && _simulacao != null && !_calculando && _erro == null;

  Pizza? pizzaDe(int id) => _pizzas[id];

  List<Map<String, dynamic>> paraApi() => _itens.map((i) => i.paraApi()).toList();

  /// Lê o carrinho salvo no aparelho (chamado ao abrir o app).
  Future<void> carregar() async {
    final salvos = await Preferencias.lerCarrinho();
    for (final s in salvos) {
      final id = s['pizzaId'], tamanho = s['tamanho'], qt = s['qt'];
      if (id is int && tamanho is String && Tamanhos.todos.contains(tamanho) && qt is int) {
        _itens.add(ItemCarrinho(pizzaId: id, tamanho: tamanho, quantidade: qt.clamp(1, AppConfig.maximoPorItem)));
      }
    }
    notifyListeners();
  }

  /// Recebe o cardápio atual e tira do carrinho as pizzas que saíram dele.
  void atualizarCardapio(List<Pizza> cardapio) {
    _pizzas
      ..clear()
      ..addEntries(cardapio.map((p) => MapEntry(p.id, p)));

    final antes = _itens.length;
    _itens.removeWhere((i) => _pizzas[i.pizzaId]?.precoDe(i.tamanho) == null);
    if (_itens.length != antes) _salvar();

    _recalcular();
  }

  void adicionar(Pizza pizza, String tamanho, int quantidade) {
    for (final i in _itens) {
      if (i.pizzaId == pizza.id && i.tamanho == tamanho) {
        i.quantidade = (i.quantidade + quantidade).clamp(1, AppConfig.maximoPorItem);
        _mudou();
        return;
      }
    }
    _itens.add(ItemCarrinho(pizzaId: pizza.id, tamanho: tamanho, quantidade: quantidade));
    _mudou();
  }

  void aumentar(ItemCarrinho item) {
    if (item.quantidade < AppConfig.maximoPorItem) item.quantidade++;
    _mudou();
  }

  /// Diminui; com uma unidade só, tira o item do carrinho (igual ao site).
  void diminuir(ItemCarrinho item) {
    if (item.quantidade > 1) {
      item.quantidade--;
    } else {
      _itens.remove(item);
    }
    _mudou();
  }

  void limpar() {
    _itens.clear();
    _mudou();
  }

  void _mudou() {
    _salvar();
    _recalcular();
  }

  void _salvar() => Preferencias.salvarCarrinho(_itens.map((i) => i.paraSalvar()).toList());

  void _recalcular() {
    _espera?.cancel();

    if (_itens.isEmpty) {
      _sequencia++; // descarta respostas que ainda estejam a caminho
      _simulacao = null;
      _erro = null;
      _calculando = false;
      notifyListeners();
      return;
    }

    _calculando = true;
    notifyListeners();
    // Espera um instante para juntar vários toques seguidos em uma só chamada
    _espera = Timer(const Duration(milliseconds: 250), _simular);
  }

  Future<void> _simular() async {
    final minhaVez = ++_sequencia;
    try {
      final resposta = await _api.simular(paraApi());
      if (minhaVez != _sequencia) return; // chegou depois de uma resposta mais nova
      _simulacao = resposta;
      _erro = null;
    } on ApiException catch (e) {
      if (minhaVez != _sequencia) return;
      _simulacao = null;
      _erro = e.mensagem;
    }
    _calculando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }
}

/// Dados digitados no checkout, mantidos enquanto o app está aberto
/// (voltar ao carrinho e reabrir o checkout não apaga o que já foi digitado).
class RascunhoCheckout {
  final Map<String, String> campos = {};

  void limpar() => campos.clear();
}
