import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/api_service.dart';
import '../services/preferencias.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

/// "Endereço do servidor": troca o endereço da API sem precisar gerar o app de novo
/// (por exemplo, quando o computador muda de rede e ganha outro IP).
class ServidorScreen extends StatefulWidget {
  const ServidorScreen({super.key});

  @override
  State<ServidorScreen> createState() => _ServidorScreenState();
}

class _ServidorScreenState extends State<ServidorScreen> {
  late final TextEditingController _campo = TextEditingController(text: AppConfig.apiUrl);
  bool _testando = false;
  bool? _resultado;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _testar() async {
    final endereco = AppConfig.normalizar(_campo.text);
    if (endereco.isEmpty) return;
    setState(() {
      _testando = true;
      _resultado = null;
      _campo.text = endereco;
    });
    final ok = await context.read<ApiService>().testarServidor(endereco);
    if (mounted) setState(() { _testando = false; _resultado = ok; });
  }

  Future<void> _salvar() async {
    final endereco = AppConfig.normalizar(_campo.text);
    if (endereco.isEmpty) return;
    final padrao = endereco == AppConfig.apiPadrao;
    await Preferencias.salvarServidor(padrao ? null : endereco);
    AppConfig.enderecoSalvo = padrao ? null : endereco;
    if (!mounted) return;
    avisar(context, 'Endereço salvo. O cardápio será recarregado.');
    Navigator.pop(context, true);
  }

  Future<void> _restaurar() async {
    await Preferencias.salvarServidor(null);
    AppConfig.enderecoSalvo = null;
    if (!mounted) return;
    setState(() {
      _campo.text = AppConfig.apiPadrao;
      _resultado = null;
    });
    avisar(context, 'Voltou para o endereço padrão.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraLaVaiPizza(titulo: 'Endereço do servidor', mostrarCarrinho: false, mostrarMeuPedido: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Endereço da API (o computador onde o back-end está rodando). '
              'No celular, use o IP do computador na mesma rede Wi-Fi, por exemplo 192.168.43.10:5166.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _campo,
              decoration: const InputDecoration(labelText: 'Endereço da API', hintText: 'http://192.168.0.10:5166'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enabled: !_testando,
              onSubmitted: (_) => _testar(),
            ),
            const SizedBox(height: 8),
            Text('Padrão deste app: ${AppConfig.apiPadrao}',
                style: const TextStyle(fontSize: 12, color: Cores.textoSecundario)),
            const SizedBox(height: 16),
            if (_resultado != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _resultado! ? const Color(0xFFE6F4EA) : Cores.erroFundo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _resultado!
                        ? 'Conectado! A API respondeu neste endereço.'
                        : 'Não foi possível conectar. Confira o IP, se a API está rodando com o perfil "celular" '
                            'e se o celular e o computador estão na mesma rede.',
                    style: TextStyle(color: _resultado! ? Cores.verde : Cores.erroTexto),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              style: estiloBotaoSecundario(),
              onPressed: _testando ? null : _testar,
              child: Text(_testando ? 'Testando...' : 'Testar conexão'),
            ),
            const SizedBox(height: 12),
            FilledButton(style: estiloBotaoConfirmar(), onPressed: _testando ? null : _salvar, child: const Text('Salvar')),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _testando ? null : _restaurar,
              style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario, minimumSize: const Size(48, 48)),
              child: const Text('Restaurar o padrão', style: TextStyle(decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}
