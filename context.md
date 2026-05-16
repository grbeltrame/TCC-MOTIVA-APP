# Contexto do Projeto MOTIVA

Este arquivo resume as principais decisões, implementações e validações feitas durante a conversa sobre o app MOTIVA. Ele serve como memória rápida para retomar o desenvolvimento, deploy e testes sem depender do histórico completo do chat.

## Visão Geral

- O projeto principal fica em `flutter_app/`.
- O app usa Flutter no frontend e Firebase/Cloud Functions no backend.
- O foco recente foi preparar o app para testes reais em Android/iOS e melhorar o módulo de IA para atletas.
- As alterações mais recentes são apenas em Cloud Functions e scripts locais; não exigem atualização do app instalado pelos atletas/coaches quando forem deployadas.

## Deploy e Testes Mobile

### Android

- O app oficial Android usa o package:
  - `com.motiva.buildAmdre`
- O app antigo `com.example.flutter_app` no Firebase não deve ser usado como oficial.
- A distribuição de APK para testes foi feita pelo Firebase App Distribution.
- Se não houver grupo de testers criado, o upload da release pode funcionar, mas a distribuição para `--groups testers` falha com 404.
- Para Android, normalmente é necessário cadastrar os e-mails dos testers no Firebase App Distribution ou criar um grupo antes de distribuir.

Comando usado como base:

```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:877545487911:android:827789bc563d3450b31802 \
  --groups testers \
  --release-notes "Nova versão de teste do MOTIVA"
```

### iOS

- A conta Apple Developer foi ativada.
- O app foi registrado no App Store Connect.
- O Bundle ID oficial deve ser:
  - `com.motiva.buildAmdre`
- Foi feito upload via Xcode Organizer/TestFlight.
- Um erro de App Store Connect ocorreu por falta de purpose string:
  - `NSPhotoLibraryUsageDescription`
- A correção foi adicionar a descrição de uso da galeria no `Info.plist`.
- Após upload correto, a build apareceu no TestFlight.
- Testers externos precisam passar por aprovação da Apple; testers internos podem usar antes da revisão externa.
- Testers iOS precisam instalar o app TestFlight para baixar o MOTIVA.

## Firebase, Rules e Status de Treinos

- `firestore.rules` foi ajustado para permitir:
  - Coaches/admins leem rascunhos e publicados.
  - Atletas leem apenas treinos publicados.
  - Dados antigos sem `status` ou com `status: processado` são tratados como publicados para compatibilidade.
- Treinos importados via PDF nascem como:
  - `status: "rascunho"`
- Ao publicar:
  - `status: "publicado"`
  - `publishedAt`
  - `publishedByUid`
  - `statusAnalise: "pendente"`
- IA e notificações pré-treino só rodam para treinos publicados.

## Parser de PDF

Foi planejada e implementada uma refatoração importante do parser:

- PDFs mensais são processados página a página.
- Cada página com data válida pode virar um treino separado.
- Capa, domingo/`BOX FECHADO` e páginas sem treino estruturado são ignoradas.
- Treinos importados ficam em rascunho até publicação manual do coach.
- Parser passou a preservar melhor:
  - `Buy in - 500m run`
  - `Buy out - 500m run`
  - `*Break penalty`
  - penalties com hífen
  - `Active - Sit up`
  - `Rest - Crunch`
  - `TEAM WARM UP`
  - esquemas como `5|5|5|3|3 Deadlift`
  - linhas de EMOM como `1º- 16 Box jump over`
- Foi adicionada compatibilidade de item com `kind`, mantendo `raw`, `quantidade`, `nome`, `unidade`, `cargaRx`, `cargaScaled`.

## IA Pré-Treino Sem Perfil Detalhado

Foi removida a dependência obrigatória de `users/{uid}/profiles/athlete` para gerar insight pré-treino.

Agora a elegibilidade usa:

- `users/{uid}.profile in ["athlete", "athleteCoach", "athleteIntern"]`

O perfil detalhado continua sendo usado como complemento quando existe:

- Se existir: entra no prompt.
- Se não existir: retorna `{"hasDetailedProfile": false}` e a IA não inventa categoria, gênero, peso, altura ou experiência.

