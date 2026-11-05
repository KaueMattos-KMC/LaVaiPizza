import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/pizza_repository.dart';
import '../models/pizza.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import 'cart_screen.dart';
import 'pizza_detail_sheet.dart';

const siteImg = 'https://willianduartte.github.io/PIM-3-Front-End/assets/images';

Widget pizzaImage(String url, {double? size, BoxFit fit = BoxFit.cover}) {
  return Image.network(
    url,
    width: size,
    height: size,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      width: size,
      height: size,
      color: Colors.orange.shade50,
      child: const Icon(Icons.local_pizza, size: 40, color: Colors.orange),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Pizza>> _future;
  final _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _future = context.read<PizzaRepository>().buscarPizzas();
  }

  void _irParaMenu() => Scrollable.ensureVisible(
        _menuKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.network('$siteImg/logo.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.local_pizza)),
          const SizedBox(width: 8),
          const Text('LaVaiPizza!', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${cart.quantidade}'),
              isLabelVisible: cart.quantidade > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: cs.primaryContainer.withAlpha(90),
            child: Column(children: [
              Text('Sua Pizza Favorita, Entregue Quentinha.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('As melhores pizzas artesanais com ingredientes selecionados e entrega ultra rápida na sua região.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              pizzaImage('$siteImg/pizza6.png', size: 200, fit: BoxFit.contain),
              const SizedBox(height: 16),
              FilledButton(onPressed: _irParaMenu, child: const Text('VER CARDÁPIO')),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              _Destaque('🚚', 'Entrega Grátis', 'Para pedidos acima de R\$ 50,00.'),
              _Destaque('🔥', 'Forno a Lenha', 'Sabor tradicional e inconfundível.'),
              _Destaque('🌿', 'Ingredientes', 'Tudo fresco e selecionado.'),
            ]),
          ),
          Padding(
            key: _menuKey,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Mais Pedidas da Semana',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          FutureBuilder<List<Pizza>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text('Não foi possível carregar o cardápio.\n${snap.error}', textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => setState(() => _future = context.read<PizzaRepository>().buscarPizzas()),
                      child: const Text('Tentar de novo'),
                    ),
                  ]),
                );
              }
              final pizzas = snap.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: pizzas.length,
                itemBuilder: (_, i) => _PizzaCard(pizza: pizzas[i]),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                '© 2026 Pizzaria LaVaiPizza.\nRua das Pizzas, 123 - São Paulo/SP | (11) 9999-9999',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Destaque extends StatelessWidget {
  final String emoji, titulo, texto;
  const _Destaque(this.emoji, this.titulo, this.texto);
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(texto),
      );
}

class _PizzaCard extends StatelessWidget {
  final Pizza pizza;
  const _PizzaCard({required this.pizza});
  @override
  Widget build(BuildContext context) {
    final menor = pizza.precos.values.reduce((a, b) => a < b ? a : b);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => PizzaDetailSheet(pizza: pizza),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SizedBox(width: double.infinity, child: pizzaImage(pizza.imagemUrl))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pizza.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('a partir de ${brl(menor)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            ]),
          ),
        ]),
      ),
    );
  }
}
