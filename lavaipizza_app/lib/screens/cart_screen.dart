import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import 'home_screen.dart' show pizzaImage;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Suas Pizzas')),
      body: cart.itens.isEmpty
          ? const Center(child: Text('Seu carrinho está vazio 🍕'))
          : Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.itens.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final it = cart.itens[i];
                    return Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: pizzaImage(it.pizza.imagemUrl, size: 64)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.pizza.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(it.tamanho.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(brl(it.total)),
                        ]),
                      ),
                      IconButton(onPressed: () => cart.alterarQtd(it, -1), icon: const Icon(Icons.remove_circle_outline)),
                      Text('${it.qtd}'),
                      IconButton(onPressed: () => cart.alterarQtd(it, 1), icon: const Icon(Icons.add_circle_outline)),
                    ]);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SafeArea(
                  top: false,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _Linha('Subtotal', brl(cart.subtotal)),
                    _Linha('Desconto (-10%)', '- ${brl(cart.desconto)}'),
                    const Divider(),
                    _Linha('Total', brl(cart.total), destaque: true),
                    const SizedBox(height: 4),
                    Text(
                      cart.freteGratis
                          ? '🚚 Entrega grátis!'
                          : 'Faltam ${brl(CartProvider.freteGratisAcima - cart.subtotal)} para entrega grátis',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            // TODO: enviar o pedido ao back-end (ex.: POST /pedidos).
                            final total = brl(cart.total);
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Pedido realizado! 🍕'),
                                content: Text('Total: $total'),
                                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                              ),
                            );
                            cart.limpar();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Finalizar a compra'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
    );
  }
}

class _Linha extends StatelessWidget {
  final String a, b;
  final bool destaque;
  const _Linha(this.a, this.b, {this.destaque = false});
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(fontWeight: destaque ? FontWeight.bold : FontWeight.normal, fontSize: destaque ? 18 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: s), Text(b, style: s)]),
    );
  }
}
