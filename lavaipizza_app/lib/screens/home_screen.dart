import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pizza.dart';
import '../providers/carrinho_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';
import 'entregador_login_screen.dart';
import 'pizza_detalhe_sheet.dart';
import 'servidor_screen.dart';

/// Página inicial, igual ao index.html do site: banner, promoções, benefícios e cardápio.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chaveCardapio = GlobalKey();
  late Future<List<Pizza>> _cardapio;
  List<Promocao> _promocoes = const [];

  @override
  void initState() {
    super.initState();
    _carregarCardapio();
    _carregarPromocoes();
  }

  void _carregarCardapio() {
    final api = context.read<ApiService>();
    final carrinho = context.read<CarrinhoProvider>();
    setState(() {
      _cardapio = api.cardapio().then((pizzas) {
        carrinho.atualizarCardapio(pizzas); // tira do carrinho o que saiu do cardápio
        return pizzas;
      });
    });
  }

  Future<void> _carregarPromocoes() async {
    try {
      final promocoes = await context.read<ApiService>().promocoesVigentes();
      if (mounted) setState(() => _promocoes = promocoes);
    } on ApiException {
      // A faixa de promoções é opcional: sem ela o app continua funcionando.
    }
  }

  Future<void> _atualizar() async {
    _carregarCardapio();
    await Future.wait([_cardapio.then((_) {}, onError: (_) {}), _carregarPromocoes()]);
  }

  Future<void> _configurarServidor() async {
    final mudou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ServidorScreen()));
    if (mudou == true && mounted) _atualizar();
  }

  void _irParaCardapio() {
    final alvo = _chaveCardapio.currentContext;
    if (alvo != null) {
      Scrollable.ensureVisible(alvo, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraLaVaiPizza(),
      body: RefreshIndicator(
        color: Cores.laranja,
        onRefresh: _atualizar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            _Banner(aoVerCardapio: _irParaCardapio),
            if (_promocoes.isNotEmpty) _FaixaPromocoes(_promocoes),
            _Beneficios(_promocoes),
            Padding(
              key: _chaveCardapio,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Semantics(
                header: true,
                child: const Text('Nosso Cardápio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Cores.texto)),
              ),
            ),
            FutureBuilder<List<Pizza>>(
              future: _cardapio,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _Mensagem(texto: 'Carregando o cardápio...', carregando: true);
                }
                if (snap.hasError) {
                  return _Mensagem(texto: '${snap.error}', aoTentarDeNovo: _carregarCardapio);
                }
                final pizzas = snap.data!;
                if (pizzas.isEmpty) {
                  return const _Mensagem(texto: 'O cardápio está vazio no momento. Volte em instantes!');
                }
                return _GradeCardapio(pizzas);
              },
            ),
            const SizedBox(height: 40),
            _Rodape(aoConfigurarServidor: _configurarServidor),
          ]),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.aoVerCardapio});

  final VoidCallback aoVerCardapio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Cores.cinzaFundo,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(children: [
        Semantics(
          header: true,
          child: const Text(
            'Sua Pizza Favorita, Entregue Quentinha.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w800, color: Cores.marrom),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'As melhores pizzas artesanais com ingredientes selecionados e entrega ultra rápida na sua região.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Cores.textoSecundario),
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: aoVerCardapio,
          style: FilledButton.styleFrom(
            backgroundColor: Cores.marrom,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('VER CARDÁPIO'),
        ),
        const SizedBox(height: 30),
        const _PizzaFlutuante(),
      ]),
    );
  }
}

/// Pizza do banner "flutuando", como a animação float do site.
/// Quem pediu para reduzir animações no celular vê a imagem parada.
class _PizzaFlutuante extends StatefulWidget {
  const _PizzaFlutuante();

  @override
  State<_PizzaFlutuante> createState() => _PizzaFlutuanteState();
}

class _PizzaFlutuanteState extends State<_PizzaFlutuante> with SingleTickerProviderStateMixin {
  late final AnimationController _controle =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagem = ExcludeSemantics(child: Image.asset('assets/images/pizza6.png', width: 240));
    if (MediaQuery.of(context).disableAnimations) return imagem;

    return AnimatedBuilder(
      animation: _controle,
      builder: (_, filho) => Transform.translate(
        offset: Offset(0, -15 * Curves.easeInOut.transform(_controle.value)),
        child: filho,
      ),
      child: imagem,
    );
  }
}

class _FaixaPromocoes extends StatelessWidget {
  const _FaixaPromocoes(this.promocoes);

