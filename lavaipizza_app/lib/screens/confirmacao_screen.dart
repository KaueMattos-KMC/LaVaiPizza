import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/pedido.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';
import 'acompanhar_screen.dart';

/// "Pedido confirmado!": código de acompanhamento, total e previsão de entrega.
class ConfirmacaoScreen extends StatefulWidget {
  const ConfirmacaoScreen({super.key, required this.pedido});

  final PedidoCriado pedido;

  @override
  State<ConfirmacaoScreen> createState() => _ConfirmacaoScreenState();
}

class _ConfirmacaoScreenState extends State<ConfirmacaoScreen> {
  String _textoCopiar = 'Copiar código';
  Timer? _volta;

  @override
  void dispose() {
    _volta?.cancel();
    super.dispose();
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.pedido.codigoAcompanhamento));
    if (!mounted) return;
    setState(() => _textoCopiar = 'Código copiado!');
    _volta?.cancel();
    _volta = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _textoCopiar = 'Copiar código');
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Pedido confirmado', mostrarCarrinho: false, mostrarMeuPedido: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: const Text('Pedido confirmado! 🍕',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Cores.marrom)),
              ),
              const SizedBox(height: 12),
              const Text('Guarde o código para acompanhar o seu pedido:', textAlign: TextAlign.center),
              const SizedBox(height: 6),
              // Texto comum (o SelectableText fica mudo para o leitor de tela); para copiar há o botão abaixo.
              // O código é soletrado para o leitor de tela não ler como uma palavra.
              Semantics(
                label: 'Código do pedido: ${p.codigoAcompanhamento.split('').join(' ')}',
                excludeSemantics: true,
                child: Text(
                  p.codigoAcompanhamento,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 4, color: Cores.laranja),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total de ${brl(p.total)}. Previsão de entrega: cerca de ${p.tempoEstimado} minutos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: estiloBotaoConfirmar(),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => AcompanharScreen(codigoInicial: p.codigoAcompanhamento)),
                  ),
                  child: const Text('Acompanhar pedido'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(style: estiloBotaoSecundario(), onPressed: _copiar, child: Text(_textoCopiar)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario, minimumSize: const Size(48, 48)),
                child: const Text('Fechar', style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
