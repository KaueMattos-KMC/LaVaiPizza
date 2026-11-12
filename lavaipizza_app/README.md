# LaVaiPizza - App mobile (Flutter)

App do cliente da pizzaria, com as mesmas telas e regras do site (`LaVaiPizzaFront`):

| Tela | O que faz |
|---|---|
| Início | Banner, faixa de promoções vigentes, benefícios e cardápio vindo da API (selo de desconto e preço riscado) |
| Detalhes da pizza | Escolha do tamanho (Pequena, Média, Grande) e da quantidade |
| Carrinho | Itens salvos no aparelho; subtotal, descontos, entrega e total calculados pelo servidor |
| Finalizar pedido | Dados de entrega com validação (mesmas regras da API) |
| Pedido confirmado | Código de acompanhamento e previsão de entrega |
| Meu pedido | Linha do tempo do pedido, atualizada a cada 5 segundos até a entrega |

A área administrativa (equipe da pizzaria) fica só no back-end, em `/admin`.

## Como o app fala com a API

O endereço é escolhido na hora de compilar ou rodar (`lib/config.dart`):

| Onde roda | Endereço padrão |
|---|---|
| Navegador (`flutter run -d chrome`) | `http://localhost:5166` |
| Emulador Android | `http://10.0.2.2:5166` (o computador visto de dentro do emulador) |
| Celular de verdade | informe o IP do computador: `--dart-define=API_URL=http://192.168.x.x:5166` |

Rotas usadas (as mesmas do site): `GET /api/v1/pizzas`, `GET /api/v1/promocoes/vigentes`,
`POST /api/v1/pedidos/simular`, `POST /api/v1/pedidos` e `GET /api/v1/pedidos/acompanhar/{codigo}`.

## Rodar

```powershell
flutter pub get
flutter run -d chrome                     # no navegador
flutter run                               # no emulador ou celular conectado por USB
```

## Gerar o APK para instalar no celular

```powershell
flutter build apk --release --dart-define=API_URL=http://SEU-IP:5166
# arquivo: build\app\outputs\flutter-apk\app-release.apk
```

Para o celular alcançar a API rodando no computador:

1. Celular e computador na **mesma rede Wi-Fi**.
2. A API precisa aceitar conexões da rede (por padrão ela só escuta o próprio computador):
   ```powershell
   cd LaVaiPizzaBack\src\laVaiPizza.Api
   dotnet run --urls http://0.0.0.0:5166
   ```
3. Liberar a porta no firewall do Windows (uma vez, como administrador):
   ```powershell
   New-NetFirewallRule -DisplayName "LaVaiPizza API" -Direction Inbound -Protocol TCP -LocalPort 5166 -Action Allow -Profile Private
   ```

## Estrutura

```
lib/
  main.dart              inicia o app e carrega o carrinho salvo
  config.dart            endereço da API e constantes
  theme.dart             cores e botões do site
  models/                pizza, promoção, pedido, acompanhamento (espelham o JSON da API)
  services/              ApiService (HTTP + mensagens de erro) e Preferencias (dados no aparelho)
  providers/             CarrinhoProvider (estado do carrinho, recalcula no servidor)
  screens/               uma tela por arquivo
  widgets/componentes.dart   peças reaproveitadas: foto, preço riscado, barra superior, quantidade
```

Decisões:
- **Os valores nunca são calculados no app**: o carrinho chama `POST /pedidos/simular` a cada mudança
  (com uma espera de 250 ms para juntar toques seguidos), e o pedido é recalculado pela API ao ser criado.
- **Provider** para o estado, **http** para a API e **shared_preferences** para guardar o carrinho e o
  último pedido (os mesmos pacotes vistos em aula).
- As fotos do cardápio original vêm dentro do app (`assets/images`); fotos enviadas pelo admin são
  baixadas da API (`/uploads/...`).
- Acessibilidade: rótulos para leitor de tela (TalkBack), botões com área de toque de pelo menos 48 px,
  anúncio das mudanças de status e respeito à opção "remover animações" do Android.
