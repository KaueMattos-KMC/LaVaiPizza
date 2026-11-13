import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/pizza.dart';
import '../providers/carrinho_provider.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

/// Abre a janela de detalhes da pizza (o "modal" do site). Ao adicionar, abre o carrinho.
Future<void> abrirDetalhePizza(BuildContext context, Pizza pizza) async {
  final adicionou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
    builder: (_) => PizzaDetalheSheet(pizza: pizza),
  );
  if (adicionou == true && context.mounted) abrirCarrinho(context);
}

class PizzaDetalheSheet extends StatefulWidget {
  const PizzaDetalheSheet({super.key, required this.pizza});

  final Pizza pizza;

  @override
  State<PizzaDetalheSheet> createState() => _PizzaDetalheSheetState();
}

class _PizzaDetalheSheetState extends State<PizzaDetalheSheet> {
  late String _tamanho;
  int _quantidade = 1;

  @override
  void initState() {
    super.initState();
    // Começa na Grande, como o site (ou no maior tamanho disponível)
    _tamanho = widget.pizza.precoDe(Tamanhos.grande) != null ? Tamanhos.grande : widget.pizza.precos.last.tamanho;
  }

  @override
  Widget build(BuildContext context) {
    final pizza = widget.pizza;
    final preco = pizza.precoDe(_tamanho)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PizzaImagem(pizza.imagemUrl, tamanho: 160),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(pizza.nome,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Cores.marrom)),
          ),
          const SizedBox(height: 10),
          Text(pizza.descricao,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Cores.textoSecundario)),
          const _Setor('Tamanho'),
          _SeletorTamanho(
            pizza: pizza,
            selecionado: _tamanho,
            aoEscolher: (t) => setState(() => _tamanho = t),
          ),
          const _Setor('Preço'),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 30,
            runSpacing: 12,
            children: [
              PrecoTexto(preco, tamanhoFonte: 28),
              SeletorQuantidade(
                quantidade: _quantidade,
                descricao: 'quantidade',
                aoDiminuir: _quantidade > 1 ? () => setState(() => _quantidade--) : null,
                aoAumentar: _quantidade < AppConfig.maximoPorItem ? () => setState(() => _quantidade++) : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: estiloBotaoConfirmar(),
              onPressed: () {
                context.read<CarrinhoProvider>().adicionar(pizza, _tamanho, _quantidade);
                Navigator.pop(context, true);
              },
              child: const Text('Adicionar ao carrinho'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario, minimumSize: const Size(48, 48)),
            child: const Text('Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    );
  }
}

/// Título cinza em maiúsculas (.pizzaInfo--sector).
class _Setor extends StatelessWidget {
  const _Setor(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(texto.toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Color(0xFF767676), letterSpacing: 0.5)),
    );
  }
}

/// Os três botões de tamanho lado a lado, com o selecionado em laranja.
class _SeletorTamanho extends StatelessWidget {
  const _SeletorTamanho({required this.pizza, required this.selecionado, required this.aoEscolher});

  final Pizza pizza;
  final String selecionado;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final disponiveis = Tamanhos.todos.where((t) => pizza.precoDe(t) != null).toList();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Cores.borda, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        for (final t in disponiveis)
          Expanded(
            child: Semantics(
              button: true,
              selected: t == selecionado,
              label: '${Tamanhos.rotulo(t)}, ${Tamanhos.gramas(t)}',
              // excludeSemantics remove a ação do InkWell: o toque precisa ser repassado aqui
              onTap: () => aoEscolher(t),
              excludeSemantics: true,
              child: Material(
                color: t == selecionado ? Cores.laranja : Colors.transparent,
                child: InkWell(
                  onTap: () => aoEscolher(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(children: [
                      Text(Tamanhos.rotulo(t),
                          style: TextStyle(fontSize: 13, color: t == selecionado ? Colors.white : Cores.texto)),
                      Text(Tamanhos.gramas(t),
                          style: TextStyle(fontSize: 13, color: t == selecionado ? Colors.white : Cores.texto)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
