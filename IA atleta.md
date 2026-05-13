# IA do Atleta — Arquitetura Técnica

> Documento técnico do módulo de IA destinado ao **atleta** no app MOTIVA.
> Cobre estrutura, decisões de design, fluxo de execução, engenharia de
> prompt e integrações.
> Não confundir com `ia_module`, que é a IA destinada ao **coach/professor**.

---

## 1. Visão geral

O MOTIVA gera **insights personalizados de IA** para atletas de CrossFit a
partir dos seus dados históricos de treino, dos treinos publicados pelo
coach e do contexto temporal (dia da semana, estágio do microciclo,
janela de carga). O objetivo é entregar ao atleta informação que ele
não conseguiria extrair sozinho dos próprios dados.

A IA do atleta **não substitui** o coach: ela observa padrões,
correlaciona variáveis e devolve uma leitura humana, curta e empática.
Decisões sobre programação de treino são escopo do coach.

**Stack:**

- **Backend:** Cloud Functions (Python 3) na GCP, região `us-central1`.
- **Banco:** Firestore (Native mode) como fonte única de verdade.
- **LLM:** Gemini 2.5 Flash via `langchain-google-genai`.
- **Parsing estruturado:** Pydantic + `PydanticOutputParser`.
- **Orquestração assíncrona:** Cloud Tasks para o fluxo semanal,
  Firestore triggers para o pré-treino, HTTPS Callable para evolução.
- **Observabilidade:** `telemetry_module` (próprio) para métricas de
  geração e `notification_module` (próprio) para alertas in-app/push.

---

## 2. Os três fluxos de inferência

A IA do atleta opera em três fluxos independentes, cada um com gatilho,
janela temporal, cache e schema de saída próprios:

| Fluxo | Janela analisada | Gatilho | Cache | Saída |
|--|--|--|--|--|
| **Weekly** | Semana corrente | Cloud Task (debounce ~5–15 min após write em `results/`) | Sem cache (regenera quando o atleta para de registrar) | 6 insights (alertas + informações) |
| **Evolution** | Últimas 12 semanas | HTTPS Callable (`onCall`) acionado pela tela de evolução | 4 dias em `users/{uid}/insights/evolucao.lastGeneratedAt` | 10 insights |
| **Pre-workout** | Histórico do atleta no mesmo tipo/modalidade do treino de hoje | Firestore trigger em `exercises/{workoutId}` (status=publicado) | Hash do conteúdo do treino — só regenera se mudou | 5 insights |

A separação em três fluxos é deliberada:

1. **Gatilhos diferentes** justificam código separado (debounce
   ≠ trigger Firestore ≠ onCall).
2. **Custo de inferência** é mantido sob controle: weekly só roda quando
   há novidade na semana; evolution tem cache longo; pre-workout
   deduplica por hash.
3. **Schemas Pydantic separados** permitem evoluir cada saída sem
   afetar as outras (frontend consome cada uma em telas distintas).

---

## 3. Arquitetura geral

```
                        ┌──────────────────────────┐
                        │   Firestore (verdade)    │
                        │  users/{uid}/results/    │
                        │  users/{uid}/weekly_load │
                        │  users/{uid}/prs         │
                        │  users/{uid}/stats       │
                        │  users/{uid}/insights/   │
                        │  exercises/{workoutId}   │
                        │  cohorts/{key}           │
                        └────────────┬─────────────┘
                                     │
            ┌────────────────────────┼────────────────────────────┐
            │                        │                            │
            ▼                        ▼                            ▼
   ┌────────────────┐       ┌─────────────────┐       ┌───────────────────┐
   │  Cloud Tasks   │       │  Firestore      │       │  HTTPS onCall     │
   │ (debounce)     │       │  trigger        │       │  do app           │
   │ ⇒ weekly       │       │ ⇒ pre-workout   │       │  ⇒ evolution      │
   └───────┬────────┘       └────────┬────────┘       └─────────┬─────────┘
           │                         │                          │
           └────────────────┬────────┴──────────────────────────┘
                            │
                            ▼
                ┌─────────────────────────┐
                │ athlete_insights_module │
                │                         │
                │ logic.py                │
                │ pre_workout_logic.py    │
                │ context_builder.py      │
                │ prompt_builder.py       │
                │ models.py               │
                └────────────┬────────────┘
                             │
                             ▼
                  ┌────────────────────┐
                  │  Gemini 2.5 Flash  │
                  │  via langchain     │
                  └──────────┬─────────┘
                             │
                ┌────────────┴──────────────┐
                │                           │
                ▼                           ▼
      ┌───────────────────┐       ┌─────────────────────┐
      │ Persistência      │       │ Side-effects        │
      │ users/{uid}/      │       │ telemetry_module    │
      │   insights/*      │       │ notification_module │
      └───────────────────┘       └─────────────────────┘
```

Os módulos externos (`cohort_module`, `telemetry_module`,
`notification_module`, `user_settings_module`) são importados sob
demanda dentro das funções (lazy import) — minimiza o impacto no cold
start das Cloud Functions e evita acoplamento desnecessário entre
domínios.

---

## 4. Estrutura de arquivos

[flutter_app/functions/athlete_insights_module/](flutter_app/functions/athlete_insights_module/) contém todo o domínio da IA do atleta:

```
athlete_insights_module/
├── __init__.py           # Reexporta as 3 funções de entrada
├── models.py             # Schemas Pydantic + factories de parser
├── logic.py              # Orquestração weekly + evolution
├── pre_workout_logic.py  # Orquestração pré-treino (separada)
├── context_builder.py    # Pré-computação determinística
└── prompt_builder.py     # Construção de prompts + glossários
```

