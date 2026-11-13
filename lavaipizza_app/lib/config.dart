import 'package:flutter/foundation.dart';

/// Configuração do app.
///
/// Endereço da API, em ordem de prioridade:
///   1. o que o usuário salvou na tela "Endereço do servidor" (fica guardado no aparelho);
///   2. o informado ao compilar: flutter build apk --dart-define=API_URL=http://192.168.0.10:5166
///   3. o padrão: localhost no navegador e 10.0.2.2 no emulador Android.
class AppConfig {
  AppConfig._();

  static const String _apiDefinida = String.fromEnvironment('API_URL');

  /// Endereço salvo na tela de configuração (carregado ao abrir o app).
  static String? enderecoSalvo;

  static String get apiUrl => _limpar(enderecoSalvo?.isNotEmpty == true ? enderecoSalvo! : apiPadrao);

  /// Endereço usado quando nada foi salvo no aparelho.
  static String get apiPadrao {
    if (_apiDefinida.isNotEmpty) return _limpar(_apiDefinida);

    // No navegador o computador é o próprio "localhost".
    if (kIsWeb) return 'http://localhost:5166';

    // No emulador Android, 10.0.2.2 é o endereço do computador que roda o emulador.
    return 'http://10.0.2.2:5166';
  }

  /// Aceita "192.168.0.10:5166", "192.168.0.10" ou "http://192.168.0.10:5166/".
  static String normalizar(String texto) {
    var t = texto.trim();
    if (t.isEmpty) return t;
    if (!t.startsWith('http://') && !t.startsWith('https://')) t = 'http://$t';
    final uri = Uri.tryParse(t);
    if (uri != null && uri.hasAuthority && !uri.hasPort && uri.scheme == 'http') {
      t = '${uri.scheme}://${uri.host}:5166';
    }
    return _limpar(t);
  }

  static String _limpar(String url) => url.replaceAll(RegExp(r'/+$'), '');

  /// Intervalo em que a tela "Meu pedido" consulta o andamento (igual ao site).
  static const Duration intervaloAcompanhamento = Duration(seconds: 5);

  /// Limite de unidades por item do carrinho (o servidor aceita até 20).
  static const int maximoPorItem = 20;
}
