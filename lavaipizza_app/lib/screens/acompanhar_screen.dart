import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../services/preferencias.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';

/// "Acompanhe seu pedido" (acompanhar.html): consulta a API a cada 5 segundos até a entrega.
class AcompanharScreen extends StatefulWidget {
  const AcompanharScreen({super.key, this.codigoInicial});

  /// Vindo da confirmação do pedido, já abre buscando este código.
  final String? codigoInicial;

  @override
  State<AcompanharScreen> createState() => _AcompanharScreenState();
}

class _AcompanharScreenState extends State<AcompanharScreen> with WidgetsBindingObserver {
  static const _esperaAoLimitar = Duration(seconds: 20); // resposta 429: espera mais

  final _form = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  String? _codigoAtual;
  Acompanhamento? _pedido;
  String? _erro;
  DateTime? _atualizadoEm;
  Timer? _timer;
  bool _consultando = false;
  bool _emPrimeiroPlano = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.codigoInicial != null) {
      _buscar(widget.codigoInicial!);
    } else {
      // Sugere o último pedido feito neste aparelho
      Preferencias.lerUltimoPedido().then((ultimo) {
        if (ultimo != null && mounted && _codigo.text.isEmpty) _codigo.text = ultimo;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _codigo.dispose();
    super.dispose();
  }

  /// Com o app em segundo plano não precisa consultar: pausa e retoma ao voltar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    _emPrimeiroPlano = estado == AppLifecycleState.resumed;
    if (!_emPrimeiroPlano) {
      _timer?.cancel();
    } else if (_codigoAtual != null && !(_pedido?.foiEntregue ?? false)) {
      _consultar();
    }
  }

  void _buscar(String codigo) {
    _timer?.cancel();
    final limpo = codigo.trim().toUpperCase();
    setState(() {
      _codigoAtual = limpo;
      _codigo.text = limpo;
      _pedido = null;
      _erro = null;
    });
    _consultar();
  }

  Future<void> _consultar() async {
    final codigo = _codigoAtual;
    if (codigo == null || _consultando) return;
    _consultando = true;

    Duration? proxima = AppConfig.intervaloAcompanhamento;
    try {
      final pedido = await context.read<ApiService>().acompanhar(codigo);
      if (!mounted || codigo != _codigoAtual) return;
      setState(() {
        _pedido = pedido;
        _erro = null;
        _atualizadoEm = DateTime.now();
      });
      if (pedido.foiEntregue) proxima = null; // fim: não precisa consultar mais
    } on ApiException catch (e) {
      if (!mounted || codigo != _codigoAtual) return;
      setState(() {
        if (e.status == 404) {
          _pedido = null;
          _erro = 'Pedido não encontrado. Confira o código e tente de novo.';
          proxima = null;
        } else if (e.status == 429) {
          _erro = e.mensagem;
          proxima = _esperaAoLimitar;
        } else {
          // Sem conexão ou erro do servidor: mantém o que já está na tela e tenta de novo
          _erro = '${e.mensagem} Tentando novamente...';
        }
      });
    } finally {
      _consultando = false;
    }

    _timer?.cancel();
    if (proxima != null && _emPrimeiroPlano && mounted) _timer = Timer(proxima!, _consultar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Meu pedido', mostrarMeuPedido: false),
      backgroundColor: Cores.cinzaFundo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          children: [
            Semantics(
              header: true,
              child: const Text('Acompanhe seu pedido',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Cores.marrom)),
            ),
            const SizedBox(height: 8),
            const Text('Digite o código que você recebeu ao finalizar a compra.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: TextFormField(
                controller: _codigo,
                decoration: const InputDecoration(
                  labelText: 'Código do pedido',
                  hintText: 'Ex.: LV7K2P9Q',
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                style: const TextStyle(letterSpacing: 2),
                maxLength: 12,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                inputFormatters: [MaiusculasFormatter()],
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _enviar(),
                validator: (v) => (v ?? '').trim().length < 4 ? 'Informe o código (letras e números).' : null,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(style: estiloBotaoConfirmar(), onPressed: _enviar, child: const Text('Buscar')),
            if (_erro != null) ...[const SizedBox(height: 16), CaixaErro(_erro!)],
            if (_pedido == null && _codigoAtual != null && _erro == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Cores.laranja)),
              ),
            if (_pedido != null) ...[const SizedBox(height: 24), _CartaoPedido(_pedido!, _atualizadoEm)],
          ],
        ),
      ),
    );
  }

  void _enviar() {
    FocusScope.of(context).unfocus();
    if (_form.currentState!.validate()) _buscar(_codigo.text);
  }
}

