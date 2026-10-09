# Landing page do Borda

Site estático, multilíngue e pronto para Vercel. O build gera a pasta `dist`.

## Rodar localmente

```sh
npm install
npm run build
npm run check
npx serve dist
```

Sem `BORDA_DOWNLOAD_URL`, a rota `/download/` informa que a versão pública ainda está sendo preparada. Isso evita oferecer como verificada uma build ainda não assinada e notarizada com Developer ID.

## Ativar o download

Depois de publicar o DMG em uma URL HTTPS estável, configure na Vercel:

```sh
vercel env add BORDA_DOWNLOAD_URL production
vercel env add BORDA_COFFEE_URL production
vercel env add BORDA_GITHUB_URL production
vercel --prod
```

Exemplo de valor após criar uma release no GitHub:

```text
https://github.com/arthurfava/Borda/releases/download/v0.9.0/Borda-0.9.0.dmg
```

O botão principal, a página de download e `releases/latest.json` passam a usar essa URL automaticamente. As outras duas variáveis ativam `/cafe/` e `/github/`; sem elas, essas rotas exibem páginas de espera em vez de links quebrados.

## Publicar na Vercel

1. Importe a pasta `website` como projeto novo.
2. Mantenha o preset como `Other`.
3. Use `npm run build` como Build Command.
4. Use `dist` como Output Directory.
5. Adicione as três variáveis somente quando os respectivos destinos públicos estiverem prontos.
6. Publique e, depois, adicione `getborda.app` em **Settings → Domains**.

O domínio ainda não precisa existir no primeiro deploy. As URLs canônicas já apontam para `https://getborda.app`.