  final List<Promocao> promocoes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Promoções',
      child: Container(
        width: double.infinity,
        color: Cores.marrom,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            const Text('🎉 Promoções de hoje:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            for (final p in promocoes) Text(p.nome, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _Beneficios extends StatelessWidget {
  const _Beneficios(this.promocoes);

  final List<Promocao> promocoes;

  @override
  Widget build(BuildContext context) {
    // O texto da entrega acompanha a promoção de frete grátis cadastrada (igual ao site)
    Promocao? frete;
    for (final p in promocoes) {
      if (p.tipo == 'FRETE_GRATIS') frete = p;
    }
    final tituloEntrega = frete == null ? 'Entrega Rápida' : 'Entrega Grátis';
    final textoEntrega = frete == null
        ? 'Entrega ultra rápida na sua região.'
        : frete.valorMinimo != null
            ? 'Para pedidos acima de ${brl(frete.valorMinimo!)}.'
            : 'Em todos os pedidos.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(children: [
        _Beneficio('🚚', tituloEntrega, textoEntrega),
        const SizedBox(height: 40),
        const _Beneficio('🔥', 'Forno a Lenha', 'Sabor tradicional e inconfundível.'),
        const SizedBox(height: 40),
        const _Beneficio('🌿', 'Ingredientes', 'Tudo fresco e selecionado.'),
      ]),
    );
  }
}

class _Beneficio extends StatelessWidget {
  const _Beneficio(this.icone, this.titulo, this.texto);

  final String icone, titulo, texto;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ExcludeSemantics(child: Text(icone, style: const TextStyle(fontSize: 40))),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Cores.texto)),
      ),
      const SizedBox(height: 8),
      Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
    ]);
  }
}

class _GradeCardapio extends StatelessWidget {
  const _GradeCardapio(this.pizzas);

  final List<Pizza> pizzas;

  @override
  Widget build(BuildContext context) {
    // No celular, um cartão por linha (como o site no celular); em telas largas, mais colunas.
    return LayoutBuilder(builder: (context, limites) {
      final colunas = (limites.maxWidth / 320).floor().clamp(1, 3);
      final linhas = <Widget>[];
      for (var i = 0; i < pizzas.length; i += colunas) {
        final grupo = pizzas.skip(i).take(colunas).toList();
        linhas.add(Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var j = 0; j < colunas; j++) ...[
                if (j > 0) const SizedBox(width: 30),
                Expanded(child: j < grupo.length ? _CartaoPizza(grupo[j]) : const SizedBox()),
              ],
            ]),
          ),
        ));
      }
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: linhas));
    });
  }
}

class _CartaoPizza extends StatelessWidget {
  const _CartaoPizza(this.pizza);

  final Pizza pizza;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirDetalhePizza(context, pizza),
        child: Semantics(
          button: true,
          label: 'Escolher ${pizza.nome}',
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              SizedBox(
                width: 200,
                height: 205,
                child: Stack(alignment: Alignment.topCenter, children: [
                  PizzaImagem(pizza.imagemUrl, tamanho: 180),
                  // Botão laranja "+" sobreposto à foto
                  Positioned(
                    bottom: 0,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Cores.laranja,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 24)),
                      ),
                    ),
                  ),
                  if (pizza.promocao != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Semantics(
                        label: 'Promoção: ${pizza.promocao!.nome}',
                        excludeSemantics: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Cores.vermelho, borderRadius: BorderRadius.circular(12)),
                          child: Text(pizza.promocao!.selo,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Text(pizza.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.marrom)),
              const SizedBox(height: 5),
              PrecoTexto(pizza.menorPreco, prefixo: 'a partir de '),
              const SizedBox(height: 5),
              Text(pizza.descricao,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cores.textoSecundario)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.carregando = false, this.aoTentarDeNovo});

  final String texto;
  final bool carregando;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(children: [
          if (carregando) ...[const CircularProgressIndicator(color: Cores.laranja), const SizedBox(height: 16)],
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoSecundario, fontSize: 16)),
          if (aoTentarDeNovo != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: aoTentarDeNovo, style: estiloBotaoSecundario(), child: const Text('Tentar novamente')),
          ],
        ]),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.aoConfigurarServidor});

  final VoidCallback aoConfigurarServidor;

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: Colors.white, fontSize: 14);
    return Container(
      width: double.infinity,
      color: Cores.marrom,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      child: Column(children: [
        const Text('© 2026 Pizzaria LaVaiPizza. Todos os direitos reservados.',
            textAlign: TextAlign.center, style: estilo),
        const SizedBox(height: 12),
        const Text('Rua das Pizzas, 123 - São Paulo/SP | (11) 9999-9999', textAlign: TextAlign.center, style: estilo),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EntregadorLoginScreen())),
          style: TextButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.delivery_dining_outlined, size: 18),
          label: const Text('Área do entregador', style: TextStyle(decoration: TextDecoration.underline)),
        ),
        TextButton.icon(
          onPressed: aoConfigurarServidor,
          style: TextButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Endereço do servidor', style: TextStyle(decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }
}
