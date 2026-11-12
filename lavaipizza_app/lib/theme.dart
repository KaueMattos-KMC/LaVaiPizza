import 'package:material_ui/material_ui.dart';

/// Cores do site (assets/css/style.css), já com o contraste revisado para acessibilidade.
class Cores {
  Cores._();

  static const laranja = Color(0xFFB35400); // --primary-color
  static const laranjaEscuro = Color(0xFF8F4300); // --primary-hover
  static const marrom = Color(0xFF3C2A21); // --dark-color
  static const cinzaFundo = Color(0xFFF4F4F4); // --grey
  static const texto = Color(0xFF333333); // --text-color
  static const textoSecundario = Color(0xFF666666);
  static const vermelho = Color(0xFFC0392B); // --btn-action (preço promocional, selo)
  static const verde = Color(0xFF1E7A34); // botões de confirmar
  static const borda = Color(0xFFEEEEEE);
  static const erroFundo = Color(0xFFFDECEA);
  static const erroTexto = Color(0xFFB3261E);
}

ThemeData temaLaVaiPizza() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.laranja,
    primary: Cores.laranja,
    onPrimary: Colors.white,
    secondary: Cores.marrom,
    surface: Colors.white,
    error: Cores.erroTexto,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Cores.marrom,
      surfaceTintColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      centerTitle: false,
    ),
    textTheme: Typography.blackMountainView.apply(bodyColor: Cores.texto, displayColor: Cores.marrom),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.laranja, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: const TextStyle(color: Cores.marrom),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Botão verde "de confirmar" do site (.btn-confirmar / .cart--finalizar).
ButtonStyle estiloBotaoConfirmar({double raio = 25}) => FilledButton.styleFrom(
      backgroundColor: Cores.verde,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFB5B5B5),
      disabledForegroundColor: Colors.white,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(raio)),
    );

/// Botão cinza secundário do site (.btn-secundario).
ButtonStyle estiloBotaoSecundario() => FilledButton.styleFrom(
      backgroundColor: Cores.cinzaFundo,
      foregroundColor: Cores.marrom,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    );
