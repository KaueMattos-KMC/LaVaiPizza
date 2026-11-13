import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../models/pizza.dart';
import '../providers/carrinho_provider.dart';
import '../screens/acompanhar_screen.dart';
import '../screens/carrinho_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Foto da pizza. As fotos do cardápio original ("assets/images/...") vêm junto com o app;
/// as enviadas pelo admin ("/uploads/...") são baixadas da API.
class PizzaImagem extends StatelessWidget {
  const PizzaImagem(this.url, {super.key, required this.tamanho, this.redonda = true});

  final String? url;
  final double tamanho;
  final bool redonda;

  static const _padrao = 'assets/images/pizza.png';

  @override
  Widget build(BuildContext context) {
    final caminho = (url == null || url!.isEmpty) ? _padrao : url!;
    Widget erro(BuildContext _, Object _, StackTrace? _) =>
        Icon(Icons.local_pizza, size: tamanho * 0.5, color: Cores.laranja);

    final Widget imagem;
    if (caminho.startsWith('assets/')) {
      imagem = Image.asset(caminho, fit: BoxFit.cover, errorBuilder: erro);
    } else {
      final completo = caminho.startsWith('/') ? ApiService.urlDaApi(caminho) : caminho;
      imagem = Image.network(
        completo,
        fit: BoxFit.cover,
        errorBuilder: erro,
        // No navegador, a foto da API não tem cabeçalho CORS: usa a tag <img> como alternativa
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
    }

    return Container(
      width: tamanho,
      height: tamanho,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Cores.borda,
        shape: redonda ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: redonda ? null : BorderRadius.circular(16),
      ),
      child: ExcludeSemantics(child: imagem),
    );
  }
}

/// Preço com o valor antigo riscado e o promocional ao lado, quando há promoção (igual ao site).
class PrecoTexto extends StatelessWidget {
  const PrecoTexto(this.preco, {super.key, this.tamanhoFonte = 16, this.prefixo = ''});

  final PizzaPreco preco;
  final double tamanhoFonte;
  final String prefixo;

  @override
  Widget build(BuildContext context) {
    // Leitor de tela: "a partir de R$ 16,00, antes R$ 20,00"
    final rotulo = preco.emPromocao
        ? '$prefixo${brl(preco.precoPromocional!)}, antes ${brl(preco.preco)}'
        : '$prefixo${brl(preco.preco)}';

    return Semantics(
      label: rotulo.trim(),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: tamanhoFonte, fontWeight: FontWeight.bold, color: Cores.laranja),
          children: [
            if (prefixo.isNotEmpty) TextSpan(text: prefixo),
            if (preco.emPromocao) ...[
              TextSpan(
                text: brl(preco.preco),
                style: TextStyle(
                  fontSize: tamanhoFonte * 0.85,
                  fontWeight: FontWeight.normal,
                  color: Cores.textoSecundario,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: brl(preco.precoPromocional!), style: const TextStyle(color: Cores.vermelho)),
            ] else
              TextSpan(text: brl(preco.preco)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Barra superior igual ao cabeçalho do site: logo, "Meu pedido" e o carrinho com a quantidade.
class BarraLaVaiPizza extends StatelessWidget implements PreferredSizeWidget {
  const BarraLaVaiPizza({super.key, this.titulo, this.mostrarCarrinho = true, this.mostrarMeuPedido = true});

  /// Sem título, mostra o logo (tela inicial).
  final String? titulo;
  final bool mostrarCarrinho;
  final bool mostrarMeuPedido;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 6,
      title: titulo != null
          ? Text(titulo!, style: const TextStyle(fontWeight: FontWeight.bold))
          : Semantics(
              header: true,
              label: 'LaVaiPizza',
              excludeSemantics: true,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/Logo.png', height: 40),
                const SizedBox(width: 10),
                const Text('LaVaiPizza!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -1)),
              ]),
            ),
      actions: [
        if (mostrarMeuPedido)
          IconButton(
            tooltip: 'Meu pedido',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcompanharScreen())),
          ),
        if (mostrarCarrinho) const _BotaoCarrinho(),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _BotaoCarrinho extends StatelessWidget {
  const _BotaoCarrinho();

  @override
  Widget build(BuildContext context) {
    final quantidade = context.select<CarrinhoProvider, int>((c) => c.totalPizzas);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        label: 'Abrir carrinho, $quantidade pizza(s)',
        // excludeSemantics remove a ação do InkWell: o toque precisa ser repassado aqui
        onTap: () => abrirCarrinho(context),
        excludeSemantics: true,
        child: Material(
          color: Cores.cinzaFundo,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => abrirCarrinho(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$quantidade', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Text('🛒', style: TextStyle(fontSize: 18)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre o carrinho; vazio, avisa em vez de abrir (igual ao site).
void abrirCarrinho(BuildContext context) {
  if (context.read<CarrinhoProvider>().vazio) {
    avisar(context, 'Seu carrinho está vazio. Escolha uma pizza do cardápio!');
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => const CarrinhoScreen()));
}

void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
  // Leitores de tela também ouvem o aviso
  SemanticsService.sendAnnouncement(View.of(context), mensagem, TextDirection.ltr);
}

/// Caixa vermelha de erro (.checkout-erro do site).
class CaixaErro extends StatelessWidget {
  const CaixaErro(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Cores.erroFundo, borderRadius: BorderRadius.circular(8)),
        child: Text(mensagem, style: const TextStyle(color: Cores.erroTexto)),
      ),
    );
  }
}

/// Área cinza com "-  quantidade  +" (usada no detalhe da pizza e no carrinho).
class SeletorQuantidade extends StatelessWidget {
  const SeletorQuantidade({
    super.key,
    required this.quantidade,
    required this.aoDiminuir,
    required this.aoAumentar,
    required this.descricao,
    this.compacto = false,
  });

  final int quantidade;
  final VoidCallback? aoDiminuir;
  final VoidCallback? aoAumentar;
  final String descricao;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final fonte = compacto ? 14.0 : 18.0;
    return Container(
      decoration: BoxDecoration(color: Cores.borda, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Diminuir $descricao',
          onPressed: aoDiminuir,
          icon: const Icon(Icons.remove),
          color: Cores.marrom,
        ),
        Semantics(
          label: 'Quantidade $quantidade',
          excludeSemantics: true,
          child: Text('$quantidade', style: TextStyle(fontSize: fonte, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        IconButton(
          tooltip: 'Aumentar $descricao',
          onPressed: aoAumentar,
          icon: const Icon(Icons.add),
          color: Cores.marrom,
        ),
      ]),
    );
  }
}

/// Permite só letras e números, em maiúsculas (campo do código do pedido).
class MaiusculasFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final limpo = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return TextEditingValue(text: limpo, selection: TextSelection.collapsed(offset: limpo.length));
  }
}
