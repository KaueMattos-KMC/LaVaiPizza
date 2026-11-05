import 'package:flutter/foundation.dart';
import '../models/pizza.dart';

class CartItem {
  final Pizza pizza;
  final Tamanho tamanho;
  int qtd;
  CartItem(this.pizza, this.tamanho, this.qtd);
  double get total => pizza.precos[tamanho]! * qtd;
}

class CartProvider extends ChangeNotifier {
  static const double descontoPercentual = 0.10;
  static const double freteGratisAcima = 50.0;

  final List<CartItem> _itens = [];
  List<CartItem> get itens => List.unmodifiable(_itens);

  int get quantidade => _itens.fold(0, (s, i) => s + i.qtd);
  double get subtotal => _itens.fold(0.0, (s, i) => s + i.total);
  double get desconto => subtotal * descontoPercentual;
  double get total => subtotal - desconto;
  bool get freteGratis => subtotal >= freteGratisAcima;

  void adicionar(Pizza p, Tamanho t, int qtd) {
    final i = _itens.indexWhere((e) => e.pizza.id == p.id && e.tamanho == t);
    if (i >= 0) {
      _itens[i].qtd += qtd;
    } else {
      _itens.add(CartItem(p, t, qtd));
    }
    notifyListeners();
  }

  void alterarQtd(CartItem item, int delta) {
    item.qtd += delta;
    if (item.qtd <= 0) _itens.remove(item);
    notifyListeners();
  }

  void remover(CartItem item) {
    _itens.remove(item);
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
