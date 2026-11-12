import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/carrinho_provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/preferencias.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Endereço da API escolhido no aparelho (tela "Endereço do servidor"), se houver
  AppConfig.enderecoSalvo = await Preferencias.lerServidor();

  final api = ApiService();
  final carrinho = CarrinhoProvider(api);
  await carrinho.carregar(); // carrinho salvo no aparelho

  runApp(LaVaiPizzaApp(api: api, carrinho: carrinho));
}

class LaVaiPizzaApp extends StatelessWidget {
  const LaVaiPizzaApp({super.key, required this.api, required this.carrinho});

  final ApiService api;
  final CarrinhoProvider carrinho;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<CarrinhoProvider>.value(value: carrinho),
        Provider<RascunhoCheckout>(create: (_) => RascunhoCheckout()),
      ],
      child: MaterialApp(
        title: 'LaVaiPizza',
        debugShowCheckedModeBanner: false,
        theme: temaLaVaiPizza(),
        // Textos dos componentes prontos (ex.: botão "Voltar") e do leitor de tela em português
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
