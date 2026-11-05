# LaVaiPizza App (Flutter)

App mobile baseado no site https://willianduartte.github.io/PIM-3-Front-End/

## Como rodar
1. Instale o Flutter (https://docs.flutter.dev/get-started/install).
2. Dentro desta pasta, gere as pastas de plataforma (android/ios):
   `flutter create .`
3. `flutter pub get`
4. `flutter run`

## Ligar ao back-end
Em `lib/main.dart`, troque `MockPizzaRepository()` por
`ApiPizzaRepository('http://10.0.2.2:3000')` (10.0.2.2 = localhost no emulador Android)
e ajuste o endpoint e `Pizza.fromJson` conforme o seu back-end.
