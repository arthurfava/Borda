---
name: Borda
description: Caixas espaciais de Liquid Glass para transportar conteúdo entre aplicativos do macOS.
colors:
  accent: "NSColor.controlAccentColor"
  text-primary: "NSColor.labelColor"
  text-secondary: "NSColor.secondaryLabelColor"
  error: "NSColor.systemRed"
  glass-tint-rest: "shelfColor@7.5%"
  glass-tint-tab: "shelfColor@8%"
  glass-tint-tab-hover: "shelfColor@12%"
  glass-tint-drop: "controlAccentColor@16%"
typography:
  title:
    fontFamily: ".system"
    fontSize: "13pt"
    fontWeight: 600
  body:
    fontFamily: ".system"
    fontSize: "12.5pt"
    fontWeight: 600
  label:
    fontFamily: ".system"
    fontSize: "10.5pt"
    fontWeight: 400
rounded:
  tab: "15pt"
  shelf: "18pt"
spacing:
  edge-trigger: "12pt"
  shelf-inset: "8pt"
  header-inset: "16pt"
components:
  shelf-expanded:
    width: "286pt"
    rounded: "{rounded.shelf}"
    backgroundColor: "{colors.glass-tint-rest}"
  shelf-tab:
    width: "44pt, 17pt visible"
    height: "84pt"
    rounded: "{rounded.tab}"
    backgroundColor: "{colors.glass-tint-tab}"
---

# Design System: Borda

## Overview

**Creative North Star: "A gaveta na borda do vidro"**

Borda deve parecer uma propriedade espacial do macOS, não uma janela adicionada sobre ele. Quando há conteúdo, uma pequena cápsula permanece parcialmente fora da tela como memória visual. Sob o ponteiro ou durante um arrasto, ela se expande em uma superfície contínua de vidro e revela o conteúdo sem trocar o foco do aplicativo em uso.

O vidro tem função: separar conteúdo temporário do ambiente preservando contexto, legibilidade e sensação de profundidade. A interface é compacta, silenciosa e operacional. **Características-chave:** material nativo, endereço espacial persistente, lista limpa, movimento curto e uma única cor de feedback.

## Colors

A paleta é integralmente semântica e acompanha aparência, papel de parede, contraste e cor de destaque definidos pelo usuário no macOS.

### Primary

- **Cor de ação do sistema** (`NSColor.controlAccentColor`): aparece apenas no estado de drop.
- **Cor da caixa:** tonaliza toda a superfície de vidro em baixa opacidade; nunca colore somente o título.

### Neutral

- **Texto primário do sistema** (`labelColor`): títulos e nomes.
- **Texto secundário do sistema** (`secondaryLabelColor`): tipo, tamanho e contagem.
- **Vidro em repouso** (`black @ 6%`): leve neutralização sobre o efeito nativo, sem pintar uma placa opaca.

**Regra do azul transitório.** A cor de destaque comunica uma ação de drop em curso; não é decoração permanente.

## Typography

**Display, Body e Label:** San Francisco, pela pilha tipográfica nativa do macOS.

**Character:** direta e compacta, herdando métricas, hinting e acessibilidade do sistema.

### Hierarchy

- **Título da caixa** (semibold, 13 pt): nome da superfície.
- **Nome do item** (semibold, 12,5 pt): uma linha, truncamento central para preservar começo e extensão.
- **Metadado** (regular, 10,5 pt): tipo e tamanho.
- **Contagem da cápsula** (semibold monoespaçada, 11 pt): estabilidade visual entre números.

## Layout

Uma caixa aberta mede 286 pt de largura e cresce de 104 pt até 341 pt de altura. O cabeçalho usa 16 pt de respiro lateral; a lista usa 8 pt e linhas de 57 pt separadas por hairlines. A cápsula usa uma janela de 44 × 84 pt, da qual apenas 17 pt permanecem dentro da tela. A faixa invisível de criação ocupa 12 pt ao longo das laterais úteis de cada monitor.