class _CartaoPedido extends StatelessWidget {
  const _CartaoPedido(this.pedido, this.atualizadoEm);

  final Acompanhamento pedido;
  final DateTime? atualizadoEm;

  @override
  Widget build(BuildContext context) {
    final entregue = pedido.foiEntregue;
    final previsao = entregue
        ? 'Pedido entregue. Bom apetite! 🍕'
        : 'Previsão de entrega: cerca de ${pedido.tempoEstimado ?? '--'} minutos após o pedido '
            '(feito às ${hora(pedido.dataHora)}).';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('PEDIDO', style: TextStyle(fontSize: 12, color: Cores.textoSecundario)),
              Semantics(
                label: 'Código do pedido: ${pedido.codigoAcompanhamento.split('').join(' ')}',
                excludeSemantics: true,
                child: Text(pedido.codigoAcompanhamento,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 3, color: Cores.laranja)),
              ),
            ]),
            // Muda de status sozinho: o leitor de tela anuncia a mudança
            Semantics(
              liveRegion: true,
              label: 'Status: ${pedido.status}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: entregue ? Cores.verde : Cores.laranja,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(pedido.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(previsao, style: const TextStyle(color: Color(0xFF555555))),
        const SizedBox(height: 22),
        _LinhaDoTempo(pedido.etapas),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: const Text('Itens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Cores.marrom)),
        ),
        const SizedBox(height: 8),
        for (final i in pedido.itens)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text('•  ${i.quantidade}× ${i.pizza} (${i.tamanho})'),
          ),
        const Divider(height: 32, color: Cores.borda),
        Row(children: [
          Expanded(child: Text('${pedido.cliente} · ${pedido.bairro}', style: const TextStyle(fontSize: 18))),
          Text(brl(pedido.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        if (!entregue && atualizadoEm != null) ...[
          const SizedBox(height: 12),
          Text('Atualizado às ${horaComSegundos(atualizadoEm!)} · esta tela atualiza sozinha.',
              style: const TextStyle(fontSize: 12, color: Cores.textoSecundario)),
        ],
      ]),
    );
  }
}

/// Linha do tempo das etapas: concluídas em verde, a atual em laranja.
class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo(this.etapas);

  final List<Etapa> etapas;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < etapas.length; i++) _linha(etapas[i], ultima: i == etapas.length - 1),
    ]);
  }

  Widget _linha(Etapa e, {required bool ultima}) {
    // A etapa final já concluída fica verde (a "atual" laranja vale só enquanto está em andamento)
    final corBolinha = e.concluida
        ? Cores.verde
        : e.atual
            ? Cores.laranja
            : Colors.white;
    final corBorda = e.concluida
        ? Cores.verde
        : e.atual
            ? Cores.laranja
            : const Color(0xFF767676);
    final destaque = e.atual || e.concluida;
    final situacao = e.concluida ? 'concluída' : (e.atual ? 'etapa atual' : 'pendente');

    return Semantics(
      label: '${e.status}, $situacao${e.horario != null ? ', às ${hora(e.horario!)}' : ''}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 24,
            child: Column(children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: corBolinha,
                  shape: BoxShape.circle,
                  border: Border.all(color: corBorda, width: 3),
                ),
              ),
              if (!ultima)
                Expanded(child: Container(width: 2, color: e.concluida ? Cores.verde : const Color(0xFFDDDDDD))),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultima ? 0 : 22),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.status,
                    style: TextStyle(
                      fontWeight: e.atual ? FontWeight.bold : FontWeight.normal,
                      color: destaque ? Cores.marrom : Cores.textoSecundario,
                    )),
                if (e.horario != null)
                  Text(hora(e.horario!), style: const TextStyle(fontSize: 14, color: Cores.texto)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
