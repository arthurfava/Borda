# Borda

Protótipo nativo para macOS de uma prateleira temporária acionada pela borda da tela.

## Estado atual — 0.9.0 beta

- Gatilhos invisíveis configuráveis (4–24 px) nas laterais escolhidas de cada monitor.
- Cada caixa com conteúdo deixa uma aba de vidro semi-escondida na posição em que foi criada.
- Área magnética invisível ao redor da aba e do card, confirmada continuamente pela posição real do cursor.
- A caixa não recolhe enquanto o cursor estiver dentro dessa área, mesmo durante a animação da janela.
- Arrastar para uma aba existente adiciona à mesma caixa; arrastar para outro ponto da lateral cria outra caixa.
- Várias caixas podem coexistir nas duas laterais e em vários monitores.
- Entrada de arquivos, pastas, imagens, links e texto.
- Cofre persistente no App Group `group.com.arthurfava.Borda`, com migração dos dados legados.
- Seleção múltipla com ⌘/⇧, arrasto em lote e ordem ajustável pelo menu contextual.
- Arrasto funciona desde o primeiro clique em toda a linha do item; a seleção visual permanece discreta.
- Quick Look com Espaço ou dois cliques, menu Compartilhar, Finder e cópia de caminhos.
- Nome, cor, fixação, fechamento e reabertura de caixas recentes.
- A cor escolhida tonaliza o vidro inteiro da caixa; títulos e itens permanecem neutros e legíveis.
- Ações locais: renomear, ZIP, redimensionar imagem e OCR orientado pelo idioma do sistema.
- Retirada automática depois de um arrasto concluído, com restauração pelo menu da barra.
- A restauração devolve o item à caixa, lateral, monitor e altura de origem.
- Captura explícita do clipboard e histórico opcional, desligado por padrão.
- Pastas observadas opcionais e atalhos globais configuráveis por conjunto de modificadores.
- Abertura automática ao iniciar a sessão do macOS, ativada por padrão e configurável nas Preferências.
- Entrada por Serviços do macOS e URLs `borda://` para o app Atalhos.
- Persistência em JSON com gravação atômica.
- Sem monitoramento silencioso do clipboard: ele só é iniciado quando ativado nas Preferências.
- `NSGlassEffectView` nativo no macOS 26; material vibrante como fallback no macOS 15–25.
- Vidro mais transparente no estilo `clear`, sem preenchimento azul ao selecionar um item.
- Expansão interrompível em 0,18 s, recolhimento em 0,14 s e conteúdo revelado só depois da geometria estabilizar.
- Ícone próprio em Liquid Glass e pacote de distribuição `.dmg`.
- DMG com janela compacta, fundo próprio, instrução de instalação e atalho visual para Aplicativos.
- Ícone refinado com “B” tridimensional de vidro soprado, inteiramente orgânico, sem trechos retos ou faces retangulares.
- Interface e landing disponíveis em inglês, português do Brasil, espanhol, chinês simplificado, japonês, alemão, francês, coreano, italiano, holandês e russo.
- Distribuição direta por DMG, com apoio opcional pelo Buy Me a Coffee.
- Privacy Manifest, App Sandbox, bookmarks de segurança e configurações separadas de assinatura.

## Site e apoio

- Site oficial planejado: `https://getborda.app`.
- Código e releases: `https://github.com/arthurfava/Borda`.
- O Borda é gratuito e não bloqueia recursos. Apoio é sempre voluntário.
- O app e a landing abrem `getborda.app/cafe` para apoio voluntário, sem bloquear qualquer recurso.

## Desenvolvimento

```sh
swift run BordaCoreCheck
./scripts/build-app.sh
./scripts/build-dmg.sh
open .build/Borda.app
```

O núcleo continua disponível por Swift Package Manager. Para gerar o projeto de distribuição após instalar o Xcode completo e o XcodeGen:

```sh
./scripts/generate-xcode-project.sh
open Borda.xcodeproj
```

O `BordaCoreCheck` valida migração, agrupamento, persistência, cópia, remoção e restauração sem depender do XCTest. A CI também compila os schemes `Borda-Direct` e `Borda-AppStore` sem assinatura.

Para a landing:

```sh
cd website
npm run build
npm run check
```

A fonte de `Extensions/BordaShare` está pronta, mas ainda não faz parte da versão 0.9. Use o item de Serviços “Guardar no Borda” ou um Atalho que abra `borda://capture`.

Para inspeção visual sem tocar nos dados reais:

```sh
TEST_ROOT=$(mktemp -d /tmp/BordaVisual.XXXXXX)
.build/Borda.app/Contents/MacOS/Borda --show --data-root "$TEST_ROOT" --demo-seed
```
