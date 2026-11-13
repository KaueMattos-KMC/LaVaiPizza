import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/entrega.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';
import 'entregador_login_screen.dart';

/// Fila do entregador logado: pedidos prontos para coleta e os que ele está levando.
/// O servidor decide o que aparece e qual botão cada pedido tem (proximoStatusPermitido).
class EntregadorEntregasScreen extends StatefulWidget {
  const EntregadorEntregasScreen({super.key, required this.sessao});

  final SessaoFuncionario sessao;

  @override
  State<EntregadorEntregasScreen> createState() => _EntregadorEntregasScreenState();
}

class _EntregadorEntregasScreenState extends State<EntregadorEntregasScreen> {
  List<Entrega>? _fila;
  String? _erro;
  bool _carregando = false;
  int? _atualizandoId; // pedido com o botão em andamento

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final fila = await context.read<ApiService>().filaDeEntregas(widget.sessao.token);
      if (mounted) setState(() => _fila = fila);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        _sair(mensagem: e.mensagem);
        return;
      }
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _avancar(Entrega pedido) async {
    final novo = pedido.proximoStatusPermitido;
    if (novo == null) return;

    setState(() => _atualizandoId = pedido.id);
    try {
      await context.read<ApiService>().avancarStatus(widget.sessao.token, pedido.id, novo);
      if (!mounted) return;
      avisar(context, novo == 'Entregue' ? 'Entrega concluída!' : 'Pedido ${pedido.codigoAcompanhamento} saiu com você.');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        _sair(mensagem: e.mensagem);
        return;
      }
      avisar(context, e.mensagem); // ex.: 409, outro entregador pegou antes
    } finally {
      if (mounted) setState(() => _atualizandoId = null);
    }
    await _carregar();
  }

  void _sair({String? mensagem}) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EntregadorLoginScreen()));
    if (mensagem != null) avisar(context, mensagem);
  }

  @override
  Widget build(BuildContext context) {
    final fila = _fila;
    final comigo = fila?.where((p) => p.status == 'Saiu para Entrega').toList() ?? const <Entrega>[];
    final paraColetar = fila?.where((p) => p.status == 'Aguardando Coleta').toList() ?? const <Entrega>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas entregas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Atualizar', icon: const Icon(Icons.refresh), onPressed: _carregando ? null : _carregar),
          IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _sair),
          const SizedBox(width: 6),
        ],
      ),
      backgroundColor: Cores.cinzaFundo,
      body: RefreshIndicator(
        color: Cores.laranja,
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Text('Olá, ${widget.sessao.nome}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Cores.marrom)),
            const SizedBox(height: 4),
            const Text('Puxe a tela para baixo para atualizar.', style: TextStyle(color: Cores.textoSecundario)),
            if (_erro != null) ...[const SizedBox(height: 16), CaixaErro(_erro!)],
            if (fila == null && _erro == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Cores.laranja)),
              ),
            if (fila != null) ...[
              _Secao('Saíram comigo', comigo.length),
              if (comigo.isEmpty) const _Vazio('Você não está com nenhum pedido no momento.'),
              for (final p in comigo) _CartaoEntrega(p, ocupado: _atualizandoId == p.id, aoAvancar: () => _avancar(p)),
              _Secao('Prontos para coleta', paraColetar.length),
              if (paraColetar.isEmpty) const _Vazio('Nenhum pedido aguardando coleta.'),
              for (final p in paraColetar)
                _CartaoEntrega(p, ocupado: _atualizandoId == p.id, aoAvancar: () => _avancar(p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo, this.quantidade);

  final String titulo;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Semantics(
        header: true,
        child: Text('$titulo ($quantidade)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.marrom)),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto, style: const TextStyle(color: Cores.textoSecundario, fontSize: 15));
}

class _CartaoEntrega extends StatelessWidget {
  const _CartaoEntrega(this.pedido, {required this.ocupado, required this.aoAvancar});

  final Entrega pedido;
  final bool ocupado;
  final VoidCallback aoAvancar;

  @override
  Widget build(BuildContext context) {
    final proximo = pedido.proximoStatusPermitido;
    final rotuloBotao = proximo == 'Entregue' ? 'Confirmar entrega' : 'Pegar pedido';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              label: 'Pedido ${pedido.codigoAcompanhamento.split('').join(' ')}',
              excludeSemantics: true,
              child: Text(pedido.codigoAcompanhamento,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: Cores.laranja)),
            ),
          ),
          Text('há ${pedido.minutosDesdeCriacao} min', style: const TextStyle(color: Cores.textoSecundario)),
        ]),
        const SizedBox(height: 10),
        Text(pedido.cliente, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        if (pedido.endereco != null) ...[const SizedBox(height: 4), Text(pedido.endereco!)],
        if (pedido.telefone != null) ...[const SizedBox(height: 4), Text('Telefone: ${pedido.telefone}')],
        const SizedBox(height: 10),
        for (final i in pedido.itens) Text('•  ${i.quantidade}× ${i.pizza} (${i.tamanho})'),
        const SizedBox(height: 10),
        Text('Total: ${brl(pedido.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (proximo != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: estiloBotaoConfirmar(),
              onPressed: ocupado ? null : aoAvancar,
              child: Text(ocupado ? 'Enviando...' : rotuloBotao),
            ),
          ),
        ],
      ]),
    );
  }
}
