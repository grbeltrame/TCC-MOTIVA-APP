# Documentação Técnica do Backend — MOTIVA APP

**Trabalho de Conclusão de Curso**
**Versão:** 2.1 (revisada contra o código-fonte e regras Firebase) | **Data:** maio de 2026
**Plataforma:** Google Firebase (Cloud Functions 2ª geração, Firestore, Cloud Storage)
**Linguagem:** Python 3.11+

---

## Sumário

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Stack Tecnológico e Dependências](#2-stack-tecnológico-e-dependências)
3. [Estrutura de Módulos](#3-estrutura-de-módulos)
4. [Modelo de Dados do Firestore](#4-modelo-de-dados-do-firestore)
5. [Ponto de Entrada — main.py](#5-ponto-de-entrada--mainpy)
6. [Módulo de Estatísticas do Atleta](#6-módulo-de-estatísticas-do-atleta-athlete_stats_module)
7. [Módulo de Insights do Atleta](#7-módulo-de-insights-do-atleta-athlete_insights_module)
8. [Módulo de IA do Coach](#8-módulo-de-ia-do-coach-ia_module)
9. [Módulo de Notificações](#9-módulo-de-notificações-notification_module)
10. [Módulo de PDF](#10-módulo-de-pdf-pdf_module)
11. [Módulo de Coorte](#11-módulo-de-coorte-cohort_module)
12. [Módulo de Conta](#12-módulo-de-conta-account_module)
13. [Módulo de Exportação](#13-módulo-de-exportação-export_module)
14. [Módulo de Suporte](#14-módulo-de-suporte-support_module)
15. [Módulo de Telemetria](#15-módulo-de-telemetria-telemetry_module)
16. [Módulo de Configurações do Usuário](#16-módulo-de-configurações-do-usuário-user_settings_module)
17. [Sistema de Debounce e Cloud Tasks](#17-sistema-de-debounce-e-cloud-tasks)
18. [Padrões Arquiteturais e Decisões de Design](#18-padrões-arquiteturais-e-decisões-de-design)
19. [Segurança, Autenticação e Regras Firebase](#19-segurança-autenticação-e-regras-firebase)
20. [Tratamento de Erros](#20-tratamento-de-erros)
21. [Testes](#21-testes)
22. [Variáveis de Ambiente e Configuração](#22-variáveis-de-ambiente-e-configuração)
23. [Implantação](#23-implantação)
24. [Escalabilidade e Custo](#24-escalabilidade-e-custo)
25. [Dívida Técnica e Limitações Conhecidas](#25-dívida-técnica-e-limitações-conhecidas)
26. [Diagrama de Dependências Entre Módulos](#26-diagrama-de-dependências-entre-módulos)

---

## 1. Visão Geral da Arquitetura

O MOTIVA APP é uma plataforma de acompanhamento de treinamento físico voltada para academias de CrossFit. O backend é construído inteiramente sobre o **Firebase**, utilizando uma arquitetura orientada a eventos (*event-driven*) sem servidor (*serverless*) por meio do **Cloud Functions for Firebase (2ª geração)**.

### 1.1 Filosofia Arquitetural

O sistema separa três responsabilidades distintas:

1. **Computação matemática síncrona** — executada imediatamente ao receber um evento. Exemplos: cálculo de carga semanal, monotonia, ICN/ACWR. O atleta vê os dados atualizados em segundos.
2. **Inteligência artificial assíncrona** — disparada de forma diferida, com mecanismo de debounce, para não bloquear o usuário e evitar chamadas excessivas ao modelo de linguagem (LLM).
3. **Comunicação com o usuário** — sistema de notificações in-app + push com deduplicação por chave e respeito às preferências individuais.

### 1.2 Fluxos Gerais de Dados

O sistema possui sete fluxos principais independentes, cada um com trigger, cadeia de processamento e destinatário distintos. Os cinco primeiros concentram os fluxos de análise/IA; os dois últimos cobrem rotinas operacionais de notificação e agregação.

---

#### Fluxo 1 — Insights Semanais do Atleta

**Trigger:** Atleta registra resultado (`users/{uid}/results/{id}` escrito)

```
Atleta registra resultado no app
          │
          ▼
[Firestore Trigger] update_athlete_stats
          │
          ├─► [SÍNCRONO ~2s] athlete_stats_module
          │       Recalcula weekly_load + stats/summary
          │       (ICN, monotonia, strain, cargas diárias)
          │       Persiste em Firestore → atleta já vê dados
          │
          └─► [ASSÍNCRONO] _enqueue_weekly_insights_task
                  Cria Cloud Task com nome determinístico:
                  "weekly-{uid}-{bucket_de_5min}"
                  Delay = 300s base + jitter(uid) de 0 a 600s
                  ──────────────────────────────────────
                  Se atleta publicar N resultados em < 5min:
                  Cloud Tasks recusa N-1 com ALREADY_EXISTS
                  → apenas 1 task executada (debounce)
                          │
                          ▼ (~5–15 min depois)
              [HTTP Handler] run_weekly_insights_task
                          │
                          ▼
              athlete_insights_module.run_weekly_insights_logic
                  1. Verifica AI habilitada (user_settings)
                  2. Lê stats/summary
                  3. Lê weekly_load da semana corrente
                  4. Lê até 30 results da semana
                  5. Lê até 80 results dos últimos 60 dias
                  6. Lê histórico das últimas 4 semanas
                  7. Busca coorte do atleta (cohort_module)
                  8. Constrói contexto (context_builder)
                  9. Constrói prompt (prompt_builder)
                  10. Chama Gemini 2.5 Flash (temperature=0.3)
                  11. Extrai e valida JSON (llm_parser + Pydantic)
                  12. Persiste em users/{uid}/insights/semanal
                  13. Registra telemetria
                          │
                          ▼
              notification_module.create_user_notification
                  Push FCM + doc em users/{uid}/notifications/
                  dedupe_key: "athlete-weekly-insights:{uid}:{weekLabel}"
```

---

#### Fluxo 2 — Insights de Evolução do Atleta (12 semanas)

**Trigger:** Atleta abre a tela de evolução no app Flutter

```
Atleta abre tela de evolução
          │
          ▼
[onCall] get_athlete_evolution_insights
          │
          ├─► Verifica req.auth.uid (nunca confia em uid do cliente)
          │
          ├─► Lê users/{uid}/insights/evolucao.lastGeneratedAt
          │       Se cache < 4 dias: retorna doc existente
          │       com fromCache: true  ──────────────────┐
          │                                               │
          └─► Cache expirado ou force=true:               │
              athlete_insights_module                     │
              .run_evolution_insights_logic               │
                  1. Verifica AI habilitada               │
                  2. Lê stats/summary                     │
                  3. Lê últimas 12 semanas de weekly_load │
                  4. Lê PRs das últimas 12 semanas        │
                     (suporta Timestamp e string ISO)     │
                  5. Agrega estímulos (keyMetrics)        │
                  6. Constrói evolution_context           │
                  7. Busca coorte (cohort_module)         │
                  8. Constrói prompt (12-week analysis)   │
                  9. Chama Gemini 2.5 Flash               │
                  10. Valida JSON (Pydantic EvolutionInsights)
                  11. Persiste em users/{uid}/insights/evolucao
                  12. Registra telemetria                 │
                          │                               │
                          ▼                               │
              notification_module ◄──────────────────────┘
              Push + in-app: "Sua análise de evolução está pronta"
                          │
                          ▼
              Retorna JSON ao app Flutter (fromCache: true/false)
```

---

#### Fluxo 3 — Insights Pré-Treino (por atleta, por treino)

**Trigger:** Coach publica ou atualiza treino (`exercises/{workoutId}` escrito)

```
Coach publica treino no app
          │
          ▼
[Firestore Trigger] generate_pre_workout_insights
          │
          ├─► Verifica status == "publicado"  →  se não, skip
          ├─► Verifica partes != null         →  se não, skip (PDF ainda processando)
          │
          ▼
  Calcula MD5 dos campos relevantes do treino:
  (partes, modalidade, wodType, keyMetrics, dataTreinoIso)
          │
          ├─► Hash igual ao armazenado em _preWorkoutInsightsHash?
          │       SIM: apenas atletas SEM insight existente serão gerados
          │       NÃO: todos os atletas serão (re)gerados
          │
          ▼
  Para cada user em users/ com perfil atleta:
          │
          ├─► athlete_ai_enabled? → se não, skip
          ├─► insight já existe para este workoutId e hash igual? → skip
          │
          └─► Gerar para este atleta:
                  1. Busca até 10 results do mesmo wodType/modalidade
                  2. Busca carga atual (weekly_load via stats/summary)
                  3. Busca PRs das últimas 8 semanas
                  4. Busca perfil detalhado (profiles/athlete)
                  5. Busca histórico por período do dia (até 90 results)
                  6. Busca carga complementar dos últimos 7 dias
                  7. Busca coorte (cohort_module)
                  8. Constrói pre_workout_context (context_builder)
                  9. Chama Gemini 2.5 Flash (instância compartilhada)
                  10. Valida (Pydantic PreWorkoutInsights)
                  11. Persiste em:
                      users/{uid}/insights/pre_workout/items/{workoutId}
                  12. Notifica atleta via push + in-app
          │
          ▼
  Atualiza exercises/{workoutId}._preWorkoutInsightsHash
```

---

#### Fluxo 4 — Análise Diária de Treino para o Coach

**Trigger:** Coach publica ou atualiza treino (`exercises/{workoutId}` escrito)

```
Coach publica treino no app
          │
          ▼
[Firestore Trigger] analyze_workout_with_ai
          │
          ├─► Verifica status == "publicado"  → se não, skip
          ├─► Verifica statusAnalise não em   → se já for "concluida",
          │   {concluida, processando, erro}     "processando" ou "erro", skip
          ├─► Verifica partes != null         → se não, skip (PDF processando)
          │
          ▼
  Marca exercises/{workoutId}.statusAnalise = "processando"
          │
          ├─► Carrega últimos 30 exercises/ ordenados por data desc
          │   Filtra: status=="publicado", exclui workoutId atual
          │   Mantém até 15 → past_workouts
          │
          ├─► Carrega coleção movimentos/ completa → exercise_db
          │   (base de conhecimento: nome, equipamento, músculos, categoria)
          │
          ├─► ia_module._compute_class_context(db)
          │       Collection Group Query: weekly_load da semana atual
          │       Agrega: avgRpeAll, monotony, icnAll, wodDays/otherDays/restDays
          │       Retorna médias da turma para contextualizar o coach
          │
          ▼
  ia_module.create_evaluation_prompt(
      current_workout, past_workouts, exercise_db, class_context
  )
          │
          ▼
  Gemini 2.5 Flash (temperature=0.2)
  → Pydantic TrainingAnalysis:
      summary: {overview, key_metrics[max 3]}
      history_analysis: {weekly, muscle_focus}
      insights: Dict[str, InsightDetail]   (mobilidade, logística, scaling)
      alerts: Dict[str, AlertDetail]       (sobrecarga, fadiga SNC, fadiga turma)
          │
          ▼
  exercises/{workoutId}.analise = structured_analysis
  exercises/{workoutId}.statusAnalise = "concluida"
  exercises/{workoutId}.analisadoEm = SERVER_TIMESTAMP
          │
          ├─► notification_module.notify_all_coaches
          │   Push para todos os coaches:
          │   "Análise do treino pronta"
          │   dedupe_key: "coach-daily-analysis:{workoutId}"
          │
          └─► [ENCADEADO] ia_module.run_cycle_analysis(
                  db, current_workout_with_id, api_key, class_context
              )
              (descrito no Fluxo 5 abaixo)
```

---

#### Fluxo 5 — Análise de Ciclo Mensal para o Coach

**Trigger:** Chamado diretamente ao final do Fluxo 4 (mesma execução, sem trigger adicional)

```
[continuação de run_ai_analysis_logic, após análise diária]
          │
          ▼
  ia_module.run_cycle_analysis(db, current_workout, api_key, class_context)
          │
          ├─► Extrai data do treino → current_month_key (ex: "05-2026")
          │                         → prev_month_key    (ex: "04-2026")
          │
          ├─► Busca exercises/ do mês atual:
          │       where dataTreinoIso >= início_do_mês
          │       where dataTreinoIso <  início_do_próximo_mês
          │   Filtra em memória: status=="publicado"
          │   Adiciona o treino atual → month_workouts
          │
          ├─► Python calcula estatísticas do ciclo:
          │       type_counts: {WODs, LPO, Ginástica, Endurance}
          │       stimulus_counts: de analise.summary.key_metrics
          │         (estímulos definidos pela IA da análise diária)
          │       biggest_stimulus_label: estímulo mais frequente do mês
          │
          ├─► Lê cycles/{prev_month_key} → prev_cycle_data (comparação)
          │
          ▼
  ia_module.create_cycle_prompt(
      month_workouts, prev_cycle_data, month_name, class_context
  )
          │
          ▼
  Gemini 2.5 Flash via chain = llm | cycle_parser (temperature=0.2)
  → Pydantic CycleAnalysis:
      month_year, comparison (CycleComparison),
      recommendations: Dict[str, CycleDetail],
      positives: List[str],
      technical_alerts: Dict[str, CycleDetail],
      overview, quick_alerts: List[str]
          │
          ▼
  cycles/{current_month_key}.set({
      ...cycle_ai_data,            ← dados gerados pela IA
      overview_stats: {trainingsCount, ...},
      trainingTypes: training_types_list,
      stimulus: stimulus_list,
      biggestStimulusLabel: biggest_stimulus_label
  })
          │
          ▼
  notification_module.notify_all_coaches
  Push para todos coaches:
  "Análise de ciclo pronta"
  dedupe_key: "coach-cycle-analysis:{current_month_key}"
```

---

#### Fluxo 6 — Lembretes Horários de Treino

**Trigger:** Cloud Scheduler (`every 1 hours`, America/Sao_Paulo)

```
[Cloud Scheduler] a cada hora
          │
          ▼
  run_notification_reminders →
  notification_module.run_hourly_notification_reminders
          │
          ├─► Verifica janela de execução:
          │       Seg–Dom 9h–18h: ativo
          │       Segunda 8h–12h: ativo (janela extra matinal)
          │       Fora da janela: retorna {skipped: "outside_window"}
          │
          ├─► Verifica se há treino publicado hoje (exercises/)
          │
          └─► Para cada user em users/:
                  │
                  ├─► Perfil atleta:
                  │       target_hour = MD5(uid+tipo+data) % janela
                  │       Se now.hour == target_hour
                  │       E atleta NÃO tem resultado hoje:
                  │           → create_user_notification
                  │             tipo: "athlete_daily_result_reminder"
                  │             (3 variações de copy conforme dia da semana)
                  │
                  └─► Perfil coach:
                          target_hour = MD5(uid+tipo+data) % janela
                          Se now.hour == target_hour
                          E NÃO há treino publicado hoje:
                              → create_user_notification
                                tipo: "coach_missing_training_reminder"
```

---

#### Fluxo 7 — Agregação Diária de Coortes

**Trigger previsto:** Cloud Scheduler externo (3h da manhã) chamando o endpoint HTTP `update_cohort_snapshots`

> **Estado validado no código:** `update_cohort_snapshots` está implementado como `https_fn.on_request`, não como `scheduler_fn.on_schedule`. Portanto, a rotina diária de coortes depende de uma configuração externa do Cloud Scheduler ou de uma chamada manual ao endpoint. Essa configuração não está versionada em `firebase.json` nem em outro arquivo do repositório.

```
[Cloud Scheduler externo 3h00 BRT]
          │
          ▼
  update_cohort_snapshots → cohort_module.update_cohort_snapshots_logic
          │
          ├─► Para cada user em users/:
          │       Lê users/{uid}/profiles/athlete
          │       build_cohort_keys → (l3_key, l2_key)
          │       Verifica atividade: weekly_load nas últimas 4 semanas
          │       Lê weekly_load da semana atual
          │       Agrupa em cohorts_l3[key] e cohorts_l2[key]
          │
          ├─► Para cada coorte com >= 5 atletas:
          │       _aggregate_metrics: médias de ICN, monotonia, RPE, PRs, estímulos
          │       Persiste em cohorts/{key}
          │
          ├─► Coortes com < 5 atletas: NÃO persistidas (privacidade)
          │
          ├─► Limpa cohorts/ estagnadas (existiam antes, sem atletas agora)
          │
          └─► Registra telemetria (record_cohort_job)
          │
          ▼
  Retorna JSON: {athletesTotal, athletesEligible, athletesActive,
                 cohortsPersisted, cohortsTooSmall, ...}
```

---

## 2. Stack Tecnológico e Dependências

### 2.1 Dependências de Produção (`requirements.txt`)

| Pacote | Versão Mínima | Finalidade |
|--------|---------------|------------|
| `firebase-admin` | ≥ 6.0.0 | SDK do Firebase: Firestore, Auth, Messaging, Storage |
| `firebase-functions` | ≥ 0.4.1 | Decorators para Cloud Functions 2ª geração |
| `google-cloud-firestore` | ≥ 2.0.0 | Cliente Firestore |
| `google-cloud-storage` | ≥ 2.0.0 | Acesso ao Cloud Storage para PDFs |
| `google-cloud-secret-manager` | ≥ 2.16.0 | Recuperação da chave GEMINI_API_KEY |
| `google-cloud-tasks` | ≥ 2.16.0 | Fila de tarefas com delay (debounce) |
| `langchain` | ≥ 0.1.0 | Orquestração de chamadas ao LLM |
| `langchain-core` | ≥ 0.1.0 | Parsers Pydantic para saída estruturada |
| `langchain-google-genai` | ≥ 1.0.0 | Integração LangChain ↔ Gemini |
| `pydantic` | ≥ 2.0.0 | Validação e serialização de esquemas |
| `pymupdf` | ≥ 1.24.0 | Extração de texto de PDFs (`import fitz`) |

### 2.2 Serviços Google Cloud Utilizados

| Serviço | Uso |
|---------|-----|
| Cloud Functions (2ª gen) | Serverless compute |
| Firestore | Banco de dados NoSQL |
| Cloud Storage | Armazenamento de PDFs |
| Cloud Tasks | Fila com delay para debounce |
| Cloud Scheduler | Cron jobs gerenciados |
| Secret Manager | Chave GEMINI_API_KEY |
| Firebase Cloud Messaging | Push notifications |
| Firebase Authentication | Autenticação de usuários |

### 2.3 Configuração Firebase do Repositório (`flutter_app/firebase.json`)

O arquivo `firebase.json` versionado define os recursos implantáveis pelo Firebase CLI:

| Recurso | Configuração validada |
|---------|----------------------|
| Firestore Rules | `firestore.rules` |
| Storage Rules | `storage.rules` |
| Functions source | `functions` |
| Functions runtime | `python311` |
| Functions codebase | `default` |
| Arquivos ignorados no deploy | `venv`, `.git`, logs de debug e `__pycache__` |
| Projeto Firebase | `motiva-8b82f` nas configurações Android, iOS, macOS, web e Windows |

> O `firebase.json` não declara fila do Cloud Tasks nem job externo do Cloud Scheduler para coortes. Esses recursos precisam ser criados por configuração de infraestrutura fora do arquivo ou por comandos `gcloud`, conforme descrito na seção de implantação.

### 2.4 Modelo de IA

O modelo de linguagem utilizado é o **Gemini 2.5 Flash** (Google), acessado via LangChain:

```python
# athlete_insights_module — temperatura 0.3 (atleta)
ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0.3)

# ia_module — temperatura 0.2 (coach, mais técnico/determinístico)
ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0.2)
```

A diferença de temperatura reflete o perfil da análise: o coach recebe análises técnicas (menor variabilidade desejada), enquanto o atleta recebe mensagens mais conversacionais.

### 2.5 Justificativa das Escolhas Tecnológicas

#### Firebase

O Firebase foi escolhido por três razões combinadas. A primeira é a familiaridade prévia com a plataforma, o que reduziu o tempo de configuração e permitiu focar no desenvolvimento das funcionalidades. A segunda é a integração nativa com Flutter: o SDK do Firebase para Flutter oferece clientes Firestore, Authentication e Messaging com suporte a listeners em tempo real, eliminando a necessidade de polling periódico — a atualização de dados na tela do atleta acontece via `StreamBuilder` conectado diretamente ao Firestore, sem requisições repetidas ao servidor. A terceira é a arquitetura orientada a eventos: Cloud Functions dispara automaticamente em resposta a escritas no Firestore e uploads no Storage, o que se alinha diretamente com os fluxos do sistema (registro de resultado → recálculo de carga → geração de insights).

#### Gemini 2.5 Flash

O Gemini 2.5 Flash foi escolhido pela disponibilidade de cota generosa no plano gratuito associado a conta universitária do Google, que oferece limites de requisições por minuto e de tokens por minuto significativamente maiores do que os planos gratuitos de APIs concorrentes. Isso permitiu iterar o sistema em produção com usuários reais sem risco de interrupção por esgotamento de cota durante os testes. O modelo também possui desempenho adequado para geração de texto em português com instrução estruturada (JSON), que é o formato exigido pelos fluxos de insights do sistema.

#### LangChain

O LangChain foi escolhido como camada de orquestração entre Python e o Gemini por ser a tecnologia já conhecida para essa classe de problema. Ele oferece dois recursos centrais para o projeto: (1) integração com Pydantic via `PydanticOutputParser`, que permite especificar o schema de saída do LLM como uma classe Python e validar automaticamente a resposta antes de persistir; (2) a sintaxe de pipe LCEL (`llm | parser`), usada no módulo do coach, que encadeia chamada ao modelo e parsing em uma única linha sem boilerplate adicional. A abstração também facilita eventual troca de modelo sem modificar a lógica de orquestração.

#### PyMuPDF (fitz)

O PyMuPDF foi escolhido para o parsing de PDFs pela capacidade de extração de texto com ordenação baseada em blocos posicionais. PDFs de programação de treino costumam ter layouts em múltiplas colunas e cabeçalhos não-lineares — o PyMuPDF extrai os blocos de texto com coordenadas (x, y) e os reordena corretamente, o que não é garantido por alternativas como `pdfminer` ou `pypdf` em layouts complexos. A biblioteca também possui suporte robusto a normalização Unicode via NFKC, necessária para tratar caracteres especiais, travessões tipográficos e aspas curvas que aparecem frequentemente em PDFs gerados por editores de design.

---

## 3. Estrutura de Módulos

```
functions/
├── main.py                          # Ponto de entrada: todas as Cloud Functions
├── requirements.txt
│
├── athlete_stats_module/            # Cálculos matemáticos de carga semanal
│   ├── __init__.py
│   └── logic.py                     # ~680 linhas
│
├── athlete_insights_module/         # IA do ATLETA (3 fluxos)
│   ├── __init__.py
│   ├── logic.py                     # Orquestração weekly + evolution
│   ├── pre_workout_logic.py         # Orquestração pré-treino
│   ├── models.py                    # Esquemas Pydantic de saída
│   ├── prompt_builder.py            # Construção dos prompts (~1.350 linhas)
│   ├── context_builder.py           # Agregação de contexto para LLM
│   └── llm_parser.py                # Extração robusta de JSON do LLM
│
├── ia_module/                       # IA do COACH (análise diária + ciclo)
│   ├── __init__.py
│   ├── logic.py                     # run_ai_analysis_logic + run_cycle_analysis
│   ├── models.py                    # TrainingAnalysis + CycleAnalysis (Pydantic)
│   └── prompt_builder.py            # create_evaluation_prompt + create_cycle_prompt
│
├── notification_module/             # Notificações in-app + push FCM
│   ├── __init__.py
│   └── logic.py
│
├── pdf_module/                      # Parser de PDFs de treino
│   ├── __init__.py
│   └── parser.py                    # ~750 linhas
│
├── cohort_module/                   # Análise comparativa de coortes
│   ├── __init__.py
│   ├── aggregation.py               # Job diário de snapshot
│   ├── bucketization.py             # Normalização de perfil → chave de coorte
│   └── matching.py                  # Busca da coorte de um atleta
│
├── account_module/                  # Ciclo de vida da conta
│   ├── __init__.py
│   └── logic.py
│
├── export_module/                   # Exportação recursiva de dados (LGPD)
│   ├── __init__.py
│   └── logic.py
│
├── support_module/                  # Tickets de suporte via mail collection
│   ├── __init__.py
│   └── logic.py
│
├── telemetry_module/                # Contadores diários de uso da IA
│   ├── __init__.py
│   └── logic.py
│
├── user_settings_module/            # Preferências e status de conta
│   ├── __init__.py
│   └── logic.py
│
└── tests/
    ├── test_athlete_insight_output_contract.py
    ├── test_insight_context_builder.py
    ├── test_notification_module.py
    ├── test_pdf_parser.py
    ├── test_pre_workout_logic.py
    ├── test_prompt.py
    ├── test_prompt_enrichment.py
    ├── test_user_settings_module.py
    └── test_account_support_export_modules.py
```

---

## 4. Modelo de Dados do Firestore

### 4.1 Coleção `users/{uid}`

Documento raiz do usuário:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `profile` | `string` | `athlete`, `coach`, `intern`, `athleteCoach`, `athleteIntern`, `admin` |
| `accountStatus` | `string` | `active` ou `disabled` |
| `email` | `string` | E-mail do usuário |
| `name` | `string` | Nome do usuário |
| `disabledAt` | `Timestamp` | Data de desativação (se aplicável) |
| `reactivatedAt` | `Timestamp` | Data de reativação (se aplicável) |
| `updatedAt` | `Timestamp` | Última atualização |

#### Subcoleção `users/{uid}/results/{resultId}`

Registros de treino do atleta. O `doc_id` segue a convenção:
- `{YYYY-MM-DD}_{tipo}` para treinos regulares
- `{YYYY-MM-DD}_REST` para dias de descanso
- `{YYYY-MM-DD}_OTHER_{id}` para atividades externas

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `date` | `string` | Formato `YYYY-MM-DD` |
| `effort` | `number` | RPE (1–10) |
| `modalidade` | `string` | `AMRAP`, `FOR TIME`, `EMOM`, etc. |
| `wodType` | `string` | `WOD`, `LPO`, `GINÁSTICA`, `ENDURANCE` |
| `completed` | `boolean` | Semântica varia por modalidade |
| `forTimeSec` | `number` | Tempo total em segundos (FOR TIME concluído) |
| `amrapRounds` | `number` | Rounds completos (AMRAP) |
| `amrapReps` | `number` | Reps do round parcial (AMRAP) |
| `trainingTime` | `string` | Horário do treino `HH:MM` |
| `trainingDocId` | `string` | Referência a `exercises/{id}` (null para treinos pessoais) |
| `keyMetrics` | `array<string>` | Estímulos: `["Força", "Resistência"]` |
| `category` | `string` | `RX`, `Scaled`, `Intermediário` |
| `durationMinutes` | `number` | Duração (apenas treinos `_OTHER`) |

#### Subcoleção `users/{uid}/prs/{prId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `date` | `string` ou `Timestamp` | Retrocompatibilidade: ambos suportados |
| `movementName` | `string` | Ex.: `Back Squat` |
| `value` | `number` | Valor do PR |
| `unit` | `string` | `kg`, `reps`, `segundos` |
| `prType` | `string` | `1RM`, `max_reps`, `time` |
| `weekLabel` | `string` | Label da semana |

#### Subcoleção `users/{uid}/stats/summary`

Documento único atualizado a cada evento de resultado. Combina dados all-time, mês atual e semana atual com atalhos para `weekly_load` evitando segunda query:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `totalTrainingDays` | `number` | Total histórico |
| `averageEffortAllTime` | `number` | RPE médio histórico |
| `currentMonthTrainingDays` | `number` | Dias treinados no mês |
| `averageEffortCurrentMonth` | `number` | RPE médio no mês |
| `currentWeekTrainingDays` | `number` | Dias treinados na semana |
| `averageEffortCurrentWeek` | `number` | RPE médio na semana |
| `currentWeekStimuli` | `map<string,number>` | Estímulos da semana atual |
| `currentWeekCalendar` | `map<string,string>` | Estado por dia: `wod`/`rest`/`other` |
| `weeklyLoadCrossfit` | `number` | Carga de WODs da semana (AU) |
| `weeklyLoadAll` | `number` | Carga total da semana |
| `weeklyLoadLabel` | `string` | Label da semana corrente |
| `weeklyICN` | `number` | ICN atual |
| `weeklyBaselineType` | `string` | `cold_start`, `partial_N_weeks`, `historical_4_weeks` |
| `weeklyCargaCronica` | `number` | Média carga das últimas ≤4 semanas |
| `weekStart` / `weekEnd` | `string` | Limites da semana corrente |
| `monthStart` | `string` | Início do mês corrente |
| `updatedAt` | `Timestamp` | `SERVER_TIMESTAMP` |

#### Subcoleção `users/{uid}/weekly_load/{weekLabel}`

Um documento por semana. `weekLabel` segue a convenção DOM→SAB do sistema (ex.: `2026-W20`), não o padrão ISO 8601 (SEG→DOM):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `weekLabel` | `string` | `YYYY-Www` (convenção DOM→SAB) |
| `weekStart` / `weekEnd` | `string` | Datas da semana |
| `totalLoadCrossfit` | `number` | Carga de WODs (AU) |
| `totalLoadOther` | `number` | Carga de atividades externas |
| `totalLoadAll` | `number` | Soma total |
| `icnAll` | `number\|null` | ICN [0–150]; no cold start o código grava `50.0` como ponto neutro |
| `icnCrossfit` | `number\|null` | ICN apenas de WODs; no cold start o código grava `50.0` |
| `cargaCronica` | `number\|null` | Média das ≤4 semanas anteriores |
| `acwrRaw` | `number\|null` | Razão aguda/crônica bruta |
| `baselineType` | `string` | `cold_start`, `partial_N_weeks`, `historical_4_weeks` |
| `avgRpeCrossfit` | `number` | RPE médio de WODs |
| `avgRpeAll` | `number` | RPE médio total |
| `wodDays` | `number` | Dias com WOD oficial |
| `otherDays` | `number` | Dias com atividade externa |
| `restDays` | `number` | Dias de descanso explícito |
| `monotony` | `number` | Indicador Foster (mean/stdev das cargas diárias) |
| `strain` | `number` | totalLoadAll × monotony |
| `restRatio` | `number` | restDays / 7 |
| `prsCount` | `number` | PRs batidos na semana |
| `dailyLoadsCrossfit` | `map<string,number>` | Carga por dia (0 = sem treino) |
| `dailyLoadsOther` | `map<string,number>` | Carga externa por dia |
| `stimuli` | `map<string,number>` | Contagem de estímulos |
| `updatedAt` | `Timestamp` | `SERVER_TIMESTAMP` |

> **Correção validada no código:** embora o ICN conceitual dependa de carga crônica histórica, a implementação não grava `null` no primeiro contato. Quando não há semanas anteriores, `baselineType` fica `cold_start` e `icnAll`/`icnCrossfit` recebem `50.0`, indicando valor neutro sem comparação histórica real.

#### Subcoleção `users/{uid}/insights/`

| Documento | Conteúdo | Atualização |
|-----------|----------|-------------|
| `semanal` | `{alertas, informacoes, weekLabel, generatedFor, lastGeneratedAt}` | Após debounce de 5–15 min |
| `evolucao` | `{alertas, informacoes, weeksAnalyzed, lastGeneratedAt, fromCache}` | On-demand, cache 4 dias |
| `pre_workout` | Documento raiz sem campos diretos — dados em subcoleção `items/` | Ao publicar treino |

#### Subcoleção `users/{uid}/insights/pre_workout/items/{workoutId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `alertas` | `map` | Alertas pré-treino |
| `informacoes` | `map` | Informações positivas |
| `workoutId` | `string` | ID do treino |
| `workoutHash` | `string` | MD5 dos campos relevantes |
| `historySize` | `number` | Qtd de results históricos usados |
| `hasPattern` | `boolean` | Tem >= 5 registros do mesmo tipo |
| `generatedAt` | `Timestamp` | `SERVER_TIMESTAMP` |

#### Subcoleção `users/{uid}/settings/`

| Documento | Campos relevantes |
|-----------|-------------------|
| `privacy` | `aiPersonalizationEnabled: bool` (padrão: `true`) |
| `athlete` | `weeklyInsights`, `evolutionInsights`, `preWorkoutInsights`, `trainingReminders` (bool, padrão: `true`) |
| `coach` | `dailyTrainingAnalysis`, `cycleAnalysis`, `missingTrainingReminder` (bool, padrão: `true`) |

#### Subcoleção `users/{uid}/notifications/{notifId}`

O `doc_id` é o `dedupe_key` sanitizado (barras e caracteres especiais → `_`):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `role` | `string` | `athlete` ou `coach` |
| `type` | `string` | Tipo da notificação |
| `title` / `body` | `string` | Conteúdo |
| `status` | `string` | `unread` ou `read` |
| `createdAt` | `Timestamp` | Criação |
| `expiresAt` | `datetime` | createdAt + 7 dias |
| `readAt` | `Timestamp\|null` | Data de leitura |
| `dedupeKey` | `string` | Chave usada como doc_id |
| `routeName` | `string` | Rota Flutter (ex.: `/athlete_insight`) |
| `routeArgs` | `map` | Parâmetros da rota |
| `sourceId` | `string` | weekLabel, workoutId, etc. |

#### Subcoleção `users/{uid}/profiles/athlete`

Perfil detalhado opcional do atleta:

| Campo | Tipo | Valores válidos |
|-------|------|----------------|
| `category` | `string` | `Iniciante`, `Scaled`, `Intermediário`, `RX`, `Elite` |
| `gender` | `string` | `Homem`, `Mulher`, `Outro` |
| `practiceYears` | `string` | `Menos de 1 ano`, `Entre 1 e 3 anos`, `Entre 3 e 5 anos`, `Mais de 5 anos` |
| `weight` | `number` | Peso em kg |
| `height` | `number` | Altura em cm |

#### Subcoleção `users/{uid}/profiles/coach`

Perfil profissional do coach, persistido separadamente do documento raiz para isolar dados específicos da função. Lido e gravado pelo `CoachProfileService` via dois documentos em paralelo:

- **Campos compartilhados** (gravados em `users/{uid}`): `name`, `birthDate`, `photoURL` — comuns a qualquer perfil.
- **Campos exclusivos do coach** (gravados em `users/{uid}/profiles/coach`):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cref` | `string\|null` | Número de registro no CREF (opcional) |
| `certifications` | `array<string>` | Lista de certificações (ex.: `CrossFit L1`, `Bacharel em Educação Física`) |
| `specialties` | `array<string>` | Lista de especialidades (ex.: `LPO`, `Planejamento Estratégico`, `Mobilidade`) |

As especialidades são organizadas em categorias no app Flutter (`Estratégia e Planejamento`, `Técnica e Execução`, `Mobilidade e Prevenção`, `Motivação e Psicologia`, `Saúde e Bem-estar`) mas salvas como lista plana no Firestore. Itens personalizados que não pertencem ao catálogo padrão são agrupados em `Outras Especialidades` no app.

> **Nota:** o perfil do coach não é utilizado pelo backend Python para geração de análises de IA na versão atual. Ele é lido e exibido diretamente pelo app Flutter.

#### Subcoleção `users/{uid}/notificationTokens/{token}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `token` | `string` | FCM device token |
| `enabled` | `boolean` | Se o token está ativo |

---

### 4.2 Coleção `exercises/{workoutId}`

Treinos publicados pelo coach:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status` | `string` | `rascunho` ou `publicado` no código de importação; as rules também tratam `processado` como legível para atletas |
| `statusAnalise` | `string` | `aguardando_publicacao`, `pendente`, `processando`, `concluida`, `erro` ou ausente |
| `dataTreinoIso` | `string` | `YYYY-MM-DD` |
| `dataDoTreinoTexto` | `string` | Data textual extraída do PDF, ex.: `10 MARCO` |
| `diaDaSemana` | `string` | Dia textual extraído do PDF |
| `wodType` | `string` | `WOD`, `LPO`, `GINÁSTICA`, `ENDURANCE` |
| `modalidade` | `string` | Formato do WOD principal |
| `duracaoMinutos` | `number` | Duração prevista em minutos |
| `titulo` | `string` | Título do treino |
| `keyMetrics` | `array<string>` | Estímulos definidos pelo coach |
| `materiais` | `array<string>` | Materiais extraídos do PDF |
| `partes` | `map` | Estrutura do treino por seção (ver abaixo) |
| `analise` | `map` | Análise gerada pelo `ia_module` (`TrainingAnalysis`) |
| `analisadoEm` | `Timestamp` | Data de conclusão da análise |
| `erroMsg` | `string` | Mensagem de erro (se statusAnalise=="erro") |
| `createdByUid` | `string` | UID do coach criador |
| `uploadedBy` | `string` | UID lido do metadata do PDF no Storage |
| `boxId` | `string` | Identificador do box, lido do metadata do PDF |
| `arquivoFonte` / `sourcePdfPath` | `string` | Caminho do PDF no Storage |
| `sourcePage` | `number` | Página do PDF mensal que originou o treino |
| `importBatchId` | `string` | UUID da importação do PDF |
| `criadoEm` | `Timestamp` | Timestamp de criação/importação |
| `_preWorkoutInsightsHash` | `string` | MD5 de deduplicação (pré-treino) |
| `_preWorkoutInsightsGeneratedAt` | `Timestamp` | Última geração de pré-treino |

> **Comportamento validado do parser PDF:** um PDF novo gera documentos como `rascunho` e `statusAnalise="aguardando_publicacao"`. Apenas se o documento já existia publicado ele permanece `publicado` e volta com `statusAnalise="pendente"`, permitindo nova análise após atualização do conteúdo.

**Estrutura de `partes`** — cada seção é um objeto com os seguintes campos gerados pelo parser PDF:

```json
{
  "WARM UP": {
    "secao":          "WARM UP",
    "modalidade":     null,
    "rounds":         null,
    "duracaoMinutos": 10,
    "nomeWod":        null,
    "exercicios": [
      {"raw": "3 Rounds", "kind": "exercise", "quantidade": 3, "nome": "Rounds", "unidade": "rounds", "cargaRx": null, "cargaScaled": null},
      {"raw": "10 Pull-up", "kind": "exercise", "quantidade": 10, "nome": "Pull-up", "unidade": "reps", "cargaRx": null, "cargaScaled": null}
    ],
    "observacoes":    null
  },
  "WOD": {
    "secao":          "WOD",
    "modalidade":     "FOR TIME",
    "rounds":         null,
    "duracaoMinutos": 20,
    "nomeWod":        "SKY IS THE LIMIT",
    "exercicios": [
      {"raw": "21 Thruster (43Kg|30Kg)", "kind": "exercise", "quantidade": 21, "nome": "Thruster",
       "unidade": "reps", "cargaRx": "43Kg", "cargaScaled": "30Kg"}
    ],
    "observacoes":    "Manter respiração controlada nas descidas."
  }
}
```

> **Campos notáveis:** `nomeWod` é extraído do cabeçalho da seção quando há separador (`"WOD - SKY IS THE LIMIT"` → `nomeWod="SKY IS THE LIMIT"`). O campo `rounds` é preenchido quando a modalidade é `N ROUNDS` ou `N ROUNDS FOR TIME`. O campo `observacoes` captura o bloco `OBSERVAÇÃO:` presente no texto do PDF antes do próximo cabeçalho ou fim do conteúdo.

---

### 4.3 Coleção `cycles/{monthKey}`

Análise de ciclo mensal gerada pelo `ia_module`. Chave no formato `MM-YYYY` (ex.: `05-2026`):

| Campo | Tipo | Origem |
|-------|------|--------|
| `month_year` | `string` | IA |
| `comparison` | `map` | IA — `{progression, distribution, variation, effort}` |
| `recommendations` | `map<string,{description}>` | IA |
| `positives` | `array<string>` | IA |
| `technical_alerts` | `map<string,{description}>` | IA |
| `overview` | `string` | IA |
| `quick_alerts` | `array<string>` | IA — 3 a 5 alertas rápidos |
| `overview_stats` | `map` | Python — `{trainingsCount, updatedAt, registrosCount, activeStudentsPct}` |
| `trainingTypes` | `array` | Python — `[{typeLabel, typeKey, count}]` |
| `stimulus` | `array` | Python — `[{stimulus, count}]` |
| `biggestStimulusLabel` | `string` | Python — estímulo dominante do mês |

> **Nota:** `registrosCount` e `activeStudentsPct` estão marcados como WIP no código-fonte e retornam `0` na versão atual.

---

### 4.4 Coleção `cohorts/{cohortKey}`

Snapshots de coortes de atletas com perfil semelhante. Chave no formato `{CATEGORY}_{GENDER}_{BUCKET}` (level 3) ou `{CATEGORY}_{GENDER}` (level 2):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cohortKey` | `string` | Ex.: `RX_M_1-3y` ou `RX_M` |
| `level` | `number` | `3` (com experiência) ou `2` (fallback) |
| `category` | `string` | Categoria normalizada |
| `gender` | `string` | `M` ou `F` |
| `experienceBucket` | `string\|null` | `lt1y`, `1-3y`, `3-5y`, `gt5y` ou null |
| `athleteCount` | `number` | Atletas na coorte (mínimo 5) |
| `weekLabel` | `string` | Semana do snapshot |
| `metrics` | `map` | Médias: `avgWeeklyICN`, `avgMonotony`, `avgRpeAll`, `avgPrsPerWeek`, `avgCargaCronica`, `topStimuli` |
| `minCohortSize` | `number` | 5 (constante documentada no snapshot) |
| `updatedAt` | `Timestamp` | `SERVER_TIMESTAMP` |

---

### 4.5 Coleção `movimentos/{id}`

Base de conhecimento de exercícios utilizada pelo `ia_module` para sugestões de scaling e variações:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `displayName` | `string` | Nome de exibição |
| `name` | `string` | Nome alternativo |
| `equipment` | `array<string>` | Equipamentos necessários |
| `primaryMuscles` | `array<string>` | Músculos primários |
| `categories` | `array<string>` | Categorias do movimento |

---

### 4.6 Coleção `supportTickets/{ticketId}`

Tickets de suporte criados pelos usuários:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `uid` | `string` | UID do usuário |
| `userEmail` | `string` | E-mail (lido de `users/{uid}`) |
| `userName` | `string` | Nome (lido de `users/{uid}`) |
| `type` | `string` | `support`, `feedback`, `bug_report` |
| `message` | `string` | Mensagem do usuário |
| `steps` | `string\|null` | Passos para reprodução (bug_report) |
| `rating` | `number\|null` | Avaliação do usuário |
| `status` | `string` | `open` |
| `createdAt` | `Timestamp` | `SERVER_TIMESTAMP` |

---

### 4.7 Coleção `mail/{ticketId}`

Usada pelo **Firebase Extension "Trigger Email"**. Ao criar um documento nesta coleção, a extensão envia automaticamente o e-mail:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `to` | `array<string>` | Destinatários (e-mail de suporte) |
| `message.subject` | `string` | Assunto (varia por tipo de ticket) |
| `message.text` | `string` | Corpo do e-mail em texto plano |
| `createdAt` | `Timestamp` | `SERVER_TIMESTAMP` |

> O `doc_id` é o mesmo que o `ticketId` de `supportTickets/` para rastreabilidade.

---

### 4.8 Coleção `telemetry/{YYYY-MM-DD}`

Um documento por dia. Contadores atômicos de uso da IA:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `date` | `string` | Data no formato `YYYY-MM-DD` |
| `insights.weekly.total` | `number` | Total de gerações semanais no dia |
| `insights.weekly.generated` | `number` | Geradas com sucesso |
| `insights.weekly.skipped` | `number` | Puladas (IA desabilitada, sem dados) |
| `insights.weekly.failed` | `number` | Falhas (erro do LLM ou parse) |
| `insights.weekly.from_cache` | `number` | Servidas do cache |
| `insights.weekly.withCohort` | `number` | Com contexto de coorte |
| `insights.weekly.reasons.{motivo}` | `number` | Contagem por motivo de skip |
| `insights.evolution.*` | `number` | Mesma estrutura para evolução |
| `insights.preWorkout.*` | `number` | Mesma estrutura para pré-treino |
| `estimatedTokens.prompt` | `number` | Estimativa de tokens de prompt (chars / 4) |
| `estimatedTokens.response` | `number` | Estimativa de tokens de resposta |
| `cohortJobs.runs` | `number` | Execuções do job de coorte |
| `cohortJobs.cohortsPersistedSum` | `number` | Total de coortes persistidas |
| `updatedAt` | `Timestamp` | `SERVER_TIMESTAMP` |

> Todas as escritas usam `FieldValue.increment` (Firestore atomic increment) para evitar conflitos em escritas concorrentes — múltiplas Cloud Functions podem atualizar o mesmo documento diário simultaneamente.

---

## 5. Ponto de Entrada — `main.py`

### 5.1 Inicialização

```python
if not firebase_admin._apps:
    firebase_admin.initialize_app()
```

A guarda evita reinicialização em hot-reloads e testes. Usa Application Default Credentials (ADC), injetadas automaticamente no ambiente do Cloud Functions.

### 5.2 Configurações Globais de Cloud Tasks

| Constante | Padrão | Env var | Descrição |
|-----------|--------|---------|-----------|
| `_REGION` | `us-central1` | — | Região de todas as funções |
| `_TASK_QUEUE_ID` | `weekly-insights-queue` | `WEEKLY_INSIGHTS_QUEUE` | Fila Cloud Tasks |
| `_TASK_DELAY_SECONDS` | `300` | `WEEKLY_INSIGHTS_DELAY_SEC` | Delay base (5 min) |
| `_TASK_MAX_JITTER_SECONDS` | `600` | `WEEKLY_INSIGHTS_JITTER_SEC` | Jitter máximo por UID (10 min) |

### 5.3 Catálogo Completo de Cloud Functions

#### Triggers de Firestore

| Função | Documento | Memória | Timeout | Ação |
|--------|-----------|---------|---------|------|
| `update_athlete_stats` | `users/{uid}/results/{resultId}` | 256 MB | 60 s | Stats + enfileira Cloud Task |
| `update_athlete_stats_on_pr` | `users/{uid}/prs/{prId}` | 256 MB | 60 s | Recalcula stats; não enfileira insights semanais (ver nota abaixo) |
| `analyze_workout_with_ai` | `exercises/{workoutId}` | 512 MB | padrão | Análise diária + ciclo mensal (coach) |
| `generate_pre_workout_insights` | `exercises/{workoutId}` | 512 MB | 540 s | Insights pré-treino para todos os atletas |

> **Nota sobre `update_athlete_stats_on_pr`:** esta trigger recalcula `stats/summary` e `weekly_load` mas **não** enfileira uma nova tarefa de insights semanais. O motivo é intencional: um PR representa um recorde pessoal registrado de forma independente, não uma nova sessão de treino. A carga semanal já foi calculada quando o atleta registrou o resultado do WOD correspondente — um PR adicional sobre o mesmo treino não altera o volume da semana, apenas o histórico de máximos do atleta. Gerar insights a cada PR criaria redundância desnecessária e chamadas extras ao LLM para dados cujo componente de carga já foi capturado anteriormente. Os PRs das últimas 12 semanas são consumidos pelos fluxos de insights na próxima geração agendada.

> **Nota:** `analyze_workout_with_ai` e `generate_pre_workout_insights` monitoram o mesmo caminho `exercises/{workoutId}`. São funções independentes com lógicas distintas — a primeira fala com o coach, a segunda com os atletas.

#### Triggers de Storage

| Função | Evento | Memória | Timeout |
|--------|--------|---------|---------|
| `process_workout_pdf` | `on_object_finalized` | 512 MB | 60 s |

#### Endpoints HTTP (`on_request`)

| Função | Memória | Timeout | Caller |
|--------|---------|---------|--------|
| `update_cohort_snapshots` | 512 MB | 540 s | Cloud Scheduler externo ou chamada manual |
| `run_weekly_insights_task` | 512 MB | 120 s | Cloud Tasks (após debounce) |

> **Importante:** ambos os endpoints HTTP são `https_fn.on_request`. No código atual, eles não validam método HTTP, token OIDC, App Check, header interno ou segredo compartilhado. A proteção depende de configuração IAM/infraestrutura fora do arquivo ou deve ser adicionada no código antes de produção.

#### Jobs Agendados (`on_schedule`)

| Função | Schedule | Timezone | Memória | Timeout |
|--------|----------|----------|---------|---------|
| `run_notification_reminders` | `every 1 hours` | America/Sao_Paulo | 256 MB | 540 s |
| `cleanup_expired_notifications` | `30 3 * * *` | America/Sao_Paulo | 256 MB | 540 s |

#### Funções Callable (`on_call` — requerem autenticação Firebase)

| Função | Memória | Timeout | Secrets | Ação |
|--------|---------|---------|---------|------|
| `get_athlete_evolution_insights` | 512 MB | 120 s | — | Cache 4 dias de evolução |
| `deactivate_current_user_account` | 512 MB | 60 s | — | Soft-disable |
| `reactivate_current_user_account` | 512 MB | 60 s | — | Reativa conta |
| `delete_current_user_account` | 512 MB | 540 s | — | Exclui conta + dados (LGPD) |
| `export_user_data` | 512 MB | 120 s | — | Exporta árvore completa (LGPD) |
| `submit_support_ticket` | 512 MB | 60 s | `SUPPORT_EMAIL` | Cria ticket de suporte |

### 5.4 Contratos de Endpoints e Funções Callable

#### `run_weekly_insights_task` (`on_request`)

| Item | Contrato atual |
|------|----------------|
| Método esperado | `POST` |
| Body | `{"uid": "<firebase_uid>"}` |
| Sucesso | HTTP 200, corpo `"ok"` |
| Erro de entrada | HTTP 400, corpo `"missing uid"` |
| Erro interno | HTTP 500, corpo textual `error: ...` |
| Autenticação no código | Nenhuma validação explícita |

#### `update_cohort_snapshots` (`on_request`)

| Item | Contrato atual |
|------|----------------|
| Método esperado | `POST` quando chamado por Scheduler, embora o código não restrinja método |
| Body | Não utilizado |
| Sucesso | HTTP 200 com JSON do job (`athletesTotal`, `athletesEligible`, `athletesActive`, `cohortsPersisted`, etc.) |
| Erro interno | HTTP 500, corpo textual `error: ...` |
| Autenticação no código | Nenhuma validação explícita |

#### `get_athlete_evolution_insights` (`on_call`)

| Item | Contrato atual |
|------|----------------|
| Auth | Requer `req.auth.uid` |
| Payload | `{ "force": true/false }` opcional |
| Sucesso | JSON dos insights de evolução; inclui `fromCache` no retorno ao app |
| Erros | `UNAUTHENTICATED` sem login; `INTERNAL` em exceções |

#### Callables de conta e dados

| Função | Payload | Resposta | Observação |
|--------|---------|----------|------------|
| `deactivate_current_user_account` | vazio | `{"status": "disabled"}` | Usa `req.auth.uid` |
| `reactivate_current_user_account` | vazio | `{"status": "active"}` | Usa `req.auth.uid` |
| `delete_current_user_account` | vazio | `{"deletedDocs": n, "authDeleted": true}` | Exclui árvore do usuário, exercícios criados e Auth user |
| `export_user_data` | vazio | árvore JSON de `users/{uid}` + exercícios criados | Retorna payload diretamente, sem arquivo externo |
| `submit_support_ticket` | `{type, message, steps?, rating?}` | `{"ticketId": "<id>"}` | `message` é obrigatório; `type` inválido vira `support` |

---

## 6. Módulo de Estatísticas do Atleta (`athlete_stats_module`)

### 6.1 Objetivo

Núcleo matemático do sistema. Transforma registros brutos de treino em métricas quantitativas de carga. Executa de forma **síncrona** a cada evento de resultado — o atleta vê os números atualizados em segundos.

### 6.2 Fundamentação Científica

#### Session-RPE (Foster et al., 2001)

```
Carga (AU) = Esforço (RPE 1–10) × Duração (minutos)
```

Quantifica carga interna em Unidades Arbitrárias (AU). A subjetividade é intencional: um RPE 9 de iniciante representa o mesmo estresse relativo que um RPE 9 de elite.

#### ACWR / ICN (Gabbett, 2016)

```
ACWR = Carga Aguda (semana atual) / Carga Crônica (média das últimas ≤4 semanas)
ICN  = ACWR × 50, clamped em [0, 150]
```

| ACWR | ICN | Interpretação |
|------|-----|---------------|
| < 0.8 | < 40 | Subcarga / destreino |
| 0.8–1.3 | 40–65 | Zona ótima / sustentável |
| 1.3–1.5 | 65–75 | Alerta leve de aumento brusco |
| > 1.5 | > 75 | Alto risco (~2× chance de lesão, segundo Gabbett) |

A normalização para [0, 150] com ponto central em 50 (ACWR=1.0) facilita a interpretação pelo LLM.

Na implementação atual, semanas sem histórico anterior não recebem `null` como ICN. O código usa `icnAll=50.0` e `icnCrossfit=50.0` com `baselineType="cold_start"`. Esse valor deve ser interpretado como sentinela neutro, não como evidência de carga crônica normalizada.

#### Monotonia e Strain (Foster, 2001)

```python
valores  = list(daily_all.values())   # 7 dias, incluindo zeros
media    = statistics.mean(valores)
desvio   = statistics.pstdev(valores)
monotony = round(media / desvio, 3) if desvio > 0 else 0.0
strain   = round(total_load_all * monotony, 1)
```

Os 7 dias são **pré-inicializados com 0.0** antes de receber os valores reais. Isso garante que dias sem treino contribuam com zero na média, não sejam ignorados — o que tornaria qualquer semana com dias de descanso artificialmente uniforme.

**Referências de monotonia:**
- < 1.0 — treino bem variado
- 1.0–1.5 — adequado
- > 1.5 — pouca variação (risco de overtraining)
- > 2.0 — muito repetitivo

### 6.3 Função Principal: `update_athlete_stats_logic(event)`

**Arquivo:** `athlete_stats_module/logic.py:451`

**Por que recalcula tudo em vez de calcular incrementalmente?**

A carga crônica da semana atual depende das 4 semanas anteriores. Se o atleta edita um resultado de 3 semanas atrás, o efeito deve cascatear pelas semanas subsequentes. Calcular incrementalmente exigiria identificar quais semanas foram afetadas e recalculá-las em cascata — complexidade similar ao recálculo completo, porém mais frágil. A decisão foi recalcular toda a série cronologicamente a cada evento.

**Fluxo completo:**

```
1.  uid ← event.params.uid
2.  all_docs ← results_ref.stream()       (todos os results do atleta)
3.  Calcular limites temporais atuais (semana, mês)
4.  Agrupar all_docs por semana → docs_by_week
5.  Acumular all_efforts, month_efforts, week_efforts, week_calendar
6.  prs_per_week ← prs_ref.stream() agrupados por semana
    (suporta date como Timestamp ou string ISO)
7.  Garantir bucket para semana atual mesmo sem results
8.  Para label em sorted(docs_by_week.keys()):   ← ORDEM CRONOLÓGICA ASCENDENTE
        prev_loads ← totalLoadAll das ≤4 semanas anteriores já computadas
        computed_loads[label] ← _compute_week_load_doc(...)
9.  Persistir todos weekly_load docs
10. Apagar weekly_load órfãos (semanas que sumiram dos results)
11. Construir e persistir stats/summary
```

**Por que ordenação cronológica ascendente é crítica (passo 8):**
O ICN da semana N usa as cargas já calculadas das semanas N-1, N-2, N-3, N-4. Se processássemos em ordem descendente, as semanas mais recentes não teriam as anteriores calculadas ainda.

### 6.4 Cálculo de Duração por Modalidade

`_training_duration_minutes(data, db)` — `logic.py:212`

| Modalidade | `completed=True` | `completed=False` |
|-----------|-----------------|-------------------|
| FOR TIME (com `forTimeSec`) | `forTimeSec / 60` | Cap do exercício |
| FOR TIME (sem tempo) | Cap do exercício | Cap do exercício |
| AMRAP | Cap do exercício | Cap do exercício |
| EMOM (com rounds) | Cap do exercício | `emomCompletedRounds` min |
| Desconhecida | Cap do exercício | Cap do exercício |

O "cap do exercício" é a duração da **parte principal** de `exercises/{trainingDocId}`, excluindo `WARM UP`, `SKILL`, `EXTRA TRAINING`, `MOBILIDADE`.

### 6.5 Convenção de Semana DOM→SAB

A semana começa no **domingo**, diferente do ISO 8601 (segunda). Esta decisão alinha com o comportamento padrão do calendário Flutter no app cliente. A função `_week_label_sunday()` gera labels `YYYY-Www` baseados nesta convenção. A semana 1 do ano é aquela que contém o primeiro domingo.

### 6.6 Classificação de Resultados por `doc_id`

```python
def _classify_doc(doc_id: str) -> str:
    upper = doc_id.upper()
    if upper.endswith('_REST'):  return 'rest'
    if '_OTHER' in upper:        return 'other'
    return 'training'
```

- `training`: WOD oficial — entra em `totalLoadCrossfit` e `totalLoadAll`
- `other`: atividade externa — entra apenas em `totalLoadAll`
- `rest`: descanso — registrado mas não gera carga

---

## 7. Módulo de Insights do Atleta (`athlete_insights_module`)

### 7.1 Filosofia: O "Dicionário do Atleta"

A IA **nunca expõe jargão técnico** ao atleta. Recebe os dados técnicos com glossário completo e traduz para linguagem humana:

| Termo técnico (interno) | Tradução para o atleta |
|------------------------|------------------------|
| `monotony > 1.5` | "Sua semana teve pouca variação de intensidade" |
| `strain` alto | "Você acumulou bastante desgaste" |
| `icnAll > 75` | "Seu volume ficou bem acima do seu normal" |
| `icnAll < 40` | "Sua carga caiu em relação ao seu normal" |
| `baselineType = cold_start` | (nenhuma comparação com "normal" é feita) |
| `completed=false` em AMRAP | "não sustentou o tempo todo" (nunca "não concluiu") |

### 7.2 Fluxo 1: Insights Semanais

**Função:** `run_weekly_insights_logic(uid)` — `logic.py:123`

**Coleta de dados:**

```python
# 1. Verifica AI habilitada
athlete_ai_enabled(db, uid)

# 2. stats/summary (weeklyLoadLabel como ponteiro para a semana atual)
stats_summary = db.collection("users").document(uid)
                  .collection("stats").document("summary").get()

# 3. weekly_load via weeklyLoadLabel do summary
week_label = stats_summary.get("weeklyLoadLabel")
weekly_load = weekly_load_ref.document(week_label).get()

# 4. Results da semana (até 30)
results_ref.where("date", ">=", week_start)
           .where("date", "<=", week_end).limit(30)

# 4b. Results dos últimos 60 dias para tendências objetivas (até 80)
results_ref.where("date", ">=", since_60_days).limit(80)

# 5. Histórico das 4 semanas anteriores (exclui semana atual)
weekly_load_ref.order_by("weekLabel", DESCENDING).limit(5)
# ordena ascendente, mantém só as 4 anteriores à atual

# 6. Coorte do atleta (cohort_module.find_athlete_cohort)
```

**Estrutura de saída — `WeeklyInsights` (Pydantic):**

| Restrição | Valor |
|-----------|-------|
| Total máximo de insights | 6 |
| Máximo de alertas | 3 |
| Máximo de caracteres por mensagem | 240 |
| Mínimo obrigatório | 1 alerta + 1 informação |

**Persistência:**
```python
db.collection("users").document(uid)
  .collection("insights").document("semanal")
  .set({**parsed, "weekLabel": week_label,
        "generatedFor": {"weekStart": ..., "weekEnd": ...},
        "lastGeneratedAt": SERVER_TIMESTAMP})
```

### 7.3 Fluxo 2: Insights de Evolução

**Função:** `run_evolution_insights_logic(uid, force=False)` — `logic.py:415`

**Cache de 4 dias:**
```python
_EVOLUTION_CACHE_DAYS = 4

def _is_cache_fresh(last_generated_at) -> bool:
    age = datetime.now(UTC) - last_generated_at
    return age < timedelta(days=_EVOLUTION_CACHE_DAYS)
```

Se cache fresco: retorna doc existente com `fromCache: True` sem chamar o LLM.

**Retrocompatibilidade de datas em PRs:**
```python
# date pode ser Timestamp (novo) ou string ISO (legado)
def _stream_date_docs_since(collection_ref, since_date):
    seen = {}
    for bound in [since_date, since_date.strftime("%Y-%m-%d")]:
        for doc in collection_ref.where("date", ">=", bound).stream():
            seen[doc.id] = doc   # dedup por ID
    return list(seen.values())
```

**Estrutura de saída — `EvolutionInsights` (Pydantic):**

| Restrição | Valor |
|-----------|-------|
| Total máximo de insights | 10 |
| Máximo de alertas | 4 |
| Máximo de caracteres por mensagem | 280 |

### 7.4 Fluxo 3: Insights Pré-Treino

**Função:** `run_pre_workout_insights_logic(workout_id, workout_data)` — `pre_workout_logic.py:396`

**Deduplicação por hash MD5:**
```python
_HASH_FIELDS = ('partes', 'modalidade', 'wodType', 'keyMetrics', 'dataTreinoIso')

def _compute_workout_hash(workout: dict) -> str:
    relevant = {k: workout.get(k) for k in _HASH_FIELDS}
    serialized = json.dumps(relevant, sort_keys=True, default=str)
    return hashlib.md5(serialized.encode('utf-8')).hexdigest()
```

Se hash idêntico ao armazenado e atleta já tem insight: **skip**. Se hash diferente: regenera para todos. Garante que edições no título ou status não disparem reprocessamento.

**Dados coletados por atleta:**
- `_fetch_athlete_history_same_type`: até 10 results do mesmo `wodType` ou `modalidade`, com `trainingDocId` (WODs oficiais apenas)
- `_fetch_athlete_current_load`: `weekly_load` atual via `stats/summary.weeklyLoadLabel`
- `_fetch_athlete_recent_prs`: PRs das últimas 8 semanas
- `_fetch_athlete_profile`: perfil detalhado (`profiles/athlete`)
- `_fetch_athlete_history_for_time_of_day`: até 90 results com `trainingTime` para análise de período do dia
- `_fetch_athlete_complementary_load_recent`: treinos pessoais (sem `trainingDocId`) dos últimos 7 dias — apenas para carga acumulada, nunca para comparação de formato

**Otimização:** a instância do LLM é criada **uma única vez** e reutilizada para todos os atletas elegíveis. A chave do Secret Manager é lida uma vez por execução da trigger.

**Estrutura de saída — `PreWorkoutInsights` (Pydantic):**

| Restrição | Valor |
|-----------|-------|
| Total máximo de insights | 5 |
| Máximo de alertas | 3 |
| Máximo de caracteres por mensagem | 240 |

### 7.5 Construção de Contexto (`context_builder.py`)

Em vez de enviar dados brutos ao LLM e deixá-lo calcular (tarefa para a qual LLMs são imprecisos), o código Python pré-computa métricas derivadas. Os detalhes de implementação abaixo foram verificados diretamente no código.

**Contexto semanal (`build_weekly_context`):**

- **`currentWeekDailyLoads`** — distribuição de carga diária com `firstHalfLoad`, `secondHalfLoad`, `heaviestDay`, `trainingDays`. **Importante:** usa apenas `dailyLoadsCrossfit` (WODs oficiais), não a carga total — atletas com alto volume de atividades `_OTHER` terão a forma da semana subestimada neste campo.
- **`recentWeeksDailyLoads`** — mesma estrutura para as 4 semanas anteriores, também baseada em `dailyLoadsCrossfit`.
- **`modalityPerformanceTrends`** — dict keyed por modalidade (ex.: `{"FOR TIME": {direction, sampleSize, ...}}`). Tendência calculada comparando primeiro e último valor de uma série ordenada por data. Requer `sampleSize >= 3`; retorna `None` para séries menores.
- **`completionRateByModality`** — taxa de conclusão por modalidade.
- **`categoryMix`** — distribuição de categorias (RX, Scaled, Intermediário) nos últimos resultados.
- **`milestone`** — marco de frequência próximo. **Ativado apenas quando faltam ≤ 5 treinos** para o próximo alvo da série `(50, 75, 100, 150, 200, 250, 300, 400, 500)`. Se `remaining == 0`, inclui `completedNow: true`. Se nenhum alvo estiver nessa janela, retorna `null` — o prompt não deve mencionar marco nesse caso.

**Contexto de evolução (`build_evolution_context`):**

- **`peakPerformanceProfile`** — zona de fadiga em que os PRs historicamente aparecem: `low` (ICN < 45), `medium` (ICN 45–65), `high` (ICN > 65). Esses limiares são internos ao `context_builder` e diferem dos limiares de referência clínica do Gabbett (2016) usados no glossário do prompt — servem apenas para classificar a zona ótima individual do atleta. Requer `>= 3` PRs com `weekLabel` mapeável para ter `status: "available"`; caso contrário retorna `status: "insufficient_data"`.
- **`allFourWeekPhases`** — blocos de 4 semanas em ordem cronológica com `prsCount`, `wodDays`, `avgIcnAll`, `weeksInHealthyIcnZone` (ICN 40–75), `weeksInHighIcnZone` (ICN > 75), `weeksInLowIcnZone` (ICN < 40).
- **`prEfficiency`** — `prsPerWodDay`: total de PRs dividido por total de dias com WOD nas 12 semanas.

**Contexto pré-treino (`build_pre_workout_context`):**

- **`todayAnchors`** — modalidade, duração, keyMetrics e **até 12 movimentos** do treino (`movements[:12]`).
- **`objectiveTrendSameType`** — dict keyed por modalidade (mesma estrutura de `modalityPerformanceTrends`), calculado sobre o histórico do atleta no mesmo `wodType`/`modalidade`.
- **`prsInTodayWorkout`** — **limitado a 5 itens** (`prs_in_workout[:5]`). PRs são cruzados com movimentos do treino por correspondência de substring no nome.
- **`timeOfDayPerformance`** — breakdown por período (manhã 5h–12h, tarde 12h–18h, noite 18h–24h, madrugada 0h–5h) com `sampleSize`, `avgEffort`, `completionRate`. Inclui `todayPeriod` apenas se `dataTreinoIso` contiver componente de horário (formato `"2026-05-13T19:00:00"`); se a data for apenas `"YYYY-MM-DD"`, `todayPeriod` será `null`.
- **`complementaryLoadRecent`** — resumo de carga complementar dos últimos 7 dias: `{count, days, avgEffort}` ou `null` se não houver atividade.
- **`completionRateSameType`** — taxa de conclusão do atleta naquele tipo/modalidade específico.
- **`currentLoadSummary`** — recorte do `weekly_load` atual: `{icnAll, wodDays, restDays, dailyLoadsCrossfit}`.

### 7.6 Extração de JSON do LLM (`llm_parser.py`)

O Gemini pode retornar JSON em múltiplos formatos. O parser trata todos:

```python
def extract_json_object(raw: Any) -> str:
    candidates = [text]
    # Extrai blocos fenced: ```json...```
    candidates.extend(match.group(1) for match in _FENCED_BLOCK_RE.finditer(text))

    for candidate in candidates:
        for payload in (candidate, _first_balanced_json_object(candidate)):
            try:
                parsed = json.loads(payload)
                if isinstance(parsed, dict):
                    return json.dumps(parsed, ensure_ascii=False)
            except json.JSONDecodeError:
                continue

    raise LLMJsonParseError(...)
```

`_first_balanced_json_object` implementa um parser de chaves balanceadas rastreando strings e escapes para encontrar o primeiro objeto JSON completo.

### 7.7 Modelos Pydantic (`models.py`)

Três classes herdam de `_InsightEnvelope`:

```python
class _InsightEnvelope(BaseModel):
    alertas: Dict[str, AlertDetail]
    informacoes: Dict[str, InfoDetail]

    @model_validator(mode="after")
    def _normalize_limits(self):
        # 1. Calcula quantos alertas/informações manter (respeitando max_total e max_alertas)
        # 2. Normaliza chaves: lowercase, substitui não-alfanuméricos por _, trunca em 64 chars
        # 3. Deduplica: key_2, key_3 se necessário
        # 4. Corta mensagens longas na fronteira de palavra (65% do limite mínimo)
        # 5. Garante pelo menos 1 insight (lança ValueError se ambos vazios)
```

**Configurações por classe:**

| Classe | max_total | max_alertas | max_chars |
|--------|-----------|-------------|-----------|
| `WeeklyInsights` | 6 | 3 | 240 |
| `EvolutionInsights` | 10 | 4 | 280 |
| `PreWorkoutInsights` | 5 | 3 | 240 |

### 7.8 Estratégia de Prompt Engineering (`prompt_builder.py`)

O `prompt_builder.py` (~1.350 linhas) é o componente mais extenso do módulo de insights. Ele não apenas monta strings — ele codifica o conhecimento de domínio do CrossFit e as regras de comunicação com o atleta em blocos reutilizáveis que compõem cada um dos três tipos de prompt.

#### Filosofia geral: contexto em vez de decisão

O LLM recebe **fatos já calculados** pelo `context_builder.py` acompanhados de um glossário que explica o significado de cada campo. A IA não faz aritmética — ela interpreta. Essa divisão evita alucinações numéricas (LLMs são imprecisos em cálculos) e torna o contexto testável independentemente da IA.

#### Bloco `_common_rules()` — Dicionário do Atleta

Injetado nos três fluxos. Define duas camadas:

1. **Contexto teórico confidencial** — explicação das métricas com referências científicas (Gabbett, 2016 para ICN/ACWR; Foster, 2001 para Session-RPE, Monotonia e Strain). Este bloco é explicitamente marcado como "não repassar ao atleta" — serve para que o modelo entenda o significado dos dados sem usar a nomenclatura técnica na resposta.

2. **Dicionário de tradução obrigatória** — mapeamento rígido de termos técnicos para linguagem humana:

| Termo técnico (proibido no output) | Tradução obrigatória |
|------------------------------------|----------------------|
| `ICN alto` / `ACWR > 1.3` | "Seu volume ficou bem acima do seu normal" |
| `ICN baixo` / `ACWR < 0.8` | "Sua carga caiu em relação ao seu normal" |
| `Monotonia > 1.5` | "Sua semana teve pouca variação de intensidade" |
| `Strain alto` | "Você acumulou bastante desgaste" |
| `completed=false` em AMRAP | "não sustentou o tempo todo" (nunca "não concluiu") |
| `baselineType=cold_start` | nenhuma comparação com "normal" é feita |

#### Bloco `_non_obviousness_rule()` — 5 regras de qualidade

Aplicadas antes de cada insight ser incluído na resposta final:

1. **Não-obviedade:** o atleta já saberia disso sem ler? Se sim, descartar.
2. **Unicidade:** dois candidatos com a mesma ideia central → manter o mais específico.
3. **Contraste temporal:** quando há histórico, preferir narrativas "antes X, agora Y".
4. **Confiança de amostra:** padrão requer 4–5 observações; menos que isso exige linguagem condicional.
5. **Coerência temática:** o mesmo tema (modalidade, estímulo, movimento) aparece em apenas um lado da resposta — alerta ou informação, nunca ambos com sinais opostos.

#### Bloco `_few_shot_examples_block(flow)` — exemplos de calibração por fluxo

Um exemplo ruim e um bom por fluxo, com motivo explícito. Não são copiados literalmente — servem como âncora de padrão para o modelo calibrar tom, especificidade e ancoragem em dado. Exemplo do fluxo semanal:

```
Mini-snapshot: icnAll=85, monotony=1.7, stimuli={'Força': 4, 'Ritmo': 0},
carga concentrada no fim da semana.

❌ RUIM: "Você treinou bastante essa semana. Pense em descansar."
   Motivo: genérico, sem cruzamento, sem ação específica.

✅ BOM: "Quatro estímulos de força e zero de ritmo — e os dias pesados
   concentrados no fim. Encaixe um treino mais ágil no começo do próximo
   ciclo para reequilibrar."
   Motivo: cruza estímulo × forma do microciclo × ação concreta.
```

#### Bloco `_week_stage_context(now, week_start)` — estágio temporal

Injetado no fluxo semanal. Informa ao LLM o dia atual (1–7), o percentual da semana concluído e o estágio (`INÍCIO`/`MEIO`/`FIM`). Calibra o tempo verbal e a profundidade dos insights:

- **INÍCIO (dia 1–2):** proibido falar em "variação da semana" ou "padrão semanal" — a semana mal começou.
- **MEIO (dia 3–5):** mistura de leitura do que está se desenhando com projeção.
- **FIM (dia 6–7):** pode afirmar padrões consolidados com confiança.

O dia e a data são pré-computados em Python e enviados como texto — o modelo não faz aritmética de datas.

#### Bloco `_cohort_context_block(cohort)` — framing comparativo positivo

Injetado quando a coorte está disponível. Inclui regras rígidas de uso: comparações negativas são proibidas no output. Se o atleta está abaixo da média da coorte, a coorte não é mencionada. Se está igual ou acima, pode ser usada como validação ou conquista. Máximo de 1–2 insights comparativos por resposta.

#### Três funções de prompt e seus tamanhos aproximados

| Função | Dados injetados | Tamanho estimado |
|--------|----------------|-----------------|
| `create_weekly_insights_prompt` | stats/summary, weekly_load, results da semana, histórico 4 semanas, contexto pré-computado, coorte | ~3.000–5.000 chars |
| `create_evolution_insights_prompt` | stats/summary, 12 semanas de weekly_load, PRs, distribuição de estímulos, contexto de evolução, coorte | ~5.000–8.000 chars |
| `create_pre_workout_insights_prompt` | treino do dia, histórico do mesmo tipo, carga atual, PRs recentes, contexto pré-treino, coorte | ~3.000–5.000 chars |

---

## 8. Módulo de IA do Coach (`ia_module`)

### 8.1 Objetivo e Escopo

Este módulo gera análises destinadas ao **coach**, em contraste com o `athlete_insights_module` que fala com o atleta. O coach recebe dois tipos de análise, ambas disparadas pelo mesmo trigger (`exercises/{workoutId}` escrito) e executadas na mesma invocação da Cloud Function:

1. **Análise Diária (Micro)** — análise técnica do treino publicado no contexto dos últimos 15 dias
2. **Análise de Ciclo Mensal (Macro)** — visão estratégica do mês completo, chamada logo após a análise diária

### 8.2 Orquestrador: `run_ai_analysis_logic(event)`

**Arquivo:** `ia_module/logic.py:327`

**Máquina de estados em `exercises/{workoutId}.statusAnalise`:**

```
null / ausente
      │  trigger recebido
      ▼
  "processando"   ← marcado antes de chamar o LLM
      │
      ├─► sucesso → "concluida" + analise salva + analisadoEm
      │
      └─► exceção → "erro" + erroMsg
```

**Guardas de execução:**
```python
if current_data.get('status') != 'publicado': return
if status in ['concluida', 'processando', 'erro']: return  # evita reprocessamento
if not current_data.get('partes'): return  # aguarda PDF
```

**Dados carregados:**
1. `past_workouts` — últimos 30 `exercises/` por data desc, filtrando `status=="publicado"` em memória, excluindo o atual, mantendo até 15
2. `exercise_db` — coleção `movimentos/` completa: nome, equipamento, músculos, categorias
3. `class_context` — `_compute_class_context(db)`: agregação da turma via Collection Group Query

**Invocação do LLM:**
```python
llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0.2)
ai_message = llm.invoke(prompt_text)  # análise diária usa .invoke direto
```

**Pós-processamento do JSON:**
```python
clean_output = raw_output
if "```json" in raw_output:
    clean_output = raw_output.split("```json")[1].split("```")[0].strip()
elif "```" in raw_output:
    clean_output = raw_output.split("```")[1].strip()
# Nota: não usa o llm_parser.py robusto do athlete_insights_module
```

**Salvamento:**
```python
workout_ref.update({
    "analise": structured_analysis,
    "statusAnalise": "concluida",
    "analisadoEm": firestore.SERVER_TIMESTAMP,
    "erroMsg": firestore.DELETE_FIELD,
})
```

**Notificação:**
```python
notify_all_coaches(
    type_="coach_daily_analysis_ready",
    dedupe_key=f"coach-daily-analysis:{workout_id}",
    route_name="/coach_insights",
    route_args={"trainingId": workout_id, "dateIso": ...},
)
```

**Encadeamento do ciclo:**
```python
# A mesma api_key e class_context são reaproveitadas
run_cycle_analysis(db, current_data_with_id, api_key, class_context)
```

### 8.3 Função: `run_cycle_analysis(db, current_workout, api_key, class_context)`

**Arquivo:** `ia_module/logic.py:140`

**Computed data em Python (antes de chamar o LLM):**

```python
# Contagem de tipos de treino por seção de 'partes'
for key in partes.keys():
    if "WOD" in key.upper():      type_counts["WODs"] += 1
    elif "LPO" in key.upper():    type_counts["LPO"] += 1
    elif "GYM" in key.upper() or "GINÁSTICA" in key.upper():
                                   type_counts["Ginástica"] += 1
    elif "ENDURANCE" in key.upper(): type_counts["Endurance"] += 1

# Estímulos: lidos de analise.summary.key_metrics JÁ gerado pela análise diária
for metric in analise.get("summary", {}).get("key_metrics", []):
    stimulus_counts[metric.title()] += 1
```

> **Limitação conhecida — `key_metrics` do treino atual ausentes no ciclo:** `run_cycle_analysis` recebe `current_data_for_cycle = current_data.copy()`, que é uma cópia do documento Firestore capturada **no início** de `run_ai_analysis_logic`, antes de `workout_ref.update({"analise": ...})` ser chamado. Portanto, o treino atual não terá `analise.summary.key_metrics` no momento em que `stimulus_counts` é calculado — sua contribuição de estímulos para o ciclo será `[]` nessa primeira execução. Treinos do mês publicados anteriormente **já têm** `analise` persistida no Firestore e contribuem normalmente. Na próxima publicação de outro treino no mês, o Firestore já terá o documento atualizado e o ciclo calculará corretamente os estímulos de todos os treinos passados.

**Invocação com pipe do LangChain:**
```python
chain = llm | cycle_parser
result = chain.invoke(prompt_text)
cycle_ai_data = result.dict()
```

A sintaxe de pipe (`|`) é o padrão moderno do LangChain (LCEL — LangChain Expression Language), diferente do `llm.invoke` usado na análise diária.

**Documento final mesclado:**
```python
final_document = {
    **cycle_ai_data,              # dados da IA (comparison, recommendations, etc.)
    "overview_stats": {
        "updatedAt": datetime.now().isoformat(),
        "trainingsCount": trainings_count,
        "registrosCount": 0,      # WIP
        "activeStudentsPct": 0    # WIP
    },
    "trainingTypes": training_types_list,   # Python
    "stimulus": stimulus_list,              # Python
    "biggestStimulusLabel": biggest_stimulus_label
}
cycles/{current_month_key}.set(final_document)
```

**Tratamento de erros:**
```python
except Exception as e:
    logging.error(f"Erro CRÍTICO na análise de ciclo: {e}")
    return {"error": str(e)}
    # Não relança — falha no ciclo não derruba a análise diária já salva
```

### 8.4 Contexto da Turma: `_compute_class_context(db)`

**Arquivo:** `ia_module/logic.py:49`

Agrega métricas de **todos os atletas** em uma única Collection Group Query:

```python
docs = db.collection_group('weekly_load')
         .where('weekLabel', '==', week_label)
         .stream()
```

**Saída:**
```python
{
    'weekLabel': '2026-W20',
    'athletesCount': 42,
    'averageEffortCurrentWeek': 7.3,
    'averageMonotony': 1.2,
    'averageIcnAll': 58.4,
    'wodVsAlternativeRatio': 0.71,
    'totals': {'wodDays': 120, 'otherDays': 18, 'restDays': 30},
}
```

Este contexto permite ao LLM gerar alertas específicos para o coach sobre o estado coletivo da turma (ex: "A turma está chegando cansada esta semana").

### 8.5 Modelos Pydantic do Coach (`ia_module/models.py`)

**`TrainingAnalysis`** — análise diária:

```python
class TrainingAnalysis(BaseModel):
    summary: Summary               # overview (≤600 chars) + key_metrics (max 3 items)
    history_analysis: HistoryAnalysis  # weekly: fatos, muscle_focus: grupos musculares
    insights: Dict[str, InsightDetail]  # chave=título, valor={detail: ≤600 chars}
    alerts: Dict[str, AlertDetail]      # chave=tipo_alerta, valor={message}
```

**`CycleAnalysis`** — análise mensal:

```python
class CycleAnalysis(BaseModel):
    month_year: str
    comparison: CycleComparison         # progression, distribution, variation, effort
    recommendations: Dict[str, CycleDetail]  # chave=título, valor={description}
    positives: List[str]
    technical_alerts: Dict[str, CycleDetail]
    overview: str
    quick_alerts: List[str]             # 3–5 alertas curtos (max 20 palavras cada)
```

### 8.6 Construção de Prompts (`ia_module/prompt_builder.py`)

**`create_evaluation_prompt`** — recebe: treino atual, histórico de 15 dias, base de movimentos, contexto da turma.

Quatro etapas de análise explícitas no prompt:
1. `history_analysis` — fatos objetivos (sem opiniões)
2. `alerts` — riscos: sobrecarga, fadiga SNC, fadiga de grip, fadiga lombar, fadiga de turma
3. `insights` — mobilidade recomendada, logística, scaling por nível, variações compatíveis
4. `summary` — overview + top 3 estímulos (máximo estrito de 3 em `key_metrics`)

**`create_cycle_prompt`** — recebe: treinos do mês, ciclo anterior, contexto da turma. Análise macro em 6 campos.

---

## 9. Módulo de Notificações (`notification_module`)

### 9.1 Função: `create_user_notification()`

**Arquivo:** `notification_module/logic.py:82`

**Parâmetros:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `db` | Firestore client | — |
| `uid` | `str` | Destinatário |
| `role` | `str` | `athlete` ou `coach` |
| `type_` | `str` | Tipo da notificação |
| `title` / `body` | `str` | Conteúdo |
| `dedupe_key` | `str` | Usado como `doc_id` (sanitizado) |
| `route_name` | `str` | Rota Flutter |
| `route_args` | `dict` | Parâmetros da rota |
| `source_id` | `str` | weekLabel, workoutId, etc. |

**Fluxo:**
```
1. users/{uid} existe?     → se não, return False
2. notification_enabled?   → se não, return False
3. doc_id = _safe_doc_id(dedupe_key)
4. Documento já existe?    → se sim, return False (deduplicado)
5. Criar doc com status="unread", expiresAt=now+7dias
6. _send_push_to_user: itera notificationTokens/ where enabled==true
7. return True
```

**Prefixo para perfis híbridos:**
```python
_HYBRID_PROFILES = {"athleteCoach", "athleteIntern"}

def _with_role_prefix(title, role, profile):
    if profile not in _HYBRID_PROFILES: return title
    prefix = "[coach]" if role == "coach" else "[atleta]"
    return f"{prefix} {title}"
```

### 9.2 Função: `notify_all_coaches()`

Itera todos os perfis coach-like (`coach`, `intern`, `athleteCoach`, `athleteIntern`) e chama `create_user_notification` para cada um, adicionando `:uid` ao `dedupe_key` para não conflitar entre coaches.

### 9.3 Função: `run_hourly_notification_reminders()`

**Janela:** 9h–18h BRT (seg–dom), 8h–12h BRT (segunda-feira).

**Horário determinístico por usuário:**
```python
def _stable_hour(seed: str, start_hour: int, end_hour: int) -> int:
    digest = int(hashlib.md5(seed.encode()).hexdigest(), 16)
    return start_hour + (digest % (end_hour - start_hour + 1))

# seed varia por uid + tipo + data
target_hour = _stable_hour(f"{uid}:athlete:{today_key}", 9, 18)
```

O horário é estável para o mesmo usuário no mesmo dia (mesma seed → mesmo hash), mas varia entre usuários, evitando picos de envio.

**Três variações de copy para atletas:**

| Condição | Título | Corpo |
|----------|--------|-------|
| Segunda-feira 8h–12h | "A semana começou" | "Uma ótima hora para começar bem..." |
| Atleta sem result na semana e dia ≥ 3 | "Vamos manter a constância?" | "Ainda dá tempo de registrar..." |
| Padrão | "Seu registro de hoje está pendente" | "Você ainda não registrou..." |

### 9.4 Função: `delete_expired_notifications()`

**Trigger:** Cron `30 3 * * *` (3:30 da manhã, BRT)

```python
while True:
    expired_docs = db.collection_group("notifications")
                     .where("createdAt", "<=", cutoff)  # cutoff = now - 7 dias
                     .limit(450)                         # conservador vs. limite do Firestore (500)
                     .stream()
    if not expired_docs: break
    batch = db.batch()
    for doc in expired_docs: batch.delete(doc.reference)
    batch.commit()
    if len(expired_docs) < 450: break  # último lote
```

O loop garante que grandes volumes sejam removidos completamente em múltiplas rodadas.

### 9.5 Tipos de Notificação e Preferências

**Para atletas:**

| `type` | Chave em `settings/athlete` | Trigger |
|--------|-----------------------------|---------|
| `athlete_weekly_insights_ready` | `weeklyInsights` | `run_weekly_insights_logic` |
| `athlete_evolution_insights_ready` | `evolutionInsights` | `run_evolution_insights_logic` |
| `athlete_pre_workout_insights_ready` | `preWorkoutInsights` | `run_pre_workout_insights_logic` |
| `athlete_daily_result_reminder` | `trainingReminders` | `run_hourly_notification_reminders` |

**Para coaches:**

| `type` | Chave em `settings/coach` | Trigger |
|--------|---------------------------|---------|
| `coach_daily_analysis_ready` | `dailyTrainingAnalysis` | `run_ai_analysis_logic` |
| `coach_cycle_analysis_ready` | `cycleAnalysis` | `run_cycle_analysis` |
| `coach_missing_training_reminder` | `missingTrainingReminder` | `run_hourly_notification_reminders` |

---

## 10. Módulo de PDF (`pdf_module`)

### 10.1 Objetivo

Processa PDFs de programação de treino enviados pelo coach e transforma o conteúdo em documentos estruturados na coleção `exercises/`.

### 10.2 Função Principal: `run_pdf_parser_logic(event)`

**Arquivo:** `pdf_module/parser.py` (~750 linhas)

**Trigger:** `process_workout_pdf` — `storage_fn.on_object_finalized`

**Origem no Storage:** o app Flutter envia PDFs para `uploads/{uid}/{timestamp}_{filename}` com `contentType='application/pdf'` e metadata customizado (`userId`, `boxId`, `targetDate`). As regras de Storage só permitem criação nesse caminho para usuários coach-like e com arquivo menor que 20 MB.

### 10.3 Pipeline de Parsing (8 estágios)

**Estágio 1: Extração de Texto**
```python
import fitz  # PyMuPDF
doc = fitz.open(stream=pdf_bytes, filetype="pdf")
text = "\n".join(page.get_text() for page in doc)
```

**Estágio 2: Normalização Unicode**
- Normalização NFKC (combina caracteres compostos)
- Mapeamento de caracteres especiais
- Correção de espaçamento irregular

**Estágio 3: Extração de Data**
Padrão: `"10 MARCO | TERCA FEIRA"` (meses sem acento, em português)
Converte para ISO `YYYY-MM-DD`.

**Estágio 4: Extração de Materiais**
Padrão: `"MATERIAL: Munhequeira | Gripp | Barra"`

**Estágio 5: Classificação de Seções**
Seções reconhecidas pelo parser PDF atual: `WARM UP`, `SKILL`, `WOD`, `EXTRA TRAINING`. A seção `MOBILIDADE` aparece como parte de suporte no cálculo de duração do módulo de estatísticas, mas não está no array `HEADERS` do parser PDF.

**Estágio 6: Parsing de Exercícios**
```
"20 Box jump step down" → {quantidade: 20, nome: "Box jump step down", unidade: "reps"}
"15 KTB swing (24Kg|18Kg)" → {quantidade: 15, nome: "KTB swing",
                               cargaRx: "24Kg", cargaScaled: "18Kg"}
```

**Estágio 7: Classificação de Modalidade**

O parser reconhece as seguintes modalidades, aplicadas nesta ordem de prioridade (a primeira correspondência vence):

| Modalidade gerada | Padrão regex no PDF |
|-------------------|---------------------|
| `N ROUNDS FOR TIME` | `\d+\s+ROUNDS?\s+FOR\s+TIME` (ex: `3 ROUNDS FOR TIME`) |
| `AMRAP` | `\bAMRAP\b` |
| `FOR TIME` | `\bFOR\s+TIME\b` |
| `EMOM` | `\bEMOM\b` |
| `TABATA` | `\bTABATA\b` |
| `N ROUNDS` | `\d+\s+ROUNDS?\b` (genérico, sem FOR TIME) |

Se nenhum padrão for encontrado, `modalidade` fica `null`.

**Estágio 8: Parsing de Cargas**
Formato `(24Kg|18Kg)`: primeiro valor = RX/masculino, segundo = Scaled/feminino.
Formato com barra, como `(24Kg/18Kg)`, não é separado em `cargaRx` e `cargaScaled` pelo parser atual; ele é preservado como uma única string em `cargaRx`.

**ID do documento gerado:**
- Com nome de WOD/SKILL/EXTRA/WARM UP: `{nome_sanitizado} ({DD-MM-YYYY})`, ex.: `SKY IS THE LIMIT (10-03-2026)`.
- Sem nome de WOD/SKILL/EXTRA/WARM UP: `Treino ({DD-MM-YYYY})`.
- Páginas sem data válida ou sem WOD válido são ignoradas; o código atual não grava treino sem data e não usa UUID nesse fluxo.

**Status inicial após importação:**
- Documento novo: `status="rascunho"` e `statusAnalise="aguardando_publicacao"`.
- Documento já existente e publicado: mantém `status="publicado"` e define `statusAnalise="pendente"` para permitir reanálise.

**Metadados do upload usados pelo parser:**
- `userId`: usado como `uploadedBy` e `createdByUid`.
- `boxId`: usado como `boxId`.
- `targetDate`: enviado pelo Flutter, mas não é usado pelo parser atual; a data efetiva vem do texto do PDF.

---

## 11. Módulo de Coorte (`cohort_module`)

### 11.1 Objetivo

Gera snapshots agregados de atletas com perfil semelhante (coortes), permitindo que a IA forneça contexto comparativo positivo e personalizado.

### 11.2 Normalização de Perfil (`bucketization.py`)

**Categorias válidas** (mapeadas para chave canônica sem acentos):

| Valor no app | Chave normalizada |
|---|---|
| `Iniciante` | `INICIANTE` |
| `Scaled` | `SCALED` |
| `Intermediário` | `INTERMEDIARIO` |
| `RX` | `RX` |
| `Elite` | `ELITE` |

**Gênero:**

| Valor no app | Chave | Elegível para coorte |
|---|---|---|
| `Homem` | `M` | ✅ |
| `Mulher` | `F` | ✅ |
| `Outro` | — | ❌ (pool insuficiente) |

**Tempo de prática (buckets):**

| Valor no app | Bucket |
|---|---|
| `Menos de 1 ano` | `lt1y` |
| `Entre 1 e 3 anos` | `1-3y` |
| `Entre 3 e 5 anos` | `3-5y` |
| `Mais de 5 anos` | `gt5y` |

**Geração de chaves:**
```python
def build_cohort_keys(profile: dict) -> Tuple[Optional[str], Optional[str]]:
    cat    = normalize_category(profile.get('category'))
    gender = normalize_gender(profile.get('gender'))
    bucket = normalize_practice_years(profile.get('practiceYears'))

    if cat is None or gender is None:
        return (None, None)  # sem coorte

    level2 = f'{cat}_{gender}'
    level3 = f'{cat}_{gender}_{bucket}' if bucket else None
    return (level3, level2)
```

### 11.3 Matching de Coorte (`matching.py`)

**Função:** `find_athlete_cohort(uid, db) -> Optional[dict]`

```
1. Ler profiles/athlete → se não existe, return None
2. build_cohort_keys → (l3, l2)
3. Se l2 é None (perfil incompleto ou "Outro") → return None
4. Tentar cohorts/{l3} → se existe e tem dados, return
5. Fallback: tentar cohorts/{l2} → se existe e tem dados, return
6. Nenhum disponível → return None
```

### 11.4 Agregação de Coortes (`aggregation.py`)

**Função:** `update_cohort_snapshots_logic()`

**Estratégia de leitura validada no código:** a agregação de coortes itera `db.collection('users').stream()`, lê `users/{uid}/profiles/athlete` e, para atletas elegíveis/ativos, busca `users/{uid}/weekly_load/{weekLabel}` da semana atual. Diferentemente de `_compute_class_context` no `ia_module`, este job não usa Collection Group Query.

**Constantes de privacidade e atividade:**
```python
_MIN_COHORT_SIZE = 5        # coortes com < 5 atletas não são publicadas
_ACTIVITY_WINDOW_WEEKS = 4  # atleta sem weekly_load nas últimas 4 semanas é ignorado
```

**Métricas agregadas por coorte:**
```python
{
    'avgWeeklyICN':    mean(icns),
    'medianWeeklyICN': median(icns),
    'avgMonotony':     mean(monotonias),
    'avgRpeAll':       mean(rpes),
    'avgPrsPerWeek':   mean(prs),
    'avgCargaCronica': mean(cargas_cronica),
    'topStimuli':      top_5_stimuli_by_frequency,
}
```

**Limpeza de coortes estagnadas (passo final):**
```python
existing = {d.id for d in cohorts_ref.stream()}
active_keys = {p['cohortKey'] for p in persisted}
stale = existing - active_keys
for s in stale:
    cohorts_ref.document(s).delete()
```

Remove coortes que existiam no Firestore mas não tiveram atletas ativos suficientes nesta semana.

**Telemetria:**
```python
telemetry_module.record_cohort_job(
    cohorts_persisted=len(persisted),
    cohorts_too_small=len(skipped_too_small),
    athletes_active=athletes_active,
)
```

### 11.5 Regras de Framing Comparativo (no Prompt)

Regras estritas aplicadas no `prompt_builder.py` do módulo de insights:

- ❌ **Proibido:** "Você está pior que atletas como você", "sua carga está abaixo da coorte"
- ✅ **Permitido:** validação ("você está no ritmo do grupo"), conquista ("acima da média"), contextualização ("atletas com perfil parecido também sentem dificuldade")
- Se o atleta está **abaixo** da média da coorte: coorte não é mencionada
- Máximo de **1–2 insights comparativos** por resposta
- Level 2 (fallback): usar "atletas da sua categoria" em vez de "atletas com seu tempo de prática"

---

## 12. Módulo de Conta (`account_module`)

### 12.1 `deactivate_user_account(uid, db=None)`

**Arquivo:** `account_module/logic.py:6`

Realiza **soft-disable**: preserva todos os dados, apenas altera o status.

```python
db.collection("users").document(uid).set({
    "accountStatus": "disabled",
    "disabledAt": firestore.SERVER_TIMESTAMP,
    "updatedAt": firestore.SERVER_TIMESTAMP,
}, merge=True)
```

`merge=True` garante que apenas os campos listados sejam alterados. O usuário **ainda pode fazer login** — o Firebase Authentication não é afetado. Consequências:
- `athlete_ai_enabled()` → `False` (nenhuma geração de IA)
- `notification_enabled()` → `False` (nenhuma notificação)

### 12.2 `reactivate_user_account(uid, db=None)`

Restaura `accountStatus = "active"` com timestamp de reativação.

### 12.3 `delete_user_account(uid, db=None)`

**Exclusão completa e permanente (LGPD):**

```python
# 1. Excluir exercises/ criados por este coach
for exercise in db.collection("exercises")
                  .where("createdByUid", "==", uid).stream():
    _delete_doc_tree(exercise.reference)

# 2. Excluir toda a árvore do usuário (recursivo)
_delete_doc_tree(db.collection("users").document(uid))

# 3. Excluir usuário do Firebase Authentication
try:
    auth.delete_user(uid)
except auth.UserNotFoundError:
    pass  # já deletado, não é erro

return {"deletedDocs": deleted_docs, "authDeleted": True}
```

**`_delete_doc_tree(doc_ref)`** — recursivo:
```python
def _delete_doc_tree(doc_ref) -> int:
    deleted = 0
    for collection_ref in doc_ref.collections():
        for child in collection_ref.stream():
            deleted += _delete_doc_tree(child.reference)
    doc_ref.delete()
    return deleted + 1
```

Percorre toda a árvore de subcoleções de baixo para cima antes de deletar o documento pai, garantindo que nenhum dado órfão seja deixado.

---

## 13. Módulo de Exportação (`export_module`)

### 13.1 Objetivo e Conformidade LGPD

Permite ao usuário exportar todos os seus dados, em conformidade com o direito à portabilidade garantido pela Lei nº 13.709/2018 (LGPD).

### 13.2 Função: `export_user_data(uid, db=None)`

**Arquivo:** `export_module/logic.py:39`

**O que é exportado:**
1. Toda a árvore recursiva de `users/{uid}` — inclui results, prs, stats, weekly_load, insights, settings, notifications, profiles, notificationTokens
2. Todos os documentos de `exercises/` onde `createdByUid == uid`

**Estrutura de saída:**
```python
{
    "uid": uid,
    "exportedAt": "2026-05-14T10:30:00Z",
    "user": {
        "id": uid,
        "exists": True,
        "data": {...},   # campos do documento raiz
        "collections": {
            "results": {"doc_id_1": {...}, "doc_id_2": {...}},
            "prs": {...},
            "stats": {...},
            "weekly_load": {...},
            "insights": {...},
            ...
        }
    },
    "exercises": {
        "workoutId_1": {...},
        ...
    }
}
```

**Serialização segura de tipos Firestore:**
```python
def _json_safe(value):
    if isinstance(value, (datetime, date)): return value.isoformat()
    if hasattr(value, "to_datetime"):       return value.to_datetime().isoformat()
    if isinstance(value, dict):  return {str(k): _json_safe(v) for k,v in value.items()}
    if isinstance(value, list):  return [_json_safe(v) for v in value]
    ...
```

O retorno é feito diretamente ao app Flutter via `onCall`. Não há geração de arquivo separado — o JSON é retornado no payload da resposta callable.

---

## 14. Módulo de Suporte (`support_module`)

### 14.1 Função: `submit_support_ticket(uid, payload, db=None)`

**Arquivo:** `support_module/logic.py`

**Tipos de ticket aceitos:** `support`, `feedback`, `bug_report`
Tipo inválido é normalizado para `support`.

**Validação:**
```python
message = str(payload.get("message", "")).strip()
if not message:
    raise ValueError("Mensagem vazia.")
# Lança ValueError → main.py converte para HttpsError.INVALID_ARGUMENT
```

**Campos do payload:**

| Campo | Obrigatório | Descrição |
|-------|-------------|-----------|
| `type` | ✅ | Tipo do ticket |
| `message` | ✅ | Mensagem do usuário |
| `steps` | ❌ | Passos para reprodução (bug_report) |
| `rating` | ❌ | Avaliação numérica |

**Fluxo:**
1. Cria documento em `supportTickets/{auto_id}`
2. Lê `email` e `name` de `users/{uid}` para enriquecer o ticket
3. Cria documento em `mail/{ticketId}` — processado pelo Firebase Extension "Trigger Email"

**Endereço de e-mail:**
```python
# Variável de ambiente, com fallback hardcoded
support_email = os.environ.get("SUPPORT_EMAIL", "suporte@motiva.app")
```

> **Importante:** `SUPPORT_EMAIL` é declarado como `params.SecretParam("SUPPORT_EMAIL")` em `main.py`, portanto deve existir como secret/param no ambiente de Functions. Durante a execução da callable `submit_support_ticket`, o valor é injetado como variável de ambiente apenas para essa função e o módulo de suporte o lê via `os.environ.get("SUPPORT_EMAIL")`. Se não houver valor injetado, o fallback do código é `suporte@motiva.app`.

**Assuntos por tipo:**

| Tipo | Assunto do e-mail |
|------|-------------------|
| `feedback` | `Motiva - novo feedback` |
| `bug_report` | `Motiva - novo relato de erro` |
| `support` | `Motiva - nova mensagem de suporte` |

---

## 15. Módulo de Telemetria (`telemetry_module`)

### 15.1 Objetivo

Registra contadores diários de uso da IA para monitoramento de custo, qualidade e comportamento do sistema. **Nunca levanta exceção** — falha na telemetria não impacta o fluxo principal.

### 15.2 Função: `record_insight_event(kind, *, status, ...)`

**Arquivo:** `telemetry_module/logic.py:55`

**Escritas atômicas com `FieldValue.increment`:**
```python
updates = {
    f'insights.{kind}.total':    firestore.Increment(1),
    f'insights.{kind}.{status}': firestore.Increment(1),
    'estimatedTokens.prompt':    firestore.Increment(prompt_tok),
    'estimatedTokens.response':  firestore.Increment(response_tok),
}
db.collection('telemetry').document(ts_doc_id).set(updates, merge=True)
```

`FieldValue.increment` é essencial aqui: múltiplas Cloud Functions (atletas diferentes recebendo insights simultâneos) podem tentar atualizar o mesmo documento `telemetry/{YYYY-MM-DD}`. Com increment atômico, não há condição de corrida — cada Function soma ao valor existente sem sobrescrever.

**Estimativa de tokens:**
```python
_CHARS_PER_TOKEN = 4  # Gemini PT-BR usa ~3.5–4 chars/token em média

def estimate_tokens(text: str) -> int:
    return max(1, len(text) // _CHARS_PER_TOKEN)
```

### 15.3 Função: `record_cohort_job(...)`

Registra execuções do job de coorte com contadores separados: `cohortJobs.runs`, `cohortsPersistedSum`, `cohortsTooSmallSum`, `athletesActiveSum`.

### 15.4 Função: `record_insight_generated(kind, ...)`

Wrapper de conveniência sobre `record_insight_event`, aceita `skipped: bool` em vez de `status: str`.

---

## 16. Módulo de Configurações do Usuário (`user_settings_module`)

### 16.1 Funções

**`is_account_disabled(db, uid, user_data=None) -> bool`**
Verifica `accountStatus == "disabled"`. Aceita `user_data` pré-carregado para evitar leitura duplicada.

**`athlete_ai_enabled(db, uid) -> bool`**
```python
def athlete_ai_enabled(db, uid: str) -> bool:
    if is_account_disabled(db, uid): return False
    privacy = _settings_data(db, uid, "privacy")
    return privacy.get("aiPersonalizationEnabled", True) is not False
```
Padrão é `True` — se o documento não existe ou o campo está ausente, a IA é considerada habilitada.

**`notification_enabled(db, uid, role, type_, user_data=None) -> bool`**
Verifica preferência por tipo de notificação usando as chaves mapeadas:

```python
_ATHLETE_NOTIFICATION_KEYS = {
    "athlete_weekly_insights_ready":      "weeklyInsights",
    "athlete_evolution_insights_ready":   "evolutionInsights",
    "athlete_pre_workout_insights_ready": "preWorkoutInsights",
    "athlete_daily_result_reminder":      "trainingReminders",
}
_COACH_NOTIFICATION_KEYS = {
    "coach_daily_analysis_ready":      "dailyTrainingAnalysis",
    "coach_cycle_analysis_ready":      "cycleAnalysis",
    "coach_missing_training_reminder": "missingTrainingReminder",
}
```

Tipos não mapeados retornam `True` por padrão.

---

## 17. Sistema de Debounce e Cloud Tasks

### 17.1 Problema

Quando um atleta registra 3 resultados em rápida sucessão (WOD + PR + atividade extra após a aula), sem debounce seriam geradas 3 chamadas ao Gemini em poucos segundos — custo triplicado e insights baseados em dados parciais.

### 17.2 Solução: Nome de Task Determinístico

**Arquivo:** `main.py:63–131`

```python
# Bucket de 5 minutos: agrupa todos os publishes do mesmo atleta na mesma janela
bucket = int(now.timestamp() // _TASK_DELAY_SECONDS)
task_name = f"{parent}/tasks/weekly-{uid}-{bucket}"
```

Se o atleta publicar N resultados em menos de 5 minutos, as N tentativas geram o **mesmo nome de task**. O Cloud Tasks recusa as N-1 duplicatas com `ALREADY_EXISTS` — apenas uma task é executada.

### 17.3 Jitter Anti-Pico por UID

Após o fim de uma aula, dezenas de atletas publicam resultados quase simultaneamente. Sem dispersão, todas as tasks disparariam no mesmo intervalo de 5–15 minutos, gerando spike de chamadas ao Gemini.

```python
def _uid_jitter_seconds(uid: str) -> int:
    digest = int(hashlib.md5(uid.encode()).hexdigest(), 16)
    return digest % (_TASK_MAX_JITTER_SECONDS + 1)  # 0–600 s
```

O jitter é **determinístico por UID**: o mesmo atleta sempre tem o mesmo offset, então o nome da task permanece idêntico para múltiplos publishes na mesma janela (debounce preservado). Atletas diferentes têm offsets diferentes, distribuindo as execuções ao longo de até 10 minutos adicionais.

**Delay total:**
```
Delay total = 300s (base) + jitter(uid) ∈ [0, 600s]
Resultado: task executada entre 5 e 15 minutos após o último resultado
```

### 17.4 URL do Handler

```python
def _weekly_insights_handler_url() -> str:
    project = os.environ.get("GCLOUD_PROJECT") or \
              json.loads(os.environ.get("FIREBASE_CONFIG", "{}")).get("projectId")
    return f"https://{_REGION}-{project}.cloudfunctions.net/run_weekly_insights_task"
```

Resolvido em runtime: o PROJECT_ID vem de `GCLOUD_PROJECT` (injetado automaticamente) ou do JSON `FIREBASE_CONFIG`.

---

## 18. Padrões Arquiteturais e Decisões de Design

### 18.1 Separação Síncrono / Assíncrono

- **Síncrono (inline no trigger):** matemática pura, operações < 2s. O usuário vê dados imediatamente.
- **Assíncrono (Cloud Tasks):** chamadas ao LLM, iteração sobre muitos usuários. O usuário recebe notificação quando pronto.

### 18.2 Collection Group Queries para Agregação

```python
db.collection_group('weekly_load').where('weekLabel', '==', label).stream()
```

Permite consultar `weekly_load` de **todos os usuários** em uma query, sem iterar `users/`. Na versão atual, esse padrão é usado em `ia_module._compute_class_context`. O `cohort_module.aggregation`, por outro lado, itera `users/` porque também precisa ler o perfil detalhado de cada atleta e aplicar regras de elegibilidade/atividade.

### 18.3 Importação Lazy de Módulos

Todos os módulos são importados dentro das funções:
```python
@firestore_fn.on_document_written(...)
def update_athlete_stats(event):
    try:
        from athlete_stats_module import update_athlete_stats_logic
    except Exception:
        logging.exception("Falha ao importar")
        return
```

**Motivos:** (1) reduz cold start — imports no nível do módulo aumentam o tempo de inicialização; (2) isolamento de falhas — falha em um módulo não afeta os outros; (3) testabilidade — facilita mock em testes unitários.

### 18.4 Pré-computação de Contexto para o LLM

O padrão `context_builder.py → prompt_builder.py → LLM` garante que a IA receba **fatos** (distribuições, tendências já calculadas) em vez de dados brutos. LLMs são imprecisos em aritmética; entregar contexto pré-computado reduz alucinações numéricas.

### 18.5 Retrocompatibilidade de Formatos

O sistema suporta dois formatos de data em PRs (Timestamp e string ISO). Em cargas de exercícios, o formato com pipe (`24Kg|18Kg`) é interpretado como RX/Scaled; formato com barra (`24Kg/18Kg`) é preservado como texto único e não gera separação automática.

### 18.6 Análise de Ciclo Encadeada

`run_cycle_analysis` é chamada de dentro de `run_ai_analysis_logic`, reaproveitando `api_key` (uma única chamada ao Secret Manager por trigger) e `class_context` (uma única Collection Group Query por trigger). Isso é mais eficiente do que ter um trigger separado para o ciclo.

---

## 19. Segurança, Autenticação e Regras Firebase

### 19.1 Funções Callable — uid do Token

```python
def get_athlete_evolution_insights(req: https_fn.CallableRequest):
    if not req.auth or not req.auth.uid:
        raise https_fn.HttpsError(UNAUTHENTICATED, "Autenticação necessária.")
    uid = req.auth.uid  # NUNCA usa uid do body/data
```

O `uid` é sempre extraído do token Firebase Authentication, nunca do corpo da requisição.

### 19.2 Chave de API via Secret Manager

```python
name = f"projects/{project_id}/secrets/GEMINI_API_KEY/versions/latest"
client = secretmanager.SecretManagerServiceClient()
response = client.access_secret_version(request={"name": name})
return response.payload.data.decode("UTF-8")
```

A chave nunca é exposta em código-fonte, logs ou variáveis de ambiente visíveis. Rotação é feita no Secret Manager sem redeployment.

### 19.3 SUPPORT_EMAIL via SecretParam

```python
_SUPPORT_EMAIL_SECRET = params.SecretParam("SUPPORT_EMAIL")

@https_fn.on_call(secrets=[_SUPPORT_EMAIL_SECRET])
def submit_support_ticket(req):
    ...
```

`params.SecretParam` instrui o Cloud Functions a injetar o secret como variável de ambiente **apenas para esta função**. O módulo de suporte o lê via `os.environ.get("SUPPORT_EMAIL")`.

### 19.4 Validação de Entrada em Callables

Todas as funções callable verificam autenticação antes de qualquer operação de banco. Funções de modificação de conta (`deactivate`, `reactivate`, `delete`) usam o `req.auth.uid` como única fonte de verdade do usuário alvo.

### 19.5 Regras de Segurança do Firestore (`firestore.rules`)

As regras usam três funções-base:

```javascript
isSignedIn()      // request.auth != null
isOwner(userId)   // request.auth.uid == userId
isActiveOwner()   // owner e accountStatus != "disabled"
```

Perfis considerados coach-like:
`coach`, `intern`, `athleteCoach`, `athleteIntern`, `admin`.

| Caminho | Leitura pelo app | Escrita pelo app | Observação técnica |
|---------|------------------|------------------|--------------------|
| `users/{uid}` | Somente o dono | Criação pelo dono; update pelo dono ativo | `accountStatus="disabled"` bloqueia updates do próprio usuário |
| `users/{uid}/results/{id}` | Dono ativo | Dono ativo | Trigger `update_athlete_stats` recalcula métricas após writes |
| `users/{uid}/prs/{id}` | Dono ativo | Dono ativo | Trigger `update_athlete_stats_on_pr` recalcula métricas após writes |
| `users/{uid}/profiles/{profileId}` | Dono ativo | Dono ativo | Inclui `profiles/athlete` e `profiles/coach` |
| `users/{uid}/stats/{document}` | Dono ativo | Dono ativo | **Atenção:** hoje o cliente pode escrever em dados derivados |
| `users/{uid}/weekly_load/{weekLabel}` | Dono ativo | Dono ativo | **Atenção:** hoje o cliente pode escrever em dados derivados |
| `users/{uid}/insights/{document=**}` | Dono ativo | Dono ativo | **Atenção:** hoje o cliente pode escrever em insights gerados por IA |
| `users/{uid}/settings/{athlete,coach,privacy}` | Dono | Dono ativo | Apenas estes três documentos são permitidos; delete é bloqueado |
| `users/{uid}/notifications/{id}` | Dono | Apenas update de `status` e `readAt` para marcar como lida | Create/delete bloqueados ao cliente; Functions criam via Admin SDK |
| `users/{uid}/notificationTokens/{token}` | Dono | Dono ativo, com chaves restritas | `request.resource.data.token` precisa ser igual ao ID do documento |
| `exercises/{document=**}` | Usuário autenticado se coach-like ou treino publicado/processado | Apenas coach-like | Atletas leem apenas treinos publicados/processados |
| `cycles/{document=**}` | Público (`allow read: if true`) | Qualquer usuário autenticado | **Risco:** análises de ciclo deveriam ser escritas apenas por backend/coach |
| `movimentos/{document}` | Qualquer usuário autenticado | Bloqueado | Base de movimentos usada pelo coach/IA |
| `cohorts/{document=**}` | Bloqueado | Bloqueado | Apenas Admin SDK/Functions acessam |
| `telemetry/{document=**}` | Bloqueado | Bloqueado | Apenas Admin SDK/Functions acessam |
| `supportTickets/{document=**}` | Bloqueado | Bloqueado | Criados por callable via Admin SDK |
| `mail/{document=**}` | Bloqueado | Bloqueado | Criados por callable para a extensão Trigger Email |

**Ponto de atenção para produção:** `stats`, `weekly_load` e `insights` são apresentados arquiteturalmente como dados derivados/gerados pelo backend, mas as regras atuais permitem escrita pelo próprio usuário ativo. Para consistência técnica e segurança, recomenda-se tornar esses caminhos read-only para o cliente e manter escrita exclusivamente por Cloud Functions/Admin SDK. O mesmo vale para `cycles`, que hoje aceita escrita de qualquer usuário autenticado.

### 19.6 Regras de Segurança do Cloud Storage (`storage.rules`)

O upload de PDFs é restrito ao caminho:

```text
uploads/{userId}/{fileName}
```

Regras aplicadas:

| Operação | Condição |
|----------|----------|
| `read` | usuário autenticado e `request.auth.uid == userId` |
| `create` | usuário coach-like, `request.auth.uid == userId`, `contentType == "application/pdf"` e tamanho menor que 20 MB |
| `update/delete` | sempre bloqueados |
| Qualquer outro caminho | leitura e escrita bloqueadas |

Essas regras impedem upload de arquivos não-PDF e limitam o vetor de entrada do parser `process_workout_pdf`. A validação de conteúdo, entretanto, continua sendo complementar: o backend também confere `event.data.content_type != "application/pdf"` e ignora arquivos fora do tipo esperado.

### 19.7 Segurança dos Endpoints HTTP (`on_request`)

Dois endpoints são HTTP puros:

| Endpoint | Uso esperado | Validação presente no código |
|----------|--------------|------------------------------|
| `run_weekly_insights_task` | Chamado pelo Cloud Tasks após debounce | Verifica apenas se `uid` existe no JSON |
| `update_cohort_snapshots` | Chamado por Cloud Scheduler externo/manual | Não valida autenticação, método ou origem |

**Risco documentado:** sem proteção adicional, qualquer agente que conheça a URL pode tentar disparar geração semanal para um UID ou executar o job de coortes. A execução usa Admin SDK, então o endpoint não depende das regras do Firestore.

**Recomendação técnica:**
- configurar Cloud Tasks com OIDC token e validar o token no handler;
- configurar Cloud Scheduler com service account e OIDC;
- alternativamente, exigir header assinado/secret e validar método `POST`;
- registrar essa configuração no runbook de implantação.

### 19.8 Privacidade, IA e LGPD

O backend trata dados pessoais e dados de prática esportiva. As principais salvaguardas implementadas são:

- exportação de dados do usuário via `export_user_data`;
- exclusão permanente via `delete_current_user_account`;
- desativação lógica via `accountStatus="disabled"`, que bloqueia IA e notificações;
- preferência `settings/privacy.aiPersonalizationEnabled` para desativar personalização por IA;
- coortes publicadas apenas com no mínimo 5 atletas;
- coleções `cohorts`, `telemetry`, `supportTickets` e `mail` bloqueadas para acesso direto do cliente.

Limitações relevantes: não há anonimização completa dos dados exportados, os prompts enviados ao Gemini contêm contexto de desempenho do atleta, e a retenção/expiração de notificações depende do job `cleanup_expired_notifications`.

---

## 20. Tratamento de Erros

### 20.1 Falha Ruidosa (re-raise) vs. Silenciosa

**Ruidosa — Cloud Functions reententa:**
```python
try:
    run_pdf_parser_logic(event)
except Exception:
    logging.exception("Erro crítico")
    raise  # Cloud Functions vai fazer retry
```

**Silenciosa — operação acessória, não deve bloquear:**
```python
try:
    from ia_module import run_ai_analysis_logic
    run_ai_analysis_logic(event)
except Exception:
    logging.exception("Análise de IA falhou")
    return  # treino publicado com sucesso; análise é acessória
```

A análise de ciclo (`run_cycle_analysis`) também é silenciosa em relação à análise diária: a exceção é capturada e logada, não relançada.

### 20.2 ALREADY_EXISTS no Cloud Tasks

```python
if "ALREADY_EXISTS" in msg or "already exists" in msg.lower():
    logging.info(f"[cloud-tasks] debounce ativo para {uid}")
    return  # comportamento esperado, não é erro
```

### 20.3 Máquina de Estados em exercises/

O campo `statusAnalise` previne reprocessamento:
```python
if status in ['concluida', 'processando', 'erro']:
    logging.info(f"Treino ignorado (Status: {status})")
    return
```

Em caso de erro o status `"erro"` persiste com `erroMsg`. O coach pode ver no app que a análise falhou, sem loop infinito de retentativas.

### 20.4 Falha de LLM Registra Telemetria

```python
except Exception:
    _record_insight_event("weekly", "failed", reason="llm_or_parse_error", ...)
    raise  # para que Cloud Tasks faça retry
```

---

## 21. Testes

### 21.1 Estrutura

| Arquivo | Escopo |
|---------|--------|
| `test_athlete_insight_output_contract.py` | Contrato dos modelos Pydantic (limites, normalização de chaves, clipping de texto) |
| `test_insight_context_builder.py` | Funções de agregação do `context_builder.py` |
| `test_notification_module.py` | Criação, deduplicação, limpeza |
| `test_pdf_parser.py` | Parsing de PDFs com casos de borda |
| `test_pre_workout_logic.py` | Lógica de geração de insights pré-treino |
| `test_prompt.py` | Construção e validação de prompts |
| `test_prompt_enrichment.py` | Enriquecimento de prompts com contexto |
| `test_user_settings_module.py` | Preferências e status de conta |
| `test_account_support_export_modules.py` | Conta, suporte, exportação |

### 21.2 Estratégia

Os testes usam stubs de Firestore (objetos Python que simulam o comportamento do banco) sem dependências de infraestrutura real:

```python
class FakeDoc:
    def __init__(self, data):
        self._data = data
        self.exists = data is not None
    def to_dict(self): return self._data
```

**Testes de contrato de saída:** verificam que os validadores Pydantic truncam mensagens, normalizam chaves, deduplicam, limitam quantidades e rejeitam inputs inválidos.

### 21.3 Ferramenta de Avaliação de Insights (`tools/evaluate_athlete_insights.py`)

Além da suíte de testes unitários, o projeto inclui uma ferramenta de linha de comando para inspeção manual dos três fluxos de insights do atleta diretamente contra o Firestore de produção, sem escrever nenhum dado no banco.

**Uso:**
```bash
# Montar prompt semanal sem chamar o Gemini (inspecionar dados e prompt)
python tools/evaluate_athlete_insights.py \
  --uid <firebase_uid> --flow weekly --no-llm

# Executar fluxo completo: prompt + chamada ao Gemini + checklist de qualidade
python tools/evaluate_athlete_insights.py \
  --uid <firebase_uid> --flow pre_workout --workout-id <exerciseId>

# Avaliar os três fluxos em sequência
python tools/evaluate_athlete_insights.py --uid <uid> --flow all
```

**O que a ferramenta produz:**

| Seção impressa | Conteúdo |
|----------------|----------|
| Resumo dos dados | contexto pré-computado (weekly_context, evolution_context, pre_workout_context) |
| Prompt completo | texto enviado ao Gemini (truncável via `--prompt-max-chars`) |
| Resposta crua | output literal do modelo |
| JSON parseado | resultado após validação Pydantic |
| Checklist de qualidade | presença de número concreto, contraste temporal, marcadores genéricos encontrados, âncoras do treino nos insights |

O checklist de qualidade (`_quality_check`) verifica automaticamente se os insights gerados contêm marcadores genéricos proibidos (ex.: "treinou bem", "precisa descansar"), se há referência temporal ("semana passada", "da última vez") e se os movimentos do treino aparecem nos insights pré-treino. Esta ferramenta foi central no processo iterativo de ajuste dos prompts durante o desenvolvimento.

### 21.4 Execução Local Recomendada

Os testes importam módulos que dependem de `firebase_admin`, `pymupdf`, `pydantic>=2`, LangChain e bibliotecas Google Cloud. Portanto, a execução reprodutível deve instalar as dependências de `functions/requirements.txt` em um ambiente Python isolado:

```bash
cd flutter_app/functions
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt pytest
python -m unittest discover -s tests -v
# ou, se pytest estiver disponível:
python -m pytest -q
```

> A suíte atual é majoritariamente unitária, com stubs/fakes para Firestore. Ela não substitui testes de integração com Firebase Emulator para regras de segurança, Storage, Cloud Tasks e Cloud Scheduler.

---

## 22. Variáveis de Ambiente e Configuração

### 22.1 Injetadas Automaticamente pelo Google Cloud

| Variável | Descrição |
|---------|-----------|
| `GCLOUD_PROJECT` | Project ID (injetado automaticamente) |
| `FIREBASE_CONFIG` | JSON com configuração Firebase (injetado automaticamente) |

### 22.2 Configuráveis pelo Desenvolvedor

| Variável | Padrão | Descrição |
|---------|--------|-----------|
| `WEEKLY_INSIGHTS_QUEUE` | `weekly-insights-queue` | Nome da fila Cloud Tasks |
| `WEEKLY_INSIGHTS_DELAY_SEC` | `300` | Delay base de debounce (segundos) |
| `WEEKLY_INSIGHTS_JITTER_SEC` | `600` | Jitter máximo por UID (segundos) |

### 22.3 Secrets (Google Cloud Secret Manager)

| Secret ID | Módulo consumidor | Acesso |
|-----------|------------------|--------|
| `GEMINI_API_KEY` | `athlete_insights_module`, `ia_module` | Via `SecretManagerServiceClient` em runtime |
| `SUPPORT_EMAIL` | `support_module` | Via `params.SecretParam` → `os.environ.get()` |

### 22.4 Recursos Externos Necessários

| Recurso | Nome/uso | Observação |
|---------|----------|------------|
| Cloud Tasks queue | `weekly-insights-queue` por padrão | Necessária para `_enqueue_weekly_insights_task`; não é criada por `firebase.json` |
| Cloud Scheduler externo | Job diário para `update_cohort_snapshots` | O código expõe endpoint HTTP, mas não declara schedule nativo |
| Secret Manager | `GEMINI_API_KEY`, `SUPPORT_EMAIL` | Devem existir no projeto e ser acessíveis pela service account das Functions |
| Firebase Extension Trigger Email | coleção `mail/` | Necessária para envio real de emails de suporte |

---

## 23. Implantação

### 23.1 Firebase CLI

```bash
cd flutter_app
firebase deploy --only functions          # todas as funções
firebase deploy --only functions:update_athlete_stats  # função específica
firebase deploy --only firestore:rules
firebase deploy --only storage
```

O runtime das Functions é `python311`, definido em `firebase.json`. As regras de Firestore e Storage também são deployadas a partir desse arquivo.

### 23.2 Cloud Functions 2ª Geração

Baseada em Cloud Run. Vantagens em relação à 1ª geração:
- Timeout de até 3600 segundos (vs. 540s)
- Escalonamento mais granular
- Revisões versionadas (rollback sem redeployment)

### 23.3 Emulador Local

```bash
firebase emulators:start --only functions,firestore,storage
```

### 23.4 Cloud Tasks

A fila usada pelo debounce semanal deve existir antes da primeira execução real:

```bash
gcloud tasks queues create weekly-insights-queue \
  --location=us-central1
```

Se o nome for alterado, a variável `WEEKLY_INSIGHTS_QUEUE` deve ser definida no ambiente das Functions. Para produção, recomenda-se configurar chamadas HTTP com OIDC/service account e validar essa identidade no endpoint `run_weekly_insights_task`.

### 23.5 Cloud Scheduler para Coortes

O job diário de coortes não está declarado como `scheduler_fn.on_schedule` no código. Para executar automaticamente, é necessário criar um Scheduler HTTP externo para a URL:

```text
https://us-central1-<PROJECT_ID>.cloudfunctions.net/update_cohort_snapshots
```

Configuração recomendada:

```bash
gcloud scheduler jobs create http motiva-update-cohort-snapshots \
  --location=us-central1 \
  --schedule="30 3 * * *" \
  --time-zone="America/Sao_Paulo" \
  --uri="https://us-central1-<PROJECT_ID>.cloudfunctions.net/update_cohort_snapshots" \
  --http-method=POST \
  --oidc-service-account-email="<SERVICE_ACCOUNT>@<PROJECT_ID>.iam.gserviceaccount.com"
```

O código atual ainda precisa validar o token OIDC/header recebido para que essa proteção fique efetiva no nível da aplicação.

---

## 24. Escalabilidade e Custo

### 24.1 Principais Drivers de Custo

| Serviço | Driver |
|---------|--------|
| Cloud Functions | CPU × tempo × memória (timeout 9 min no pré-treino) |
| Firestore reads | `update_athlete_stats` carrega **todos** os results do atleta |
| Firestore reads | `generate_pre_workout_insights` itera **todos** os usuários |
| Gemini API | Tokens de input (~3.000–8.000 por chamada) |
| Cloud Tasks | 1 task criada por evento de result (debounce reduz execuções) |
| Secret Manager | 1 acesso por chamada ao Gemini (sem cache) |

### 24.2 Otimizações Implementadas

- **Debounce (Cloud Tasks):** N results em < 5 min → 1 chamada ao Gemini
- **Cache de evolução (4 dias):** prompt de 12 semanas (~5.000+ tokens) amortizado
- **LLM compartilhado no pré-treino:** 1 instância para N atletas, 1 chamada ao Secret Manager
- **Collection Group Query no `ia_module`:** 1 query para agregar o contexto semanal da turma (vs. N queries individuais)
- **Jitter anti-pico:** distribui execuções de uma turma ao longo de ~10 minutos

---

## 25. Dívida Técnica e Limitações Conhecidas

### 25.1 Recálculo Total em `update_athlete_stats`

Carrega **todos** os `results/` do atleta a cada evento. Para atletas com histórico longo (1000+ resultados) isso gera custo crescente de leitura. A cascata de carga crônica torna o recálculo incremental complexo.

### 25.2 Iteração Linear sobre Usuários (Pré-Treino e Coortes)

`generate_pre_workout_insights` e `update_cohort_snapshots_logic` iteram `db.collection('users').stream()`. Com milhares de usuários, esta operação aumenta linearmente em custo e tempo.

**Mitigação futura:** manter coleção indexada `athlete_users/` com UIDs de atletas.

### 25.3 WIP no Ciclo Mensal

`overview_stats.registrosCount` e `overview_stats.activeStudentsPct` retornam `0` — marcados como WIP no código-fonte (`ia_module/logic.py:289`).

### 25.4 Parser JSON Simplificado no `ia_module`

O `ia_module/logic.py` usa parsing de JSON manual com split por ` ```json` e ` ``` `. O `athlete_insights_module` usa o parser robusto `llm_parser.py` com tratamento de casos de borda. Esta inconsistência pode causar falhas silenciosas no ia_module se o Gemini retornar JSON em formato inesperado.

### 25.5 `SECRET_MANAGER` sem Cache

`_get_gemini_api_key()` acessa o Secret Manager a cada geração de insights. Instâncias Cloud Functions são reutilizadas entre invocações (warm instances) — cache da chave em memória reduziria o custo de Secret Manager, mas exigiria lógica de invalidação.

### 25.6 Formato de Data em PRs

Dois formatos coexistem (`Timestamp` e string ISO). `_stream_date_docs_since` faz **duas queries separadas** para cobrir os dois formatos, dobrando o custo de leitura em PRs históricos.

### 25.7 Endpoints HTTP Sem Validação Explícita

`run_weekly_insights_task` e `update_cohort_snapshots` são endpoints `on_request` sem validação de origem no código. A mitigação recomendada é usar OIDC em Cloud Tasks/Cloud Scheduler e validar a identidade no handler, ou exigir header assinado/secret compartilhado.

### 25.8 Dados Derivados Graváveis pelo Cliente

As regras atuais permitem que o próprio usuário ativo escreva em `stats`, `weekly_load` e `insights`, embora esses documentos sejam derivados por Cloud Functions. Para reduzir risco de adulteração de métricas e cards de IA, recomenda-se mudar essas regras para leitura pelo dono e escrita apenas via Admin SDK.

### 25.9 Escrita Aberta em `cycles/`

`cycles/{document=**}` permite escrita por qualquer usuário autenticado. Como a coleção armazena análise mensal do coach e dados agregados do planejamento, a regra mais adequada seria permitir escrita apenas para coach-like ou apenas backend, conforme a política do produto.

### 25.10 Configuração Externa Não Versionada

Fila do Cloud Tasks e Scheduler HTTP de coortes não estão versionados em `firebase.json`. Para auditoria acadêmica e reprodutibilidade, recomenda-se criar scripts de infraestrutura ou documentar comandos `gcloud` utilizados no deploy.

---

## 26. Diagrama de Dependências Entre Módulos

```
main.py
  ├── athlete_stats_module
  │     └── (sem dependências internas)
  │
  ├── athlete_insights_module
  │     ├── logic.py
  │     │     ├── prompt_builder.py
  │     │     ├── context_builder.py
  │     │     ├── llm_parser.py
  │     │     └── models.py
  │     ├── pre_workout_logic.py
  │     │     ├── prompt_builder.py
  │     │     ├── context_builder.py
  │     │     ├── llm_parser.py
  │     │     └── models.py
  │     ├── [lazy] cohort_module
  │     ├── [lazy] user_settings_module
  │     ├── [lazy] notification_module
  │     └── [lazy] telemetry_module
  │
  ├── ia_module
  │     ├── logic.py
  │     │     ├── prompt_builder.py
  │     │     └── models.py
  │     ├── [lazy] notification_module
  │     └── [lazy] telemetry_module
  │
  ├── notification_module
  │     └── user_settings_module
  │
  ├── cohort_module
  │     ├── aggregation.py
  │     │     ├── bucketization.py
  │     │     └── [lazy] telemetry_module
  │     ├── bucketization.py
  │     └── matching.py → bucketization.py
  │
  ├── account_module      (sem dependências internas)
  ├── export_module       (sem dependências internas)
  ├── support_module      (sem dependências internas)
  ├── telemetry_module    (sem dependências internas)
  └── user_settings_module (sem dependências internas)
```

**Princípio:** módulos utilitários (`user_settings_module`, `telemetry_module`) não importam outros módulos internos. Módulos de orquestração (`athlete_insights_module`, `ia_module`) usam importação lazy de `cohort_module` e `notification_module` para evitar dependências circulares e isolar falhas de import.

---

*Documentação revisada contra o código-fonte em* `flutter_app/functions/`, `flutter_app/firestore.rules`, `flutter_app/storage.rules` e `flutter_app/firebase.json` *(branch `release_teste_melhoria_parser`)*

*Versão 2.1 — revisada com leitura dos arquivos-fonte: main.py, athlete_stats_module/logic.py, athlete_insights_module/{logic,pre_workout_logic,models,prompt_builder,context_builder,llm_parser}.py, ia_module/{logic,models,prompt_builder}.py, notification_module/logic.py, cohort_module/{aggregation,bucketization,matching}.py, account_module/logic.py, export_module/logic.py, support_module/logic.py, telemetry_module/logic.py, user_settings_module/logic.py, pdf_module/parser.py, requirements.txt e regras Firebase.*
