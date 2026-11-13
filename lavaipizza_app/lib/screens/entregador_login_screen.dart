import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/componentes.dart';
import 'entregador_entregas_screen.dart';

/// Login do entregador (motoboy). Usa o mesmo POST /api/v1/auth/login da área administrativa
/// e só deixa entrar quem tem o cargo Entregador.
class EntregadorLoginScreen extends StatefulWidget {
  const EntregadorLoginScreen({super.key});

  @override
  State<EntregadorLoginScreen> createState() => _EntregadorLoginScreenState();
}

class _EntregadorLoginScreenState extends State<EntregadorLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _entrando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    setState(() {
      _entrando = true;
      _erro = null;
    });

    try {
      final sessao = await context.read<ApiService>().login(_email.text.trim(), _senha.text);
      if (!mounted) return;

      if (!sessao.ehEntregador) {
        setState(() => _erro = 'Esta área é só para entregadores. Gerente e pizzaiolo usam a área administrativa.');
        return;
      }

      _senha.clear();
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EntregadorEntregasScreen(sessao: sessao)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Área do entregador', mostrarCarrinho: false, mostrarMeuPedido: false),
      backgroundColor: Cores.cinzaFundo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          children: [
            const ExcludeSemantics(child: Text('🛵', textAlign: TextAlign.center, style: TextStyle(fontSize: 56))),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: const Text('Entrar como entregador',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Cores.marrom)),
            ),
            const SizedBox(height: 8),
            const Text('Use o e-mail e a senha cadastrados pela pizzaria.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Form(
                key: _form,
                child: Column(children: [
                  TextFormField(
                    controller: _email,
                    enabled: !_entrando,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'motoboy1@lavai.com',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final texto = (v ?? '').trim();
                      if (texto.isEmpty) return 'Informe o e-mail.';
                      if (!texto.contains('@') || !texto.contains('.')) return 'E-mail inválido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senha,
                    enabled: !_entrando,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                        icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    validator: (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null,
                  ),
                ]),
              ),
            ),
            if (_erro != null) ...[const SizedBox(height: 16), CaixaErro(_erro!)],
            const SizedBox(height: 20),
            FilledButton(
              style: estiloBotaoConfirmar(),
              onPressed: _entrando ? null : _entrar,
              child: Text(_entrando ? 'Entrando...' : 'Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
