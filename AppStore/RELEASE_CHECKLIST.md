# Borda — checklist da Mac App Store

## 1. Conta e certificados

- [ ] Assinar o Apple Developer Program como Arthur Fava.
- [ ] Instalar o Xcode completo e aceitar a licença.
- [ ] Adicionar a conta Apple em Xcode › Settings › Accounts.
- [ ] Registrar `com.arthurfava.Borda` e `group.com.arthurfava.Borda`.
- [ ] Criar Apple Development, Apple Distribution e Developer ID Application.
- [ ] Aceitar Paid Apps Agreement e preencher banco e impostos.

## 2. App Store Connect

- [ ] Criar o app macOS “Borda: Edge Shelf” com bundle ID `com.arthurfava.Borda`.
- [ ] Categoria principal: Utilities; preço: Free; liberação: Manual.
- [ ] Informar `https://getborda.app/privacy/`, `/support/` e a URL de marketing.
- [ ] Declarar “Data Not Collected” somente depois da auditoria final do binário.
- [ ] Responder classificação etária e criptografia de exportação.
- [ ] Criar os três consumíveis definidos em `SupportService.swift`.
- [ ] Inserir os metadados gerados em `AppStore/metadata/`.
- [ ] Subir cinco screenshots reais por idioma, sem mockups enganosos.

## 3. Archive e TestFlight

```sh
export BORDA_DEVELOPMENT_TEAM="SEU_TEAM_ID"
./scripts/archive-app-store.sh
open build/Borda-AppStore.xcarchive
```

- [ ] Validar o archive no Organizer e enviar ao App Store Connect.
- [ ] Testar StoreKit, drag-in/out, login item, pastas observadas e migração no TestFlight.
- [ ] Cobrir macOS 15 e 26, Apple Silicon e Intel, um e vários monitores.
- [ ] Testar aparências clara/escura, Reduzir Movimento e contraste aumentado.

## 4. Revisão

- [ ] Anexar vídeo curto mostrando como ativar a lateral e retirar um item.
- [ ] Explicar nas Review Notes que o acesso a arquivos ocorre por ação explícita.
- [ ] Explicar que cafés são consumíveis opcionais e não liberam recursos.
- [ ] Confirmar que a build App Store não contém Buy Me a Coffee nem download externo.
- [ ] Enviar para revisão e manter a liberação manual.

## 5. Lançamento coordenado

- [ ] Aprovação da Apple recebida.
- [ ] DMG 1.0.0 assinado, notarizado, grampeado e verificado em um Mac limpo.
- [ ] Tag `v1.0.0` e GitHub Release publicados.
- [ ] `getborda.app/download/` baixando o DMG correto.
- [ ] Landing, política, suporte e Buy Me a Coffee conferidos.
- [ ] Liberar manualmente a Mac App Store.
