import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pizza.dart';

abstract class PizzaRepository {
  Future<List<Pizza>> buscarPizzas();
}

const _img = 'https://willianduartte.github.io/PIM-3-Front-End/assets/images';

/// Dados de exemplo (PLACEHOLDER). Troque por [ApiPizzaRepository] em main.dart.
class MockPizzaRepository implements PizzaRepository {
  @override
  Future<List<Pizza>> buscarPizzas() async {
    await Future.delayed(const Duration(milliseconds: 400));
    Map<Tamanho, double> t(double p, double m, double g) =>
        {Tamanho.pequena: p, Tamanho.medio: m, Tamanho.grande: g};
    return [
      Pizza(id: '1', nome: 'Margherita', descricao: 'Molho, mussarela, tomate e manjericão.', imagemUrl: '$_img/pizza1.png', precos: t(29.9, 39.9, 49.9)),
      Pizza(id: '2', nome: 'Calabresa', descricao: 'Calabresa fatiada, cebola e azeitonas.', imagemUrl: '$_img/pizza2.png', precos: t(31.9, 41.9, 51.9)),
      Pizza(id: '3', nome: 'Quatro Queijos', descricao: 'Mussarela, provolone, parmesão e gorgonzola.', imagemUrl: '$_img/pizza3.png', precos: t(34.9, 44.9, 54.9)),
      Pizza(id: '4', nome: 'Frango com Catupiry', descricao: 'Frango desfiado e catupiry cremoso.', imagemUrl: '$_img/pizza4.png', precos: t(33.9, 43.9, 53.9)),
      Pizza(id: '5', nome: 'Portuguesa', descricao: 'Presunto, ovos, cebola, ervilha e mussarela.', imagemUrl: '$_img/pizza5.png', precos: t(34.9, 44.9, 54.9)),
      Pizza(id: '6', nome: 'Pepperoni', descricao: 'Pepperoni crocante e mussarela.', imagemUrl: '$_img/pizza6.png', precos: t(36.9, 46.9, 56.9)),
    ];
  }
}

/// Consome a API do back-end. Ajuste [baseUrl] e o endpoint.
class ApiPizzaRepository implements PizzaRepository {
  final String baseUrl; // ex.: http://10.0.2.2:3000 (emulador Android)
  ApiPizzaRepository(this.baseUrl);

  @override
  Future<List<Pizza>> buscarPizzas() async {
    final res = await http.get(Uri.parse('$baseUrl/pizzas'));
    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar cardápio (${res.statusCode})');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) => Pizza.fromJson(e as Map<String, dynamic>)).toList();
  }
}
