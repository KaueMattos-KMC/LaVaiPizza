import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/pizza_repository.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';

void main() => runApp(const LaVaiPizzaApp());

class LaVaiPizzaApp extends StatelessWidget {
  const LaVaiPizzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Para usar o back-end: ApiPizzaRepository('http://10.0.2.2:3000')
        Provider<PizzaRepository>(create: (_) => MockPizzaRepository()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'LaVaiPizza',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