**Por que `pre_workout_logic.py` está separado de `logic.py`:** o
fluxo pré-treino tem um gatilho fundamentalmente diferente (Firestore
trigger global em `exercises/`, iterando N atletas) e uma estrutura de
deduplicação própria (hash de conteúdo do treino). Misturar essa
lógica com weekly/evolution polui ambos os fluxos. Em [pre_workout_logic.py:412](flutter_app/functions/athlete_insights_module/pre_workout_logic.py#L412), o módulo faz um import lazy de `_get_gemini_api_key` e `_build_llm` do
`logic.py` para reaproveitar a configuração do cliente LLM sem duplicar
código.

Pontos de entrada externos:

```python
# functions/athlete_insights_module/__init__.py
from .logic import (
    run_weekly_insights_logic,
    run_evolution_insights_logic,
)
from .pre_workout_logic import run_pre_workout_insights_logic
```

Cada uma é chamada por um handler em [flutter_app/functions/main.py](flutter_app/functions/main.py):

- `run_weekly_insights_task` ([main.py:318](flutter_app/functions/main.py#L318)) — HTTPS handler chamado pelo Cloud Tasks.
- `get_athlete_evolution_insights` ([main.py:388](flutter_app/functions/main.py#L388)) — HTTPS Callable autenticado.
- `generate_pre_workout_insights` ([main.py:183](flutter_app/functions/main.py#L183)) — Firestore trigger `on_document_written` em `exercises/{workoutId}`.

---

## 5. Modelagem de saída (Pydantic)

[models.py](flutter_app/functions/athlete_insights_module/models.py) define três schemas, todos seguindo o mesmo padrão
`Dict[str, DetailObj]`:

```python
class AlertDetail(BaseModel):
    message: str

class InfoDetail(BaseModel):
    detail: str

class WeeklyInsights(BaseModel):
    alertas: Dict[str, AlertDetail]
    informacoes: Dict[str, InfoDetail]

class EvolutionInsights(BaseModel):
    alertas: Dict[str, AlertDetail]
    informacoes: Dict[str, InfoDetail]

class PreWorkoutInsights(BaseModel):
    alertas: Dict[str, AlertDetail]
    informacoes: Dict[str, InfoDetail]
```

**Por que `Dict[str, DetailObj]` em vez de `List[DetailObj]`:**

1. **Chave semântica e única** — `'desgaste_acumulado'`,
   `'pr_no_movimento_de_hoje'` etc. são "tipos de insight" que o
   frontend pode tratar individualmente (ícone, cor, ação). Lista pura
   exigiria um campo `type` extra em cada item.
2. **Detecção natural de duplicidade** — se o LLM gerar dois insights
   com a mesma chave, um sobrescreve o outro. Em lista, duplicatas
   passariam silenciosamente.
3. **Grupabilidade longitudinal** — facilita comparar "quantos atletas
   tiveram alerta de `monotonia_cronica` essa semana" em consultas
   analíticas, sem precisar parsear strings.

As factories `get_weekly_parser()`, `get_evolution_parser()` e
`get_pre_workout_parser()` instanciam o `PydanticOutputParser` do
LangChain sob demanda — o import é lazy para evitar custo de import na
inicialização do módulo.

---

## 6. Trigger mechanism por fluxo

### 6.1 Weekly — Cloud Tasks com debounce e jitter

O fluxo weekly é o mais complexo do ponto de vista de orquestração.
Cada vez que o atleta cria/edita/deleta um documento em
`users/{uid}/results/{resultId}`, o trigger `update_athlete_stats`
([main.py:232](flutter_app/functions/main.py#L232)) é acionado. Dois passos rodam:

1. **Matemática pura** — `update_athlete_stats_logic` recalcula
   `stats/summary` e `weekly_load` do atleta (volume, ICN, monotonia,
   strain, PRs, etc.). Determinístico, rápido, sem LLM.

2. **Enfileiramento da task de IA** — `_enqueue_weekly_insights_task(uid)` ([main.py:63](flutter_app/functions/main.py#L63)).

A Cloud Task tem três propriedades cruciais:

**(a) Nome determinístico:**

```python
bucket = int(now.timestamp() // _TASK_DELAY_SECONDS)
task_name = f"{parent}/tasks/weekly-{uid}-{bucket}"
```

O nome contém o UID do atleta e um "bucket" de tempo (janela de 5 min).
Se o atleta publicar 3 resultados em sequência (terminou o WOD, marcou
duas atividades extras), as 3 tentativas de enfileirar geram o **mesmo
nome de task** — o Cloud Tasks recusa as duplicatas com
`ALREADY_EXISTS`, e apenas UMA execução ocorre depois do debounce.

**(b) Delay base de 5 min + jitter de até 10 min:**

```python
total_delay = _TASK_DELAY_SECONDS + _uid_jitter_seconds(uid)
# total_delay ∈ [300, 900] segundos
```

O jitter é **determinístico por UID** (`md5(uid) mod 601`). Isso
distribui atletas que terminam a aula juntos ao longo de ~10 min,
evitando picos de chamadas Gemini no mesmo segundo.

**(c) HTTP Push do Cloud Tasks → handler HTTPS:**

A task agendada faz `POST /run_weekly_insights_task` com
`{"uid": "..."}` no corpo. O handler ([main.py:318](flutter_app/functions/main.py#L318)) chama `run_weekly_insights_logic(uid)`. Esse padrão (write → enfileira → debounce → handler HTTPS) é mais barato e
robusto que `setTimeout`/`sleep` na função original, e absorve picos
naturalmente.

Diagrama da janela de debounce:

```
write em results/  ─┐
write em results/  ─┼─── 5 min ───┐
write em results/  ─┘             │
                                  │
                                  ▼
                          ┌───────────────┐
                          │ + jitter      │
                          │   (0–10 min)  │
                          └───────┬───────┘
                                  │
                                  ▼
                    run_weekly_insights_logic(uid)
```

### 6.2 Evolution — HTTPS Callable com cache

O fluxo evolution é acionado pelo app quando o atleta abre a tela de
evolução. O endpoint `get_athlete_evolution_insights` ([main.py:388](flutter_app/functions/main.py#L388)) é um `https_fn.on_call`, então:

- A autenticação é validada pelo Firebase (`req.auth.uid`).
- O `uid` vem do token, nunca do cliente — proteção contra spoofing.
- O parâmetro opcional `force=true` força regeneração (uso
  administrativo/debug).

`run_evolution_insights_logic` ([logic.py:355](flutter_app/functions/athlete_insights_module/logic.py#L355))
verifica o cache **antes** de chamar o LLM:

```python
if (
    not force
    and existing_data
    and _is_cache_fresh(existing_data.get("lastGeneratedAt"))
):
    return {**existing_data, "fromCache": True}
```

Cache fresco = `lastGeneratedAt < 4 dias`. Esse TTL longo reflete o
tempo característico das análises de longo prazo: a leitura de 12
semanas muda pouco entre duas aberturas próximas da tela.

### 6.3 Pre-workout — Firestore trigger com hash de conteúdo

O fluxo pré-treino é o único que itera **vários atletas em uma única
execução**. Quando o coach publica/edita um treino em
`exercises/{workoutId}`, o trigger `generate_pre_workout_insights` ([main.py:183](flutter_app/functions/main.py#L183)) dispara.

Esse fluxo poderia ser caro: para cada write no documento, regenerar
insights para todos os atletas seria desnecessário se o coach apenas
ajustou o título ou o status. A deduplicação usa um **hash determinístico** dos campos relevantes ([pre_workout_logic.py:41](flutter_app/functions/athlete_insights_module/pre_workout_logic.py#L41)):

```python
_HASH_FIELDS = ('partes', 'modalidade', 'wodType', 'keyMetrics', 'dataTreinoIso')

def _compute_workout_hash(workout: dict) -> str:
    relevant = {k: workout.get(k) for k in _HASH_FIELDS}
    serialized = json.dumps(relevant, sort_keys=True, default=str, ensure_ascii=False)
    return hashlib.md5(serialized.encode('utf-8')).hexdigest()
```

A lógica em [pre_workout_logic.py:357](flutter_app/functions/athlete_insights_module/pre_workout_logic.py#L357) é:

1. Computa o hash atual.
2. Compara com `_preWorkoutInsightsHash` salvo no doc do treino.
3. **Hash igual** → itera atletas elegíveis e gera apenas para quem
   ainda não tem insight desse `workoutId` (cobre o caso de atleta
   que criou perfil depois da primeira geração).
4. **Hash diferente** → regenera para todos.
5. No fim, salva o hash novo em `exercises/{workoutId}._preWorkoutInsightsHash`.

A iteração de atletas tem dois filtros:

```python
def _is_athlete_user(user_doc, db) -> bool:
    data = user_doc.to_dict() or {}
    return data.get('profile') in _ATHLETE_PROFILES
    # {'athlete', 'athleteCoach', 'athleteIntern'}

from user_settings_module import athlete_ai_enabled
if not athlete_ai_enabled(db, user_doc.id):
    continue
```

`athlete_ai_enabled` consulta `users/{uid}/settings/privacy.aiPersonalizationEnabled` e o status da conta. Se a IA estiver desativada
pelo atleta, o fluxo pula completamente — nem o histórico é lido. Isso
é **privacy by design**.

O LLM é instanciado **apenas se houver pelo menos um atleta que precise
de geração** ([pre_workout_logic.py:411](flutter_app/functions/athlete_insights_module/pre_workout_logic.py#L411)):

```python
if llm is None:
    from .logic import _get_gemini_api_key, _build_llm
    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)
```

Esse late-binding evita chamadas ao Secret Manager quando todos os
atletas já têm insights cacheados.

---

## 7. Pipeline de geração — etapas comuns

Os três fluxos seguem a mesma sequência:

```
1. Validar elegibilidade (athlete_ai_enabled)
2. Buscar dados crus do Firestore
3. Buscar coorte (se disponível)         ◄── opcional, falhas não bloqueiam
4. Pré-computar contexto (context_builder)
5. Construir prompt (prompt_builder)
6. Buscar chave da API (Secret Manager)
7. Instanciar Gemini (langchain)
8. Invocar LLM
9. Parsear JSON (PydanticOutputParser)
10. Persistir no Firestore
11. Registrar telemetria                 ◄── não bloqueia
12. Criar notificação                    ◄── não bloqueia
```

**Falhas em etapas 11 e 12 são engolidas com `try/except: pass`** — a
geração já foi salva e o atleta receberá o insight ao abrir o app
mesmo sem notificação push. Isso é decisão consciente: telemetria e
notificações são **side effects observáveis**, não parte do produto
mínimo.

---

## 8. Pré-computação determinística (`context_builder.py`)

Modelos de linguagem são notoriamente ruins em aritmética, em
contagem e em manipulação de datas. [context_builder.py](flutter_app/functions/athlete_insights_module/context_builder.py) existe
exatamente para tirar essa responsabilidade do LLM e entregar
resultados prontos no prompt.

A regra geral é: **se um cálculo é determinístico e auditável, fazer em
Python; se requer interpretação contextual e humana, deixar para o
LLM**.

### 8.1 Funções principais

Três `build_*_context()`, uma por fluxo:

**`build_weekly_context()` ([context_builder.py:266](flutter_app/functions/athlete_insights_module/context_builder.py#L266)):**

```python
{
    "milestone": ...,                    # 50/75/100/... treinos próximo
    "currentMicrocycle": ...,            # shape: front/back/balanced/single
    "habitualMicrocycleShape": ...,      # forma típica das últimas semanas
    "microcycleShift": ...,              # mudança em relação ao habitual
    "modalityPerformanceTrends": ...,    # FOR TIME caindo, AMRAP subindo
    "completionRateByModality": ...,
    "categoryMix": ...,                  # rx / scaled / intermediário / outro
    "performanceResultsAnalyzed": ...,
}
```

**`build_evolution_context()` ([context_builder.py:325](flutter_app/functions/athlete_insights_module/context_builder.py#L325)):**

```python
{
    "bestFourWeekPhase": ...,            # melhor bloco de 4 semanas
    "allFourWeekPhases": ...,            # todos os blocos com scores
    "peakPerformanceProfile": ...,       # zona ICN onde PRs aparecem
    "prEfficiency": ...,                 # PRs por dia de WOD
    "stimulusDistribution": ...,
    "gapAnalysisPolicy": ...,            # texto-regra para evitar invenção
}
```

**`build_pre_workout_context()` ([context_builder.py:479](flutter_app/functions/athlete_insights_module/context_builder.py#L479)):**

```python
{
    "todayAnchors": ...,                 # campos do treino de hoje
    "latestSimilarResult": ...,          # último treino mesmo tipo
    "objectiveTrendSameType": ...,       # tendência objetiva pré-calculada
    "sameWeekdayPerformance": ...,       # como o atleta rende nesse dia
    "sameWeekdaySameTypePerformance": ...,
    "completionRateSameType": ...,
    "prsInTodayWorkout": ...,            # PRs em movimentos de hoje
    "currentLoadSummary": ...,
}
```

### 8.2 Cálculos não-triviais

**Score de melhor bloco de 4 semanas** ([context_builder.py:346](flutter_app/functions/athlete_insights_module/context_builder.py#L346)):

```python
score = (prs * 4) + (wod_days * 0.5) + healthy_weeks - high_weeks
```

A fórmula pondera PRs (sinal forte de evolução), volume saudável,
penaliza semanas com ICN > 75 (zona de risco). É auditável e fixa —
qualquer engenheiro consegue explicar por que aquele bloco foi
escolhido.

**Perfil de zona de pico** ([context_builder.py:377](flutter_app/functions/athlete_insights_module/context_builder.py#L377)):

Para cada PR, consulta o `icnAll` da semana em que ele aconteceu e
classifica em zona (`low` < 45, `medium` 45–65, `high` > 65). Conta a
zona dominante. Se houver pelo menos 3 PRs mapeados, devolve
`status=available` com a zona dominante; senão, `insufficient_data`.

Esse campo é o mais personalizado do fluxo evolution — diz **em que
condição de carga este atleta especificamente bate recordes**. O LLM é
obrigado a usá-lo quando disponível.

**Forma do microciclo** ([context_builder.py:193](flutter_app/functions/athlete_insights_module/context_builder.py#L193)):

A função `_load_shape()` classifica a semana em `front_loaded`,
`back_loaded`, `balanced` ou `single_peak`. A ordem de checagem
importa: **uma semana com apenas 1 dia treinado é `single_peak`, não
`front_loaded`** — checagem feita primeiro para evitar o bug óbvio.

**Tendência objetiva** ([context_builder.py:117](flutter_app/functions/athlete_insights_module/context_builder.py#L117)):

`_trend_from_entries()` calcula direção (`improving`/`declining`/`flat`)
de `forTimeSec` e `amrapRounds*1000 + amrapReps`, respeitando que em
FOR TIME menor é melhor e em AMRAP maior é melhor. Só retorna
tendência se houver pelo menos 3 entradas.

**Mix de categoria** ([context_builder.py:165](flutter_app/functions/athlete_insights_module/context_builder.py#L165)):

`_category_mix()` distribui treinos em 4 categorias —
`rxPercentage`, `scaledPercentage`, `intermediatePercentage`,
`otherPercentage`. **"Intermediário" é tratado como categoria própria**,
não como Scaled — atletas que treinam "Intermediário"
consistentemente não devem ser tratados como Scaled puros.

### 8.3 Por que isso importa para a qualidade da IA

Antes da introdução do `context_builder`, o LLM:

- **Errava** em aritmética básica ao calcular taxas e médias.
- **Inventava** tendências quando os números não eram consistentes.
- **Inventava** marcos de frequência ("você está perto dos 100 treinos!" com 47 treinos).
- **Confundia** ordem cronológica.

Após a pré-computação:

- O prompt cita campos prontos — o LLM apenas **traduz** para
  linguagem humana.
- O esforço cognitivo do modelo vai para o que ele faz bem: ler
  contexto, escolher tom, redigir frases curtas.

---

## 9. Engenharia de prompt (`prompt_builder.py`)

[prompt_builder.py](flutter_app/functions/athlete_insights_module/prompt_builder.py) tem ~1150 linhas e é o coração da qualidade dos
insights. Esta seção detalha as decisões.

### 9.1 Princípios de design

1. **Linguagem humana, dados técnicos por baixo.** O LLM recebe TODOS
   os dados técnicos (ICN, ACWR, monotonia, strain) + glossários
   explicando como interpretá-los. Mas a saída **nunca** pode usar
   esses termos.

2. **Pré-computação > deixar o LLM calcular.** Toda fala que envolve
   número/data/comparação aritmética deve nascer de um campo já
   computado pelo `context_builder`.

3. **Não-obviedade é teste obrigatório.** Toda mensagem passa pelo
   teste: "o atleta saberia disso sem me ler?". Se sim, descarta.
   Insights tipo "você treinou bem essa semana" são proibidos.

4. **Cada insight precisa de cruzamento.** Insights bons vêm de
   correlações entre 2+ variáveis. Cada prompt tem 9 itens explícitos
   de cruzamento.

5. **Tom: personal trainer atento, nunca cientista.** Empático, curto,
   motivacional. Alertas sempre acionáveis (terminam com sugestão
   prática). Zero perguntas (o atleta não pode responder ao LLM).

6. **Coorte só para reforço positivo.** Comparação com a média da
   coorte é usada apenas quando o atleta está **igual ou melhor** —
   nunca para destacar inferioridade.

7. **Calibração temporal.** O prompt sabe o dia da semana e o estágio
   (INÍCIO/MEIO/FIM). No início, fala em "intenção"; no fim, pode
   falar em "passado consolidado".

### 9.2 Blocos comuns aos três fluxos

**`_common_rules()` ([prompt_builder.py:169](flutter_app/functions/athlete_insights_module/prompt_builder.py#L169))**

Define:
- Contexto teórico sobre ICN/ACWR, Session-RPE, Monotonia, Strain
  (apenas para o LLM, NÃO repassar ao atleta).
- **Dicionário do atleta** — proibição rígida de jargão técnico, com
  traduções obrigatórias ("ICN alto" → "seu volume ficou bem acima do
  seu normal").
- Tom, 2ª pessoa, "você", curto-mas-humano.
- **Semântica de `completed` por formato** — distingue o que significa
  "completar" em FOR TIME, AMRAP, EMOM. Especificamente:
  > AMRAP não tem "fim a alcançar" — o atleta faz quantos rounds der
  > no tempo. `completed=false` em AMRAP NÃO deve virar "não concluiu";
  > deve ser "interrompeu antes do fim" ou "ritmo baixo".

  Essa regra foi adicionada após observar que o LLM importava a
  semântica de FOR TIME para AMRAP.

**`_non_obviousness_rule()` ([prompt_builder.py:209](flutter_app/functions/athlete_insights_module/prompt_builder.py#L209))**

Reitera o teste de não-obviedade e instrui contraste temporal
("antes X, agora Y").

**`_few_shot_examples_block(flow)` ([prompt_builder.py:227](flutter_app/functions/athlete_insights_module/prompt_builder.py#L227))**

Por fluxo, traz **1 exemplo ruim + 1 exemplo bom**, cada um com mini-
snapshot dos dados de entrada e motivo explicado. O objetivo não é o
LLM copiar — é calibrar o padrão de "ancorar em dado específico,
contrastar, terminar com leitura ou ação clara".

**`_cohort_context_block(cohort)` ([prompt_builder.py:44](flutter_app/functions/athlete_insights_module/prompt_builder.py#L44))**

Insere as métricas agregadas da coorte do atleta (perfil parecido)
quando disponíveis, com **regras rígidas de framing**:
- ❌ proibido comparação negativa explícita
- ✅ usar apenas para validação ("você está dentro da média"),
  conquista ("acima do grupo") ou contextualização ("a semana tem
  sido puxada para perfis como o seu")
- ⚖️ se o atleta está PIOR que a média, não mencionar

**`_week_stage_context(now, week_start)` ([prompt_builder.py:110](flutter_app/functions/athlete_insights_module/prompt_builder.py#L110))**

Calcula em que ponto da semana o atleta está (INÍCIO/MEIO/FIM) e
ajusta o tempo verbal recomendado ao LLM.

### 9.3 Glossários

Cada fluxo tem dois glossários:

| Glossário | Conteúdo | Linhas |
|--|--|--|
| `_weekly_glossary()` | Campos de `weekly_load` e `stats/summary` | [227–290](flutter_app/functions/athlete_insights_module/prompt_builder.py#L227-L290) |
| `_weekly_context_glossary()` | Campos calculados de `weekly_context` | [293–326](flutter_app/functions/athlete_insights_module/prompt_builder.py#L293-L326) |
| `_evolution_glossary()` | Campos da série de 12 semanas | [579–602](flutter_app/functions/athlete_insights_module/prompt_builder.py#L579-L602) |
| `_evolution_context_glossary()` | Campos de `evolution_context` | [605–631](flutter_app/functions/athlete_insights_module/prompt_builder.py#L605-L631) |
| `_pre_workout_glossary()` | Campos do treino, perfil, carga, histórico | [848–957](flutter_app/functions/athlete_insights_module/prompt_builder.py#L848-L957) |
| `_pre_workout_context_glossary()` | Campos de `pre_workout_context` | [960–1006](flutter_app/functions/athlete_insights_module/prompt_builder.py#L960-L1006) |

A separação **raw vs. context** é importante porque há campos onde a
mesma informação aparece nas duas formas. Em vez de deixar o LLM
escolher, o `_pre_workout_glossary` foi reescrito para apontar
explicitamente: "esse cálculo JÁ VEM PRONTO em
`pre_workout_context.objectiveTrendSameType`; prefira o campo pré-
calculado em vez de contar manualmente".

### 9.4 Cruzamentos numerados

Cada `create_*_insights_prompt()` tem uma seção
**INSTRUÇÕES DE CRUZAMENTO DE DADOS** com 9 itens. Cada item descreve
uma combinação de variáveis que o LLM deve considerar e dá exemplos
da fala humana esperada.

Exemplo (item 6 do evolution, [prompt_builder.py:737](flutter_app/functions/athlete_insights_module/prompt_builder.py#L737)):

> **Zona ótima de fadiga DESTE atleta (OBRIGATÓRIO se aplicável):** Use
> `evolution_context.peakPerformanceProfile`. Se `status=available`,
> gere OBRIGATORIAMENTE uma informação com chave `zona_otima_rendimento`
> traduzindo a zona em linguagem humana: `low` = 'semanas mais leves',
> `medium` = 'ritmo regular', `high` = 'semanas pesadas'. Esse é o
> insight mais personalizado deste fluxo. Se `status=insufficient_data`,
> não mencione zona.

**A obrigatoriedade do item 6** garante que o atleta sempre receba o
insight mais individualizado quando os dados permitem — sem isso, o
LLM tende a dar prioridade a observações genéricas.

### 9.5 Chaves sugeridas para alertas e informações

Como o schema é `Dict[str, AlertDetail]`, a chave precisa ser
significativa. O prompt provê uma **lista de chaves sugeridas** por
fluxo, mas não obriga seu uso. A lista cresce conforme novos
cruzamentos são adicionados (ex: `taxa_conclusao_baixa`,
`padrao_dia_modalidade_dificil`). Manter as chaves consistentes ao
longo do tempo é importante para análises longitudinais.

### 9.6 Regra temporal específica do pre-workout

O pre-workout tem um problema único: o treino sendo analisado **ainda
não aconteceu**. O LLM, lendo o histórico, tende a confundir tempos
verbais. Para evitar frases como "o treino de hoje foi puxado" (no
contexto pré-treino, isso é absurdo), o prompt tem uma regra explícita
([prompt_builder.py:1085](flutter_app/functions/athlete_insights_module/prompt_builder.py#L1085)):

> O treino abaixo AINDA NÃO ACONTECEU. Fale sempre em
> INTENÇÃO/PREPARO/EXPECTATIVA. NUNCA use passado para o treino de
> hoje (proibido: 'foi puxado', 'não foi concluído', 'deu certo',
> 'rendeu bem'). O passado só vale para o HISTÓRICO do atleta.

### 9.7 Escopo do pré-treino

O pre-workout tem outra restrição rígida ([prompt_builder.py:1083](flutter_app/functions/athlete_insights_module/prompt_builder.py#L1083)):

> ❌ ESTRITAMENTE PROIBIDO falar sobre:
> - Montagem do treino ('esse AMRAP tem volume alto')
> - Sugestões técnicas ao coach
> - Avaliação da progressão programada pelo coach
> - Crítica ou opinião sobre a estrutura/escolhas do treino

A IA do atleta **não opina sobre o treino**. Isso é escopo do coach
(via `ia_module`). A separação é deliberada e importante para o
relacionamento atleta-coach.

---

## 10. Integração com Gemini

### 10.1 Cliente

`_build_llm` ([logic.py:82](flutter_app/functions/athlete_insights_module/logic.py#L82)):

```python
def _build_llm(api_key: str) -> ChatGoogleGenerativeAI:
    return ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.3,
    )
```

**Por que Gemini Flash:** custo/latência ~10x melhor que Pro, com
qualidade suficiente para tarefa textual estruturada. Os campos
quantitativos já vêm prontos do `context_builder`, então o LLM não
precisa raciocinar matematicamente.

**Por que `temperature=0.3`:** queremos variação suficiente para a
saída não ficar mecânica, mas baixa o bastante para que o LLM siga as
regras do prompt (chaves sugeridas, formato JSON, distribuição
alertas/informações). Valores acima de 0.6 começam a "criar" insights
sem base nos dados.

### 10.2 Secret Manager

A chave da API é puxada do GCP Secret Manager a cada invocação
([logic.py:63](flutter_app/functions/athlete_insights_module/logic.py#L63)):

```python
def _get_gemini_api_key() -> str:
    name = f"projects/{project_id}/secrets/{SECRET_ID}/versions/latest"
    client = secretmanager.SecretManagerServiceClient()
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")
```

Trade-off conhecido: uma chamada extra por execução, mas evita
hardcoding e permite rotação sem redeploy.

### 10.3 Parsing da resposta

A saída do LLM passa por `_parse_llm_json` ([logic.py:90](flutter_app/functions/athlete_insights_module/logic.py#L90)) que remove cercas de markdown se o modelo as inclui:

```python
if "```json" in raw:
    return raw.split("```json")[1].split("```")[0].strip()
```

Em seguida, o `PydanticOutputParser` valida o JSON contra o schema
correspondente. Se o LLM produzir um JSON inválido (chaves
faltando, tipo errado), a parse falha e a exceção propaga — o atleta
não recebe insight desta vez, mas também não recebe dado corrompido.
No fluxo pré-treino, a falha de UM atleta não bloqueia os demais
([pre_workout_logic.py:330](flutter_app/functions/athlete_insights_module/pre_workout_logic.py#L330)).

### 10.4 Format instructions

O prompt termina com `parser.get_format_instructions()` —
o LangChain gera automaticamente texto descrevendo o schema esperado.
Isso reforça o "use as chaves abc, retorne só JSON válido".

---

## 11. Persistência no Firestore

Cada fluxo escreve num caminho diferente:

```
users/{uid}/
  insights/
    semanal                         ◄── 1 doc por atleta, sobrescrito a cada semana
    evolucao                        ◄── 1 doc por atleta, sobrescrito a cada 4 dias
    pre_workout/
      items/
        {workoutId}                 ◄── 1 doc por (atleta × treino publicado)
```

A estrutura `pre_workout/items/{workoutId}` é uma sub-coleção: cada
treino publicado vira um documento. O frontend lista apenas treinos
recentes para o atleta, ordenando por `dataTreinoIso`.

**Campos meta sempre presentes:**
- `lastGeneratedAt` (server timestamp) — usado para cache no evolution.
- `weekLabel` (weekly) ou `weeksAnalyzed` (evolution) — contexto da
  janela analisada.
- `workoutId`, `workoutHash`, `historySize`, `hasPattern` (pre-workout)
  — permite ao frontend mostrar warnings ("baseado em apenas N
  treinos").

---

## 12. Validação e telemetria

### 12.1 Validações de elegibilidade

Antes de qualquer chamada ao LLM:

1. **`athlete_ai_enabled(db, uid)`** — checa
   `settings/privacy.aiPersonalizationEnabled` e se a conta está ativa.
2. **Dados mínimos** — pre-workout exige histórico OU carga atual;
   weekly exige `stats/summary` E `weekly_load`; evolution exige
   pelo menos 1 semana de `weekly_load`.

Se o atleta não passa nos filtros, a função retorna um dict
`{"skipped": "<motivo>"}` sem custo de LLM.

### 12.2 Telemetria

Após cada geração bem-sucedida, [logic.py:248](flutter_app/functions/athlete_insights_module/logic.py#L248):

```python
from telemetry_module import record_insight_generated
record_insight_generated(
    'weekly',                              # ou 'evolution', 'preWorkout'
    with_cohort=cohort is not None,
    prompt_chars=len(prompt_text),
    response_chars=len(ai_message.content or ''),
)
```

O `telemetry_module` agrega contadores no Firestore. A chamada é
embrulhada em `try/except: pass` — falha de telemetria nunca quebra a
geração.

### 12.3 Notificações

Igualmente lazy e tolerante a falhas:

```python
from notification_module import create_user_notification
create_user_notification(
    db=db, uid=uid, role="athlete",
    type_="athlete_weekly_insights_ready",
    title="Seu resumo semanal está pronto",
    ...
)
```

Pontos importantes:

- A notificação é gravada em
  `users/{uid}/notifications/{dedupeKey}` **antes** de tentar o push.
  Se o FCM falhar, o atleta ainda vê o card no app.
- O `dedupeKey` evita duplicatas para a mesma semana/treino/janela.

---

## 13. Ferramenta de avaliação local

[flutter_app/functions/tools/evaluate_athlete_insights.py](flutter_app/functions/tools/evaluate_athlete_insights.py) é uma CLI
read-only que monta o prompt real para um atleta real, opcionalmente
chama o Gemini e imprime:

1. **Resumo dos dados** — quais campos do contexto foram populados.
2. **Prompt** — texto completo (truncável).
3. **Resposta crua** do Gemini.
4. **JSON parseado** após validação Pydantic.
5. **Checklist de qualidade** — métricas estáticas:
   - `messageCount`
   - `hasConcreteNumber` — se alguma fala cita número específico
   - `hasTemporalContrast` — se há frases tipo "antes X, agora Y"
   - `genericMarkersFound` — lista de frases-gatilho genéricas
     detectadas (ex: "bom treino", "consegue")
   - `preWorkoutAnchorsFound` — se as falas mencionam movimentos do
     treino do dia (no fluxo pré-treino)

A ferramenta é **não-destrutiva**: não escreve em Firestore, não cria
notificações, não chama webhooks. Pode rodar com `--no-llm` para só
ver o prompt sem gastar chamada Gemini.

Uso típico:

```bash
PYTHONPATH=functions functions/venv/bin/python functions/tools/evaluate_athlete_insights.py \
  --flow all \
  --uid <UID_DO_ATLETA> \
  --workout-id "<ID_DO_TREINO>" \
  --project-id motiva-8b82f \
  --hide-prompt --no-llm
```

Isso é crítico para iteração de prompt: alterações no `prompt_builder`
podem ser inspecionadas em segundos contra um atleta real, sem
deploy.

---

## 14. Decisões de design e trade-offs

### 14.1 Por que três fluxos separados em vez de um genérico

Tentativa inicial considerou um único builder parametrizado por
`flow`. Foi descartado porque:

- Os campos de entrada são fundamentalmente diferentes (histórico de
  treinos do mesmo tipo ≠ série de 12 weekly_loads).
- Os cruzamentos são distintos (ICN crônico no evolution, dia da
  semana no pré-treino).
- Os gatilhos têm naturezas diferentes (debounce ≠ trigger global ≠
  callable).

A duplicação é controlada — `_common_rules`, `_non_obviousness_rule`,
`_few_shot_examples_block`, `_cohort_context_block`,
`_week_stage_context` são compartilhados. O específico fica
no `create_*_insights_prompt`.

### 14.2 Por que pré-computar tanto

Cada campo pré-computado é uma decisão de tirar do LLM um erro
provável. Por exemplo:

- "Calcule a taxa de conclusão" → o LLM erra contagem ou ignora
  registros sem `completed`.
- "Pré-calcular `completionRateSameType`" → o LLM apenas traduz.

O custo: mais código Python para manter. O benefício: insights
factuais consistentes mesmo entre runs do mesmo dia (o LLM tem
variação, a aritmética não).

### 14.3 Por que Pydantic + LangChain em vez de chamada HTTP direta

`PydanticOutputParser` injeta automaticamente as `format_instructions`
no prompt e valida o JSON. Reduz boilerplate e captura erros cedo. O
ganho em legibilidade compensa a dependência adicional.

### 14.4 Por que Gemini Flash em vez de Pro ou Claude

- **Custo:** Flash é ~10x mais barato que Pro. Como rodamos o fluxo
  pre-workout para N atletas por treino publicado, o custo escala
  com a base de usuários.
- **Latência:** Flash responde em 1–3s, viável para o `onCall` de
  evolution.
- **Qualidade observada:** com a pré-computação determinística e o
  prompt detalhado, Flash entrega resultado equivalente a Pro para
  tarefa de tradução estruturada. Decisões qualitativas reais (ler
  contexto, escolher tom) Flash faz bem.

A escolha por Gemini em vez de Claude foi pragmática: integração com
GCP/Firebase, Secret Manager nativo, e a infra do MOTIVA já vive em
GCP.

### 14.5 Cache de 4 dias no evolution

A janela de 12 semanas muda lentamente. Em testes, regerar a cada
abertura adicionava custo significativo sem ganho perceptível para o
atleta. 4 dias é compromisso entre frescor e custo. O parâmetro
`force=true` no `onCall` permite forçar regeneração quando necessário.

### 14.6 Debounce vs. execução imediata no weekly

Execução imediata teria:
- N gerações para um atleta que publicou 5 resultados em sequência.
- Picos no Gemini quando turmas inteiras terminam aula.
- Insights baseados em estado parcial (atleta ainda vai logar mais).

Debounce + jitter resolve os três problemas. A latência adicional
(5–15 min) é aceitável porque o atleta não está sentado esperando o
insight semanal aparecer.

---

## 15. Limitações conhecidas

1. **Sem feedback loop quantitativo do usuário.** A IA não sabe se o
   atleta achou um insight útil ou não. Iteração depende de
   inspeção manual via `evaluate_athlete_insights.py` em casos reais.

2. **Sem validador pós-LLM no fluxo de produção.** A `evaluate_athlete_insights.py`
   calcula `genericMarkersFound` e `hasConcreteNumber` localmente,
   mas essas métricas **não** rodam dentro do fluxo de geração real.
   Um insight com texto genérico passa direto para o Firestore se
   for sintaticamente válido. Plano futuro: replicar a checklist
   dentro do pipeline e gravar via telemetria.

3. **Sem deduplicação cross-flow.** Um atleta pode ler "você bateu PR
   de Burpee" no weekly e novamente no pré-treino do dia seguinte
   (porque um movimento de Burpee aparece no treino). Não é
   redundância obviamente ruim, mas pode parecer repetitivo.

4. **Sem A/B testing de prompt.** Trocar um prompt requer redeploy e
   inspeção manual. Não há infraestrutura para rodar variantes em
   paralelo e comparar.

5. **Custo proporcional à base de atletas no pré-treino.** Para cada
   treino publicado, o fluxo itera atletas elegíveis. Em uma turma
   grande, isso pode ser dezenas de chamadas Gemini num único
   trigger.

6. **Dependência da qualidade dos dados de origem.** Se o atleta não
   registra `effort`, `keyMetrics` ou `category`, vários cruzamentos
   ficam inacessíveis e o insight cai em qualidade. A IA não tenta
   "preencher" — prefere retornar menos insights a inventar.

---

## 16. Possíveis evoluções

Em ordem de retorno esperado:

1. **Telemetria de qualidade no fluxo real.** Calcular `genericMarkersFound`
   e variantes em cada geração e gravar via `telemetry_module`.
   Permite medir drift do LLM ao longo do tempo.

2. **Sanitizador pós-LLM.** Antes de salvar no Firestore: validar que
   chaves usadas batem com `Chaves sugeridas`; vetar jargão técnico
   por regex; detectar contradições básicas (ex: alerta
   `volume_em_queda` enquanto o ICN está subindo).

3. **A/B de prompt no avaliador local.** Estender
   `evaluate_athlete_insights.py` com `--prompt-variant` para rodar
   duas versões e gerar diff.

4. **Regra de diversidade.** "Máximo 1 insight por dimensão (volume,
   modalidade, recuperação, frequência, formato)" para evitar 3
   alertas todos sobre carga.

5. **Few-shot adaptativo por categoria do atleta.** Atletas RX vs.
   Scaled têm padrões diferentes; exemplos contextualizados podem
   melhorar relevância.

6. **Fine-tuning leve ou prompt-tuning.** Após coletar volume
   suficiente de pares (entrada, saída boa), considerar Gemini
   fine-tuning para reduzir tamanho de prompt e custo.

---

## 17. Apêndice — variáveis de ambiente e secrets

| Nome | Tipo | Onde usado | Default |
|--|--|--|--|
| `GCLOUD_PROJECT` | Env | Resolução de URLs e Secret Manager | (inferido do `FIREBASE_CONFIG`) |
| `GEMINI_API_KEY` | Secret Manager | Chave da API Gemini | obrigatório |
| `WEEKLY_INSIGHTS_QUEUE` | Env | Nome da fila Cloud Tasks | `weekly-insights-queue` |
| `WEEKLY_INSIGHTS_DELAY_SEC` | Env | Delay base de debounce | `300` (5 min) |
| `WEEKLY_INSIGHTS_JITTER_SEC` | Env | Jitter máximo por atleta | `600` (10 min) |

Deploy seletivo das funções da IA do atleta:

```bash
firebase deploy --only \
  functions:run_weekly_insights_task,\
  functions:get_athlete_evolution_insights,\
  functions:generate_pre_workout_insights
```

Mudanças em `athlete_insights_module/` **não exigem update do app
mobile** — toda a lógica vive no backend. Atletas e coaches recebem
comportamento novo apenas reabrindo o app.

---

## 18. Resumo executivo

A IA do atleta combina três princípios:

1. **Pré-computação determinística** tira do LLM o que ele faz mal
   (aritmética, datas) e libera capacidade para o que ele faz bem
   (interpretação contextual, redação humana).

2. **Engenharia de prompt em camadas** — regras comuns, glossários
   especializados, cruzamentos numerados, few-shot examples,
   semântica explícita de campos ambíguos — gera saídas consistentes
   sem fine-tuning.

3. **Infraestrutura assíncrona** (Cloud Tasks com debounce e jitter,
   cache no evolution, hash de conteúdo no pré-treino) mantém o
   custo de inferência sob controle e absorve picos naturais (fim de
   aula, publicação em lote de treinos).

O resultado é um sistema onde cada parte tem responsabilidade clara:
o Firestore é a fonte de verdade, o `context_builder` é o calculador,
o `prompt_builder` é o tradutor de regras em linguagem natural, o
Gemini é o redator, e o Pydantic é o validador. Adicionar uma nova
métrica significa adicionar uma função no `context_builder`, uma
linha de glossário, e talvez um item de cruzamento — sem tocar no
restante.
