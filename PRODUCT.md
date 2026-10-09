# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Pessoas que trabalham no Mac e precisam transportar arquivos, pastas, imagens, links e trechos de texto entre aplicativos sem interromper o fluxo para organizar janelas ou criar pastas temporárias.

## Product Purpose

Borda transforma as laterais dos monitores em prateleiras temporárias. O usuário arrasta um conteúdo até a borda, guarda-o numa caixa e depois o arrasta dessa caixa para qualquer outro aplicativo. Sucesso significa esse transporte exigir poucos movimentos, continuar compreensível quando há vários grupos e nunca alterar o original.

## Positioning

Cada caixa ocupa uma posição espacial persistente na borda: vazia, a lateral é invisível; com conteúdo, uma pequena aba indica exatamente onde aquele grupo está e se expande sob o ponteiro.

## Operating Context

- Aplicativo nativo de barra de menus no macOS.
- Uso com um ou vários monitores e em todos os Spaces.
- Entrada por arrastar e soltar ou captura explícita do clipboard.
- Saída por arrastar o item para outro aplicativo.
- Conteúdo armazenado em `~/Library/Application Support/Borda`.

## Capabilities and Constraints

- Suporta arquivos, pastas, imagens, links, texto simples e texto rico.
- Permite várias caixas independentes e vários itens na mesma caixa.
- Soltar sobre uma aba existente acrescenta conteúdo àquela caixa; soltar em outro ponto da lateral cria outra.
- Retirar um item da caixa é reversível pelo menu da barra.
- Preserva os arquivos originais e mantém cópias próprias no cofre.
- Não monitora silenciosamente o clipboard e não depende de permissões de Acessibilidade ou Input Monitoring.
- A base atual usa AppKit e Swift Package Manager, com alvo mínimo macOS 15 e aprimoramento nativo no macOS 26.

## Brand Commitments

- Nome: Borda.
- Interface discreta, espacial e direta.
- A linguagem visual segue o Liquid Glass nativo da Apple, sem transformar o efeito em decoração gratuita.

## Evidence on Hand

- Protótipo funcional e dados locais existentes.
- Comportamento de referência observado no Dropshelf.
- Não há identidade gráfica, logotipo ou pesquisa formal de usuários fornecida.

## Product Principles

1. A borda só aparece quando existe algo para lembrar.
2. Cada grupo conserva um endereço espacial reconhecível.
3. Guardar e recuperar conteúdo deve funcionar por manipulação direta.
4. O original nunca é movido ou alterado.
5. Recursos recentes do sistema aprimoram a experiência sem eliminar a compatibilidade anterior.

## Accessibility & Inclusion

Respeitar Reduzir Movimento, aparências clara/escura, contraste aumentado e textos legíveis do sistema.