Mantidos os bloqueios:

- Conta desativada.
- `settings/privacy.aiPersonalizationEnabled == false`.
- Falta total de dados mínimos.

Também foi ajustado o caso em que o treino já tinha hash igual:

- Antes a Function pulava tudo.
- Agora, com hash igual, ela ainda procura atletas elegíveis sem insight daquele treino e gera apenas para quem está faltando.
- Isso permite corrigir casos como uma atleta sem `profiles/athlete` sem editar o treino.

## Notificações

Importante separar duas coisas:

- Geração da IA:
  - Cria o documento em `users/{uid}/insights/pre_workout/items/{workoutId}`.
- Notificação:
  - Cria doc em `users/{uid}/notifications/{dedupeKey}`.
  - Tenta enviar push para o celular.

Configurações:

- `settings/privacy.aiPersonalizationEnabled == false` bloqueia a geração da IA.
- `settings/athlete.preWorkoutInsights == false` bloqueia só a notificação de pré-treino.
- Se o push falhar, a notificação interna ainda pode existir no app, porque o backend salva a notificação antes de tentar o push.

Erro visto nos logs:

```text
[notifications] falha ao enviar push uid=...:
Request is missing required authentication credential...
```

Esse erro está ligado ao envio de push/autenticação FCM, não necessariamente à geração do insight no banco.

## Módulo de IA do Atleta

Módulo principal:

- `flutter_app/functions/athlete_insights_module/`

Fluxos:

- Weekly:
  - `run_weekly_insights_task`
  - Usa `create_weekly_insights_prompt`
- Evolution:
  - `get_athlete_evolution_insights`
  - Usa `create_evolution_insights_prompt`
- Pre-workout:
  - `generate_pre_workout_insights`
  - Usa `create_pre_workout_insights_prompt`

## Melhorias de Prompt e Contexto da IA

Foi criado:

- `functions/athlete_insights_module/context_builder.py`

Ele pré-computa dados que o LLM não deve calcular sozinho:

- Tendência objetiva de performance:
  - `forTimeSec` caindo em FOR TIME.
  - `amrapRounds`/`amrapReps` subindo em AMRAP.
- Marcos de frequência:
  - Ex: atleta perto de 100 treinos.
- Formato do microciclo:
  - `front_loaded`
  - `back_loaded`
  - `balanced`
  - `single_peak`
- Taxa de conclusão por modalidade.
- Distribuição de categoria:
  - `rxPercentage`
  - `scaledPercentage`
  - `intermediatePercentage`
  - `otherPercentage`
- Melhor bloco de 4 semanas.
- Perfil PR x ICN.
- Eficiência de PR por dia de treino.
- Âncoras do treino do dia.
- Histórico do mesmo dia da semana.
- Histórico do mesmo dia + mesma modalidade.
- Taxa de conclusão do mesmo tipo no pré-treino.

## Ajustes v2 Mais Recentes

### Corrigido

- `_load_shape()` agora classifica semana com exatamente 1 treino como `single_peak`.
- `_category_mix()` agora entende `Intermediário` como categoria própria, não como Scaled.

### Adicionado ao pré-treino

- `sameWeekdaySameTypePerformance`:
  - Mesmo dia da semana e mesma modalidade/tipo.
- `completionRateSameType`:
  - Taxa de conclusão na modalidade/tipo do treino atual.

### Adicionado aos prompts

Foram adicionados glossários específicos:

- `_weekly_context_glossary()`
- `_evolution_context_glossary()`
- `_pre_workout_context_glossary()`

Também foi reforçado que as mensagens devem ser:

- Curtas.
- Humanas.
- Atentas.
- Não secas.
- Não robóticas.
- Sem jargão técnico para o atleta.

## Regra de Cargas Masculina/Feminina

Foi preservada no prompt de pré-treino:

- Quando um exercício tiver duas cargas, interpretar como:
  - primeira carga = masculina
  - segunda carga = feminina

Exemplos:

- `90Kg|50Kg`
- `90Kg/50Kg`
- `cargaRx=90Kg` e `cargaScaled=50Kg`

