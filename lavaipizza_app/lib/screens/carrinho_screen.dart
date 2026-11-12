import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/pizza.dart';
import '../providers/carrinho_provider.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';
import 'checkout_screen.dart';

/// "Suas Pizzas": itens, valores calculados pelo servidor e o botão de finalizar.
class CarrinhoScreen extends StatelessWidget {
  const CarrinhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<CarrinhoProvider>();

    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Suas Pizzas', mostrarCarrinho: false),
      body: carrinho.vazio
          ? _CarrinhoVazio()
          : Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  itemCount: carrinho.itens.length,
                  separatorBuilder: (_, _) => const Divider(color: Cores.borda, height: 1),
                  itemBuilder: (_, i) => _LinhaItem(carrinho.itens[i]),
                ),
              ),
              const _Resumo(),
            ]),
    );
  }
}

class _CarrinhoVazio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ExcludeSemantics(child: Text('🍕', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 12),
          const Text('Seu carrinho está vazio.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: estiloBotaoSecundario(),
            child: const Text('Ver cardápio'),
          ),
        ]),
      ),
    );
  }
}

class _LinhaItem extends StatelessWidget {
  const _LinhaItem(this.item);

  final ItemCarrinho item;

  @override
  Widget build(BuildContext context) {
    final carrinho = context.read<CarrinhoProvider>();
    final pizza = carrinho.pizzaDe(item.pizzaId);
    final calculado = context.watch<CarrinhoProvider>().simulacao?.itemDe(item.pizzaId, item.tamanho);
    final nome = pizza?.nome ?? 'Pizza';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(children: [
        PizzaImagem(pizza?.imagemUrl, tamanho: 50),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$nome (${Tamanhos.sigla(item.tamanho)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Cores.marrom)),
            if (calculado != null)
              Text(brl(calculado.totalItem), style: const TextStyle(fontSize: 13, color: Cores.textoSecundario)),
          ]),
        ),
        SeletorQuantidade(
          compacto: true,
          quantidade: item.quantidade,
          descricao: '$nome ${item.tamanho}',
          aoDiminuir: () => carrinho.diminuir(item),
          aoAumentar: item.quantidade < AppConfig.maximoPorItem ? () => carrinho.aumentar(item) : null,
        ),
      ]),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo();

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<CarrinhoProvider>();
    final s = carrinho.simulacao;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(top: BorderSide(color: Cores.borda)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: AnimatedOpacity(
          opacity: carrinho.calculando ? 0.6 : 1,
          duration: const Duration(milliseconds: 150),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Linha('Subtotal', s == null ? 'R\$ --' : brl(s.subtotal)),
            if (s != null && s.desconto > 0) ...[
              _Linha('Desconto', '- ${brl(s.desconto)}'),
              for (final p in s.promocoes)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${p.nome}: -${brl(p.desconto)}',
                      style: const TextStyle(fontSize: 12, color: Cores.verde)),
                ),
            ],
            _Linha('Entrega', s == null ? 'R\$ --' : (s.taxaEntrega == 0 ? 'Grátis' : brl(s.taxaEntrega))),
            const Divider(color: Color(0xFFDDDDDD), thickness: 2, height: 20),
            _Linha('Total', s == null ? 'R\$ --' : brl(s.total), destaque: true),
            if (carrinho.erro != null) ...[const SizedBox(height: 10), CaixaErro(carrinho.erro!)],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: estiloBotaoConfirmar(raio: 30),
                onPressed: carrinho.prontoParaFinalizar
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()))
                    : null,
                child: Text(carrinho.calculando ? 'Calculando...' : 'Finalizar a compra'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor, {this.destaque = false});

  final String rotulo, valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final estilo = destaque
        ? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Cores.laranja)
        : const TextStyle(fontSize: 16, color: Cores.marrom);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MergeSemantics(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(rotulo, style: estilo),
          Text(valor, style: estilo),
        ]),
      ),
    );
  }
}
