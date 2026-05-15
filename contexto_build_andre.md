# Contexto - build Android isolada para o professor Andre

## Objetivo

Criar uma build Android separada do app Motiva para o professor do TCC testar no box dele, sem misturar dados com o ambiente atual de producao.

Essa build deve:

- apontar para um novo projeto Firebase isolado;
- manter a mesma arquitetura de banco atual;
- permitir que ele cadastre treinos do box dele e veja as analises do box dele;
- rodar apenas em Android;
- remover/simplificar o login com Google, mantendo apenas email e senha;
- poder usar outro projeto Firebase e ate outra conta Google, se isso facilitar.

## Decisao tomada

Para esse caso especifico, nao e necessario montar uma estrutura completa de `dev`/`prod` com Apple, iOS, macOS ou multiplos flavors complexos.

O caminho mais simples e suficiente e:

1. Criar um novo projeto Firebase, por exemplo `motiva-teste-professor`.
2. Cadastrar nele apenas um app Android.
3. Gerar a configuracao Android nova desse projeto.
4. Fazer uma build Android apontando somente para esse Firebase novo.
5. Remover da build o fluxo de login com Google.
6. Subir no novo Firebase a mesma estrutura backend usada hoje:
   - Firestore;
   - Storage;
   - Cloud Functions;
   - regras;
   - segredos/configuracoes necessarios.
7. Popular o novo banco com os dados iniciais do box dele usando a mesma modelagem existente.

## Conclusao da conversa

Nesse escopo reduzido, a dificuldade e baixa para media.

Nao e uma mudanca arquitetural grande; e principalmente uma duplicacao controlada de configuracao e infraestrutura:

- novo Firebase;
- nova configuracao Android;
- novo deploy do backend;
- retirada do login Google;
- novo conjunto de dados.

## Pontos importantes

### API key do Firebase

- A API key do Firebase nao e tratada como segredo.
- Mesmo assim, nao vale a pena reaproveitar manualmente a chave antiga.
- O correto e usar a configuracao gerada pelo novo projeto Firebase, com os novos valores de:
  - `apiKey`;
  - `projectId`;
  - `appId`;
  - `messagingSenderId`;
  - `storageBucket`.

### Banco

- A arquitetura pode continuar igual.
- O projeto novo comeca vazio.
- Sera necessario popular os dados iniciais relevantes para o uso do professor, por exemplo movimentos, ciclos e demais documentos-base que o app espera encontrar.

### Backend

O app atual usa backend real, nao apenas Firestore no cliente.

O novo projeto Firebase tambem precisara receber:

- `firestore.rules`;
- `storage.rules`;
- `functions`;
- segredos como `SUPPORT_EMAIL` e `GEMINI_API_KEY`, se essas funcionalidades forem usadas;
- configuracoes relacionadas a filas/tarefas, se forem mantidas.

Observacao: para deploy de Cloud Functions no Firebase, o projeto precisa estar no plano Blaze.

### Login Google

- Pode ser removido dessa build.
- Hoje o fluxo existe no app e ha configuracao hardcoded para Google Sign-In.
- Como essa build sera so para teste do professor e usara email/senha, esse bloco pode ser ocultado/removido para simplificar.

### Package Android

Hoje o app usa:

`com.projetofinal.motivaapp`

Se o professor so vai instalar essa build, pode manter o mesmo package para simplificar.

Se algum dia for necessario instalar a build de teste e a build oficial no mesmo aparelho, sera preciso outro `applicationId`, por exemplo:

`com.projetofinal.motivaapp.andre`

## Estado atual observado no repositorio

### Configuracao Firebase atual

- Projeto atual: `motiva-8b82f`
- Arquivos principais:
  - `flutter_app/lib/firebase_options.dart`
  - `flutter_app/firebase.json`
  - `flutter_app/.firebaserc`
  - `flutter_app/android/app/google-services.json`

### Android

- Arquivo:
  - `flutter_app/android/app/build.gradle.kts`
- Hoje existe apenas um `defaultConfig`.
- Ainda nao existem flavors configurados.
- `applicationId` atual:
  - `com.projetofinal.motivaapp`

### Login

- Login Google esta em:
  - `flutter_app/lib/core/services/auth_service.dart`
  - `flutter_app/lib/features/auth/presentation/login_screen.dart`
  - `flutter_app/lib/features/auth/presentation/google_auth.dart`
- O `serverClientId` do Google esta hardcoded em `auth_service.dart`.
- O login por email/senha ja existe e pode continuar sendo usado.

### Backend

- Codigo principal:
  - `flutter_app/functions/main.py`
- Regras:
  - `flutter_app/firestore.rules`
  - `flutter_app/storage.rules`
- O backend usa:
  - Firestore triggers;
  - Storage trigger;
  - callable functions;
  - segredos;
  - Gemini;
  - Cloud Tasks / tarefas semanais.

## Caminho pratico recomendado ao retomar

1. Criar o novo projeto Firebase.
2. Criar nele um app Android com o package desejado.
3. Baixar o novo `google-services.json`.
4. Gerar ou ajustar o `firebase_options.dart` para o novo projeto Android.
5. Configurar alias no Firebase CLI para evitar deploy no projeto errado:
   - `prod` -> projeto atual;
   - `andre` ou `teste` -> projeto novo.
6. Fazer deploy das regras e functions no projeto novo.
7. Cadastrar os segredos exigidos no projeto novo.
8. Remover da UI e do fluxo o login Google nessa build.
9. Criar/popular os dados iniciais do box do professor.
10. Gerar APK Android e testar cadastro, login, upload de treino e analises.

## Cuidados ao continuar

- Nao sobrescrever sem querer a configuracao de producao se ainda quiser manter o projeto principal intacto.
- Confirmar sempre em qual projeto Firebase o CLI esta apontando antes de rodar deploy.
- Se for usar o mesmo codigo-base para as duas builds no futuro, considerar separar por ambiente com arquivos/configuracoes distintas para evitar trocas manuais.
- Se mantiver apenas uma build temporaria para o professor, a troca manual de config pode ser aceitavel, desde que seja feita com atencao.

