import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pizza.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import 'home_screen.dart' show pizzaImage;

class PizzaDetailSheet extends StatefulWidget {
  final Pizza pizza;
  const PizzaDetailSheet({super.key, required this.pizza});
  @override
  State<PizzaDetailSheet> createState() => _PizzaDetailSheetState();
}

class _PizzaDetailSheetState extends State<PizzaDetailSheet> {
  Tamanho _tamanho = Tamanho.medio;
  int _qtd = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.pizza;
    final preco = p.precos[_tamanho]! * _qtd;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: pizzaImage(p.imagemUrl, size: 180)),
          ),
          const SizedBox(height: 12),
          Text(p.nome, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          if (p.descricao.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(p.descricao)),
          const SizedBox(height: 16),
          const Text('Tamanho', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<Tamanho>(
            showSelectedIcon: false,
            segments: [
              for (final t in Tamanho.values)
                ButtonSegment(
                  value: t,
                  label: Text('${t.label}\n${brl(p.precos[t]!)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ),
            ],
            selected: {_tamanho},
            onSelectionChanged: (s) => setState(() => _tamanho = s.first),
          ),
          const SizedBox(height: 16),
          Row(children: [
            IconButton.outlined(onPressed: _qtd > 1 ? () => setState(() => _qtd--) : null, icon: const Icon(Icons.remove)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_qtd', style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton.outlined(onPressed: () => setState(() => _qtd++), icon: const Icon(Icons.add)),
            const Spacer(),
            Text(brl(preco), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  context.read<CartProvider>().adicionar(p, _tamanho, _qtd);
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  messenger.showSnackBar(SnackBar(content: Text('${p.nome} adicionada ao carrinho')));
                },
                child: const Text('Adicionar ao carrinho'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
