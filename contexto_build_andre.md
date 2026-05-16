# Contexto - build Android isolada para o professor Andre

## Objetivo final

Manter uma branch Android separada do Motiva para o professor Andre testar no box dele, sem qualquer referencia ao Firebase de producao e sem misturar dados entre ambientes.

Nesta build:

- o Firebase e o projeto `motiva-andre`;
- o app Android usa o package `com.motiva.buildAmdre`;
- o professor deve ser `athleteCoach`, para alternar entre visao de coach e atleta;
- o login fica apenas com email e senha;
- notificacoes/FCM, suporte por email e fluxo de PDF/Storage ficam fora;
- o banco mantem a mesma arquitetura principal;
- o box padrao da branch e `BOX_ANDRE` / `Box do André`;
- os treinos serao cadastrados manualmente depois, mas o fluxo de analise por IA continua sendo o mesmo quando um treino existir.

## O que ja foi feito

### Firebase e Android

- `.firebaserc` aponta somente para `motiva-andre`;
- `firebase.json` ficou apenas com Android, Firestore e Functions;
- `firebase_options.dart` foi trocado para o projeto novo;
- `android/app/google-services.json` foi substituido pelo arquivo novo;
- `namespace` e `applicationId` Android agora sao `com.motiva.buildAmdre`;
- o plugin Google Services foi atualizado no Gradle;
- os arquivos Firebase de iOS/macOS foram removidos da branch.

### Dados iniciais

- a colecao `movimentos` foi copiada do Firebase antigo para o novo antes da limpeza;
- a validacao confirmou:
  - `64` documentos na origem;
  - `64` documentos gravados no novo projeto;
  - mesmos IDs;
  - mesmos campos.

### Fluxos removidos

- login com Google;
- Cloud Messaging, notificacoes in-app e tokens;
- telas e servicos de suporte/feedback/bug report;
- parser de PDF, upload de treino por PDF e regras de Storage;
- funcoes agendadas e chamadas associadas a notificacoes;
- referencias de codigo ao Firebase antigo e credenciais antigas.

### Fluxos mantidos

- autenticacao por email e senha;
- Firestore;
- Functions;
- IA com Gemini;
- telas de coach e atleta;
- analises e insights que nao dependiam dos modulos removidos.

## Estado esperado do projeto novo

No Firebase/GCP, o projeto `motiva-andre` deve ter:

- Firestore ativado;
- Auth por email/senha ativado;
- plano Blaze ativo;
- a colecao `movimentos` ja populada;
- secret `GEMINI_API_KEY` cadastrada antes do deploy das Functions;
- fila do Cloud Tasks criada antes de usar os fluxos que dependem dela;
- deploy de Firestore Rules e Functions feito para `motiva-andre`.

## O que ainda falta fazer depois da implementacao

1. Rodar:

   ```bash
   cd flutter_app
   firebase functions:secrets:set GEMINI_API_KEY --project motiva-andre
   ```

2. Criar a fila do Cloud Tasks usada pelo backend novo, no projeto `motiva-andre`, com a mesma regiao configurada nas Functions.

3. Fazer o deploy para o projeto novo:

   ```bash
   cd flutter_app
   firebase deploy --only firestore:rules,functions --project motiva-andre
   ```

4. Criar a conta do professor pelo app e confirmar no Firestore que o documento do usuario ficou com perfil `athleteCoach`.

5. Testar no Android:
   - cadastro;
   - login;
   - troca entre coach e atleta;
   - leitura dos movimentos;
   - telas de treino e analise que ja existem.

6. Depois, implementar o cadastro manual de treino para substituir o fluxo antigo de PDF.

## Cuidados

- Nao criar alias de producao nesta branch.
- Nao recolocar arquivos, IDs, service accounts ou configs do Firebase antigo.
- Confirmar sempre `--project motiva-andre` em comandos de deploy.
- Como esta branch e Android-only, configuracoes Apple nao entram neste fluxo.

## Validacoes ja executadas

- busca por IDs do Firebase antigo sem ocorrencias no repositorio ativo;
- testes Python das Functions: `34` testes passaram;
- testes Flutter: todos passaram;
- processamento do `google-services.json` Android foi exercitado na build debug;
- a compilacao Android completa foi concluida com sucesso.