Cada caixa mantém lateral, monitor e altura normalizada. Centros separados por menos de 74 pt pertencem à mesma caixa, evitando cápsulas sobrepostas. Acima dessa distância, um drop cria um novo grupo. A cápsula existente recebe uma margem magnética de 18 pt na horizontal e 14 pt na vertical; aberta, a caixa mantém 10 pt de tolerância em todo o perímetro. Essa margem é apenas interativa e nunca desenhada.

## Elevation & Depth

No macOS 26, `NSGlassEffectView` no estilo `clear`, com tintura de baixa opacidade, produz lente, refração e maior transparência. No macOS 15–25, `NSVisualEffectView` com material popover mantém vibrância sem simular reflexos. A sombra pertence à janela flutuante e o conteúdo evita cartões, bordas e sombras internas concorrentes.

**Regra do material funcional.** O vidro delimita a caixa e responde ao contexto; nenhuma camada extra existe apenas para parecer futurista.

## Shapes

A silhueta é uma gaveta arredondada contínua: raio de 15 pt recolhida e 18 pt expandida. A parte fora da tela cria a impressão de que a caixa mora atrás da borda. Linhas internas são retas e discretas; pills adicionais e cartões aninhados não fazem parte do sistema.

## Components

### Cápsula recolhida

- **Forma:** 44 × 84 pt, 17 pt visíveis, raio 15 pt.
- **Conteúdo:** chevrons apontando para dentro e contagem de itens.
- **Estado:** permanece visível somente enquanto a caixa contém itens; a aproximação realça a tintura de 6% para 11% e expande.

### Caixa expandida

- **Forma:** 286 pt, raio 18 pt, altura determinada por até cinco itens visíveis.
- **Superfície:** Liquid Glass regular no macOS 26; material vibrante no fallback.
- **Cabeçalho:** “Caixa” à esquerda e contagem à direita.
- **Drop:** tintura de 18% da cor de destaque; após concluir, volta ao repouso e recolhe.

### Linha de item

- **Estrutura:** ícone de 32 pt, nome, metadado e botão de remoção de 28 pt.
- **Separação:** hairline iniciada depois do ícone.
- **Hover:** revela o botão de remoção; não adiciona fundo de cartão.
- **Arrasto:** toda a linha inicia o gesto no primeiro clique; somente o botão de remoção conserva hit target próprio.
- **Seleção:** preserva o fundo transparente; não usa preenchimento azul nem contorno persistente.
- **Acessibilidade:** nome, ajuda e ações “Copiar item” e “Remover item”.

### Movimento

- **Expansão:** 0,18 s, ease-out, sem reiniciar quando o gatilho emite eventos repetidos.
- **Revelação:** conteúdo aparece em 0,10 s depois que a superfície termina de expandir, evitando compressão e distorção.
- **Recolhimento:** 0,14 s, ease-in, somente depois que o cursor deixa também a margem magnética.
- **Rastreamento:** posição global do cursor confirmada a cada 50 ms; eventos nativos continuam como resposta imediata e redundante.
- **Acessibilidade:** duração zero quando Reduzir Movimento está ativo.

## Do's and Don'ts

### Instalação

O DMG usa uma janela de 660 × 400 pt, sem barras do Finder, com o Borda à esquerda e o atalho de Aplicativos à direita. Um fundo escuro da própria identidade contém título, instrução curta e seta direcional; os ícones permanecem objetos reais e arrastáveis do Finder, não ilustrações incorporadas.

### Do:

- **Do** use cores, tipografia, símbolos e preferências de movimento do sistema.
- **Do** manter uma aba visível para cada caixa com conteúdo.
- **Do** usar o vidro como limite único da superfície.
- **Do** truncar nomes preservando começo e extensão.

### Don't:

- **Don't** mostrar uma borda grande quando não há conteúdo.
- **Don't** empilhar cartões escuros dentro da caixa de vidro.
- **Don't** usar a cor de destaque fora de feedback de interação.
- **Don't** criar cápsulas a menos de 74 pt uma da outra.
