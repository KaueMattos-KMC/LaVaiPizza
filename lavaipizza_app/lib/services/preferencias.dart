import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Dados guardados no aparelho (o equivalente ao localStorage do site).
class Preferencias {
  Preferencias._();

  static const _chaveCarrinho = 'lavai:carrinho';
  static const _chaveUltimoPedido = 'lavai:ultimoPedido';
  static const _chaveServidor = 'lavai:servidor';

  /// Endereço da API escolhido na tela "Endereço do servidor" (nulo = usar o padrão).
  static Future<String?> lerServidor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveServidor);
  }

  static Future<void> salvarServidor(String? endereco) async {
    final prefs = await SharedPreferences.getInstance();
    if (endereco == null || endereco.isEmpty) {
      await prefs.remove(_chaveServidor);
    } else {
      await prefs.setString(_chaveServidor, endereco);
    }
  }

  static Future<List<Map<String, dynamic>>> lerCarrinho() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveCarrinho);
    if (texto == null) return [];
    try {
      return (jsonDecode(texto) as List).whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return []; // dado corrompido: começa com o carrinho vazio
    }
  }

  static Future<void> salvarCarrinho(List<Map<String, dynamic>> itens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveCarrinho, jsonEncode(itens));
  }

  static Future<String?> lerUltimoPedido() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveUltimoPedido);
  }

  static Future<void> salvarUltimoPedido(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveUltimoPedido, codigo);
  }
}
