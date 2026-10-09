# Integrações do sistema

O aplicativo principal já expõe “Guardar no Borda” em Serviços e as URLs
`borda://show`, `borda://capture` e `borda://restore`, utilizáveis pelo app Atalhos.

`BordaShare` contém a fonte da extensão do menu Compartilhar. Ela exige um alvo
de extensão criado pelo Xcode completo, App Group e assinatura Developer ID/App
Store. O Command Line Tools disponível nesta máquina não produz nem assina um
bundle `.appex` confiável; por isso ele não é copiado silenciosamente para o app.
