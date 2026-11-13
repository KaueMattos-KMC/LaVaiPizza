import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pedido.dart';
import '../providers/carrinho_provider.dart';
import '../services/api_service.dart';
import '../services/preferencias.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/componentes.dart';
import 'confirmacao_screen.dart';

/// "Finalizar pedido": dados de entrega. As regras de validação são as mesmas do site e da API.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static final _regexTelefone = RegExp(r'^\(?\d{2}\)?\s?9?\d{4}-?\d{4}$');
  static final _regexCep = RegExp(r'^\d{5}-?\d{3}$');
  static final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _form = GlobalKey<FormState>();
  late final RascunhoCheckout _rascunho = context.read<RascunhoCheckout>();
  late final Map<String, TextEditingController> _campos = {
    for (final c in ['nome', 'telefone', 'email', 'cep', 'logradouro', 'numero', 'complemento', 'bairro', 'cidade'])
      c: TextEditingController(text: _rascunho.campos[c] ?? (c == 'cidade' ? 'São Paulo' : '')),
  };

  bool _enviando = false;
  bool _concluido = false;
  String? _erro;

  @override
  void dispose() {
    // Guarda o que foi digitado, para não perder ao voltar ao carrinho
    if (!_concluido) _campos.forEach((nome, c) => _rascunho.campos[nome] = c.text);
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opcional(String nome) {
    final v = _campos[nome]!.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    setState(() => _erro = null);
    if (!_form.currentState!.validate()) return;

    final carrinho = context.read<CarrinhoProvider>();
    final api = context.read<ApiService>();
    final navegador = Navigator.of(context);

    final cliente = DadosCliente(
      nome: _campos['nome']!.text.trim(),
      telefone: _campos['telefone']!.text.trim(),
      email: _opcional('email'),
      logradouro: _campos['logradouro']!.text.trim(),
      numero: _campos['numero']!.text.trim(),
      complemento: _opcional('complemento'),
      bairro: _campos['bairro']!.text.trim(),
      cidade: _opcional('cidade'),
      cep: _campos['cep']!.text.trim(),
    );

    setState(() => _enviando = true);
    try {
      final pedido = await api.criarPedido(cliente, carrinho.paraApi());
      await Preferencias.salvarUltimoPedido(pedido.codigoAcompanhamento);

      _concluido = true;
      carrinho.limpar();
      _rascunho.limpar();

      // Volta para a tela inicial e mostra a confirmação por cima dela
      navegador.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ConfirmacaoScreen(pedido: pedido)),
        (rota) => rota.isFirst,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<CarrinhoProvider>();
    final s = carrinho.simulacao;
    final resumo = s == null
        ? ''
        : '${carrinho.totalPizzas} pizza(s) · Total ${brl(s.total)}'
            '${s.taxaEntrega == 0 ? ' (entrega grátis)' : ' (inclui entrega de ${brl(s.taxaEntrega)})'}';

    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Finalizar pedido', mostrarCarrinho: false, mostrarMeuPedido: false),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (resumo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(resumo, style: const TextStyle(color: Cores.laranja, fontWeight: FontWeight.bold)),
                ),
              _campo('nome', 'Nome completo',
                  hints: const [AutofillHints.name],
                  maximo: 150,
                  validar: (v) => v.length < 2 ? 'Informe o nome (pelo menos 2 letras).' : null),
              _campo('telefone', 'Telefone com DDD',
                  dica: '(11) 91234-5678',
                  teclado: TextInputType.phone,
                  hints: const [AutofillHints.telephoneNumber],
                  maximo: 20,
                  validar: (v) => _regexTelefone.hasMatch(v)
                      ? null
                      : 'Informe o DDD e o número, por exemplo (11) 91234-5678.'),
              _campo('email', 'E-mail (opcional)',
                  teclado: TextInputType.emailAddress,
                  hints: const [AutofillHints.email],
                  maximo: 100,
                  obrigatorio: false,
                  validar: (v) => v.isEmpty || _regexEmail.hasMatch(v) ? null : 'E-mail inválido.'),
              _campo('cep', 'CEP',
                  dica: '00000-000',
                  teclado: TextInputType.number,
                  hints: const [AutofillHints.postalCode],
                  maximo: 9,
                  validar: (v) => _regexCep.hasMatch(v) ? null : 'Informe o CEP no formato 00000-000.'),
              _campo('logradouro', 'Rua',
                  hints: const [AutofillHints.streetAddressLine1],
                  maximo: 150,
                  validar: (v) => v.isEmpty ? 'Informe a rua.' : null),
              _campo('numero', 'Número', maximo: 10, validar: (v) => v.isEmpty ? 'Informe o número.' : null),
              _campo('complemento', 'Complemento (opcional)',
                  hints: const [AutofillHints.streetAddressLine2], maximo: 60, obrigatorio: false),
              _campo('bairro', 'Bairro', maximo: 80, validar: (v) => v.isEmpty ? 'Informe o bairro.' : null),
              _campo('cidade', 'Cidade', hints: const [AutofillHints.addressCity], maximo: 80, obrigatorio: false),
              if (_erro != null) ...[CaixaErro(_erro!), const SizedBox(height: 14)],
              const SizedBox(height: 6),
              FilledButton(
                style: estiloBotaoConfirmar(),
                onPressed: _enviando || !carrinho.prontoParaFinalizar ? null : _confirmar,
                child: Text(_enviando ? 'Enviando...' : 'Confirmar pedido'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: estiloBotaoSecundario(),
                onPressed: _enviando ? null : () => Navigator.pop(context),
                child: const Text('Voltar ao carrinho'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String nome,
    String rotulo, {
    String? dica,
    TextInputType? teclado,
    List<String>? hints,
    required int maximo,
    bool obrigatorio = true,
    String? Function(String valor)? validar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _campos[nome],
        decoration: InputDecoration(labelText: rotulo, hintText: dica, counterText: ''),
        keyboardType: teclado,
        autofillHints: hints,
        maxLength: maximo,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        textInputAction: TextInputAction.next,
        enabled: !_enviando,
        validator: (valor) {
          final v = (valor ?? '').trim();
          if (obrigatorio && v.isEmpty && validar == null) return 'Campo obrigatório.';
          return validar?.call(v);
        },
      ),
    );
  }
}