O prompt orienta:

- Se `athlete_profile.gender` for mulher, usar a segunda carga.
- Não gerar alerta para mulher usando carga masculina.
- Se gênero estiver ausente ou ambíguo, não citar carga numérica como personalizada.

## Avaliador Local com Gemini

Foi criado:

- `flutter_app/functions/tools/evaluate_athlete_insights.py`

Objetivo:

- Montar prompts reais com dados reais do Firestore.
- Opcionalmente chamar o Gemini.
- Mostrar:
  - resumo dos dados
  - prompt
  - resposta crua
  - JSON parseado
  - checklist de qualidade
- Não escreve em Firestore.
- Não cria notificações.
- Não altera treinos.

Comando base:

```bash
PYTHONPATH=functions functions/venv/bin/python functions/tools/evaluate_athlete_insights.py \
  --flow all \
  --uid <UID_DO_ATLETA> \
  --workout-id "<ID_DO_TREINO>" \
  --project-id motiva-andre
```

Modo sem chamada ao Gemini:

```bash
PYTHONPATH=functions functions/venv/bin/python functions/tools/evaluate_athlete_insights.py \
  --flow all \
  --uid <UID_DO_ATLETA> \
  --workout-id "<ID_DO_TREINO>" \
  --project-id motiva-andre \
  --hide-prompt \
  --no-llm
```

Exemplo já usado:

```bash
PYTHONPATH=functions functions/venv/bin/python functions/tools/evaluate_athlete_insights.py \
  --flow all \
  --uid girs2jkfxHOkJeq30PsR1yrEMnt1 \
  --workout-id "LONG HEAVY (12-05-2026)" \
  --project-id motiva-andre \
  --hide-prompt \
  --no-llm
```

Observação:

- Warnings do Firestore sobre `Detected filter using positional arguments` são avisos de estilo da SDK, não erros.

## Validações Realizadas

Testes atuais após as melhorias v2:

```bash
PYTHONPATH=functions functions/venv/bin/python -m unittest discover -s functions/tests
```

Resultado:

```text
Ran 44 tests
OK
```

Smoke test de prompt:

```bash
PYTHONPATH=functions functions/venv/bin/python functions/tests/test_prompt.py
```

Resultado:

```text
2/2 testes passaram
```

Validador local read-only:

- Rodado com `--no-llm`.
- Confirmou no atleta real:
  - `currentMicrocycle.shape = single_peak`.
  - `Intermediário` entra como `intermediatePercentage`.
  - `sameWeekdaySameTypePerformance` aparece no pré-treino.
  - `completionRateSameType` aparece no pré-treino.

## Deploy das Functions

Depois de revisar e aceitar as mudanças, o deploy pode ser feito só das Functions afetadas:

```bash
firebase deploy --only functions:run_weekly_insights_task,functions:get_athlete_evolution_insights,functions:generate_pre_workout_insights
```

Como essas mudanças são backend/Functions:

- Atletas não precisam atualizar o app.
- Coaches não precisam atualizar o app.
- O comportamento novo passa a valer após deploy das Functions.

## Observações e Cuidados

- Não houve alteração intencional de schema salvo nos documentos de insights.
- Não houve backfill automático.
- Não houve alteração nas regras do Firebase nesta etapa recente.
- O avaliador local é seguro para inspeção, desde que usado em modo `--no-llm` se a intenção for não gastar chamada Gemini.
- Para chamar Gemini localmente, usar:
  - `GEMINI_API_KEY` no ambiente, ou
  - Secret Manager com autenticação local configurada.
- Se o Secret Manager falhar localmente:

```bash
gcloud auth application-default login
```

## Estado Mental Para Retomar

O app já estava em fase de testes reais em Android e iOS. A prioridade recente deixou de ser UI e passou a ser:

1. Garantir que a IA rode para atletas elegíveis mesmo sem perfil detalhado.
2. Tornar os insights menos genéricos.
3. Fazer o Gemini usar dados pré-computados em vez de tentar calcular sozinho.
4. Validar localmente antes de deployar Functions.
5. Manter o app instalado funcionando sem exigir nova build mobile.

