# PROMPT — Refatoração do Sistema de Carga Semanal (Weekly Load)
# Migração: Fator de Categoria + Baseline Fixo → ACWR Científico

---

## CONTEXTO GERAL

Você está trabalhando no projeto **Motiva**, um app Flutter + Firebase para CrossFit.

O sistema de carga semanal do atleta precisa ser refatorado para remover duas invenções sem validação científica e substituí-las por métodos com respaldo na literatura publicada. As mudanças afetam:

1. A Cloud Function Python (`athlete_stats_module/logic.py`)
2. O documento Firestore `users/{uid}/weekly_load/{weekLabel}`
3. O documento Firestore `users/{uid}/stats/summary`
4. Os services Flutter que leem esses dados
5. Os arquivos de IA do atleta (verificação de impacto)

**Antes de escrever qualquer código**, leia todos os arquivos listados na seção "Arquivos para ler primeiro". Só então implemente as mudanças.

---

## ARQUIVOS PARA LER PRIMEIRO

Leia na seguinte ordem:

```
functions/athlete_stats_module/logic.py
functions/athlete_stats_module/__init__.py
functions/main.py
lib/core/services/athlete_stats_service.dart
lib/core/services/weekly_stats_service.dart
lib/core/services/weekly_summary_service.dart
lib/core/services/effort_service.dart
```

Depois leia os arquivos de IA do atleta (se existirem):
```
functions/athlete_insights_module/logic.py         (ou nome equivalente)
functions/athlete_insights_module/prompt_builder.py
functions/athlete_insights_module/models.py
users/{uid}/weekly_insights/                 (verificar schema no Firestore)
```

Depois leia as telas que consomem os dados:


---

## O QUE MUDA E POR QUÊ

### ❌ O QUE SAI (remover completamente)

#### 1. Fator de categoria
**O que era:**
```python
FATORES_CATEGORIA = {
    'Iniciante':     0.70,
    'Scale':         0.85,
    'Intermediário': 0.95,
    'RX':            1.00,
}
# Usado na fórmula: Carga = RPE × duração × fator_categoria
```

**Por que sai:** invenção sem publicação científica. A justificativa científica para removê-lo é que o Session-RPE mede **carga interna** (percepção subjetiva do atleta), não carga externa. Um iniciante no limite dele reporta RPE 9, um RX no limite dele também reporta RPE 9 — ambos tiveram a mesma carga interna relativa à sua capacidade. Adicionar um fator de categoria introduziria uma correção de carga externa em uma métrica de carga interna, o que é cientificamente inconsistente. Referência: Haddad et al. (2017), Frontiers in Neuroscience.

#### 2. Baselines fixos por categoria
**O que era:**
```python
_CATEGORY_BASELINE_LOAD = {
    'Iniciante':     600,
    'Scale':         900,
    'Intermediário': 1200,
    'RX':            1500,
}
# Usado no cálculo do ICN quando sem histórico
```

**Por que sai:** estimativa nossa sem publicação. Substituído pelo ACWR.

#### 3. ICN com baseline por categoria
**O que era:**
```python
if historical_weeks > 0:
    baseline = mean(cargas_históricas)
else:
    baseline = _CATEGORY_BASELINE_LOAD[categoria_mais_recente]

icn = (carga_atual / baseline) × 50
```

**Por que sai:** a lógica do baseline fixo não tem validação. Substituído pelo ACWR puro.

---

### ✅ O QUE ENTRA (implementar)

#### Nova fórmula de carga (simplificada)
```
Carga diária = RPE × duração_real_minutos
```

Sem multiplicação por fator de categoria. A fórmula base do Session-RPE (Foster, 2001) é usada de forma pura.

#### Novo ICN baseado no ACWR (Gabbett, 2016)
```
ICN = (Carga Aguda / Carga Crônica) × 50

Carga Aguda  = carga total da semana ATUAL
Carga Crônica = média da carga total das últimas 4 semanas completas
                anteriores à semana atual (excluindo a semana atual)
```

**Regra do cold start (atleta novo):**
```python
semanas_completas_anteriores = buscar weekly_load com weekLabel != semana_atual
                               ordenar por weekLabel descending

if len(semanas_completas_anteriores) == 0:
    # Semana 1: sem histórico
    icn_all      = 50.0
    icn_crossfit = 50.0
    carga_cronica = None
    baseline_type = 'cold_start'

elif len(semanas_completas_anteriores) < 4:
    # Semanas 2, 3 e 4: usa o que tem
    carga_cronica = mean([s.totalLoadAll for s in semanas_anteriores])
    icn_all       = (total_load_all / carga_cronica) × 50
    icn_crossfit  = (total_load_crossfit / carga_cronica) × 50
    baseline_type = f'partial_{len(semanas_anteriores)}_weeks'

else:
    # A partir da semana 5: usa exatamente 4 semanas
    ultimas_4 = semanas_completas_anteriores[:4]
    carga_cronica = mean([s.totalLoadAll for s in ultimas_4])
    icn_all       = (total_load_all / carga_cronica) × 50
    icn_crossfit  = (total_load_crossfit / carga_cronica) × 50
    baseline_type = 'historical_4_weeks'

# Clamp em [0, 150] para evitar outliers
icn_all      = min(max(icn_all, 0), 150)
icn_crossfit = min(max(icn_crossfit, 0), 150)
```

**Interpretação do ICN (baseada no ACWR de Gabbett, 2016):**
```
ICN = 50          → Na média histórica (manutenção)
ICN entre 50–75   → Acima da média — zona de evolução segura ("sweet spot")
ICN acima de 75   → Alerta — aumento abrupto de carga, risco de lesão
ICN abaixo de 50  → Abaixo da média — recuperação ou destreinamento
```

---

### ✅ O QUE FICA IGUAL (não alterar)

```python
# Fórmula base Session-RPE — mantida
Carga WOD   = RPE × duração_real_minutos   # sem fator de categoria
Carga OTHER = RPE × durationMinutes        # sem alteração
Carga REST  = 0                            # sem alteração

# Duração real por modalidade — mantida igual
# FOR TIME completou:     forTimeSec / 60
# FOR TIME não completou: cap do WOD
# AMRAP:                  cap do WOD (sempre)
# EMOM completou:         cap do WOD
# EMOM não completou:     emomCompletedRounds

# Monotonia — mantida
monotony = mean(daily_loads) / pstdev(daily_loads)

# Strain — mantido
strain = total_load_all × monotony

# Adaptado — mantido (não penaliza, não altera carga)
# REST como zero — mantido

# Classificação de documentos por sufixo de ID — mantida
# _REST → rest | _OTHER → other | resto → training
```

---

## MUDANÇAS NO FIRESTORE

### Documento `users/{uid}/weekly_load/{weekLabel}`

**Campos a REMOVER:**
```
icnBaselineUsed    ← era: "historical" | "category:RX" | ...
```

**Campos a ALTERAR:**
```
# ANTES:
icnAll:          float   (calculado com baseline fixo ou histórico)
icnCrossfit:     float   (calculado com baseline fixo ou histórico)

# DEPOIS:
icnAll:          float | None   (None apenas no cold_start da semana 1)
icnCrossfit:     float | None   (None apenas no cold_start da semana 1)
```

**Campos a ADICIONAR:**
```
cargaCronica:    float | None   (None se cold_start)
baselineType:    string         ("cold_start" | "partial_N_weeks" | "historical_4_weeks")
acwrRaw:         float | None   (razão pura: carga_aguda / carga_cronica, antes do ×50)
                                 None se cold_start
```

**Campos que NÃO mudam:**
```
weekLabel, weekStart, weekEnd
totalLoadCrossfit, totalLoadOther, totalLoadAll
avgRpeCrossfit, avgRpeAll
wodDays, otherDays, restDays
monotony, strain, restRatio
prsCount
dailyLoadsCrossfit, dailyLoadsOther
updatedAt
```

### Documento `users/{uid}/stats/summary`

**Campos a REMOVER:**
```
(nenhum campo existente é removido — apenas o cálculo interno muda)
```

**Campos que mudam internamente (mesmo nome, novo valor):**
```
weeklyLoadCrossfit  ← continua existindo, mas valor agora calculado sem fator de categoria
weeklyLoadAll       ← idem
```

**Campos a ADICIONAR:**
```
weeklyICN:          float | None   (ICN da semana atual, ou None se cold_start semana 1)
weeklyBaselineType: string         ("cold_start" | "partial_N_weeks" | "historical_4_weeks")
```

---

## IMPLEMENTAÇÃO — PASSO A PASSO

### Passo 1 — `functions/athlete_stats_module/logic.py`

**1a. Remover completamente:**
- O dicionário `FATORES_CATEGORIA` (ou nome equivalente)
- O dicionário `_CATEGORY_BASELINE_LOAD` (ou nome equivalente)
- A variável `categoria_mais_recente` (se usada apenas para baseline)
- A função `_category_factor()` (ou equivalente)
- Qualquer referência a `fator`, `factor`, `categoria_factor` no cálculo de carga

**1b. Alterar a fórmula de carga:**
```python
# ANTES:
carga = effort × duracao × _category_factor(category)

# DEPOIS:
carga = effort × duracao
```

**1c. Alterar o cálculo do ICN:**

Substituir a lógica de baseline fixo pela lógica ACWR descrita acima. O novo cálculo precisa:
1. Buscar os documentos de `users/{uid}/weekly_load/` EXCLUINDO o weekLabel atual
2. Ordenar por weekLabel descending
3. Pegar os primeiros 4 (ou menos se não houver)
4. Calcular média de `totalLoadAll` como Carga Crônica
5. Calcular ICN conforme fórmula

**1d. Adicionar campos novos ao documento weekly_load:**
```python
weekly_load_doc = {
    ...campos existentes sem mudança...,

    # Campos alterados:
    'icnAll':      icn_all,        # float ou None
    'icnCrossfit': icn_crossfit,   # float ou None

    # Campos novos:
    'cargaCronica':  carga_cronica,  # float ou None
    'baselineType':  baseline_type,  # string
    'acwrRaw':       acwr_raw,       # float ou None

    # Campo REMOVIDO (não incluir mais):
    # 'icnBaselineUsed': ...   ← DELETAR desta linha
}
```

**1e. Adicionar campos novos ao stats/summary:**
```python
summary_update = {
    ...campos existentes...,
    'weeklyLoadCrossfit': total_load_crossfit,  # novo valor sem fator
    'weeklyLoadAll':      total_load_all,
    'weeklyICN':          icn_all,              # novo
    'weeklyBaselineType': baseline_type,        # novo
}
```

**1f. Validar matematicamente antes de salvar:**
```python
# Checar consistência antes de gravar
assert total_load_all >= total_load_crossfit, "Consolidado deve ser >= CrossFit"
assert total_load_all == total_load_crossfit + total_load_other, "Soma deve bater"
assert 0 <= monotony or desvio == 0, "Monotonia inválida"
if icn_all is not None:
    assert 0 <= icn_all <= 150, "ICN fora do clamp"
    assert carga_cronica > 0, "Carga crônica não pode ser zero se ICN calculado"
```

---

### Passo 2 — Services Flutter

**2a. `lib/core/services/athlete_stats_service.dart`**

Atualizar o model `AthleteStatsSummary`:
- Adicionar campo `weeklyICN: double?`
- Adicionar campo `weeklyBaselineType: String?`
- Manter todos os outros campos existentes

Atualizar `fromFirestore`:
```dart
weeklyICN:          (data['weeklyICN'] as num?)?.toDouble(),
weeklyBaselineType: data['weeklyBaselineType'] as String?,
```

Adicionar método para buscar histórico de weekly_load:
```dart
static Future<List<WeeklyLoadSummary>> fetchWeeklyLoadHistory({
  int limit = 12,
}) async {
  // Busca os últimos N documentos de users/{uid}/weekly_load/
  // Ordenados por weekLabel descending
  // Retorna lista de WeeklyLoadSummary
}
```

Criar model `WeeklyLoadSummary`:
```dart
class WeeklyLoadSummary {
  final String weekLabel;
  final double totalLoadCrossfit;
  final double totalLoadAll;
  final double? icnAll;
  final double? icnCrossfit;
  final double? cargaCronica;
  final String baselineType;
  final double avgRpeCrossfit;
  final double avgRpeAll;
  final double monotony;
  final double strain;
  final int wodDays;
  final int restDays;
  final int prsCount;
  final DateTime? updatedAt;
}
```

**2b. `lib/core/services/weekly_stats_service.dart`**

- Remover qualquer referência a baseline fixo por categoria
- Atualizar `getWeeklyStat` para ler `weeklyICN` do summary quando tipo = `icn`

**2c. `lib/core/services/weekly_summary_service.dart`**

- Verificar se há qualquer cálculo local usando fator de categoria — remover se existir
- Não alterar a lógica de `fetchEffort`, `fetchStimuliCounts`, `fetchDaysTrained`

---

### Passo 3 — Verificação de impacto na IA do atleta

**Leia os arquivos de IA do atleta e verifique:**

3a. O prompt enviado para o Gemini faz referência a `icnBaselineUsed`?
  - Se sim: substituir por `baselineType`

3b. O prompt usa valores de carga em AU para gerar análise?
  - Se sim: verificar se os valores mudaram significativamente com a remoção do fator de categoria. Os valores de carga para WOD serão maiores agora (RX era ×1,0 então não muda; Scale era ×0,85 então sobe ~18%; Iniciante era ×0,70 então sobe ~43%). Isso pode mudar o tom da análise. Adicionar nota no prompt explicando que a carga é Session-RPE puro sem ajuste de categoria.

3c. O prompt usa `icnAll` ou `icnCrossfit`?
  - Se sim: atualizar a interpretação para usar os limites do ACWR (50 = média, 75 = alerta, >75 = risco)

3d. O modelo de output da IA (`models.py`) referencia campos que foram removidos?
  - Verificar e ajustar se necessário

3e. A Cloud Function de IA é disparada por escrita em `weekly_load`?
  - Se sim: verificar se o novo schema do `weekly_load` não quebra o trigger

**Após verificar, liste explicitamente** o que foi encontrado e o que foi alterado nos arquivos de IA, mesmo que seja "nenhuma alteração necessária".

---

### Passo 4 — Verificação das métricas de estatísticas do aluno

Verifique se os seguintes cálculos no `logic.py` continuam corretos após as mudanças:

```
✓ totalTrainingDays        — não usa carga, não muda
✓ averageEffortAllTime     — usa só effort, não muda
✓ currentWeekTrainingDays  — contagem de dias, não muda
✓ currentWeekStimuli       — usa keyMetrics, não muda
✓ currentWeekCalendar      — usa tipo do doc, não muda
✓ avgRpeCrossfit           — usa só effort, não muda
✓ avgRpeAll                — usa só effort, não muda
✓ monotony                 — usa carga diária sem fator → VERIFICAR se lógica está correta
✓ strain                   — produto de totalLoad × monotony → VERIFICAR
✓ restRatio                — contagem, não muda
✓ prsCount                 — query em /prs, não muda
```

Para monotonia e strain: confirmar que os 7 valores diários usados no cálculo são as cargas sem fator de categoria. Se havia fator na versão anterior, os valores mudam — isso é correto e esperado.

---

### Passo 5 — Validação matemática completa

Após implementar, crie um teste local em Python (pode ser um arquivo temporário `test_logic.py`) que simule os seguintes cenários e verifique os resultados:

**Cenário 1 — Atleta na semana 1 (cold start):**
```
Input: 3 WODs (RPE 7, 20 min cada), sem histórico
Esperado:
  totalLoadCrossfit = 3 × (7 × 20) = 420.0
  icnAll = 50.0
  baselineType = "cold_start"
  cargaCronica = None
```

**Cenário 2 — Atleta na semana 3 (histórico parcial):**
```
Input:
  Semana 1 (histórico): totalLoadAll = 400
  Semana 2 (histórico): totalLoadAll = 450
  Semana 3 (atual): 4 WODs RPE 8, 20 min = 640 AU

Esperado:
  cargaCronica = (400 + 450) / 2 = 425.0
  acwrRaw = 640 / 425 = 1.506
  icnAll = 1.506 × 50 = 75.3  (zona de alerta)
  baselineType = "partial_2_weeks"
```

**Cenário 3 — Atleta com 6 semanas de histórico:**
```
Input:
  Semanas 1–6 (histórico): [500, 520, 480, 600, 550, 510]
  Semana 7 (atual): totalLoadAll = 700

  Apenas as 4 mais recentes contam:
  cargaCronica = (600 + 550 + 510 + 520) / 4 = ?
  (usar as 4 semanas imediatamente anteriores à atual)

Esperado:
  cargaCronica = (600 + 550 + 510 + 520) / 4 = 545.0
  acwrRaw = 700 / 545 = 1.284
  icnAll = 1.284 × 50 = 64.2  (zona de evolução segura)
  baselineType = "historical_4_weeks"
```

**Cenário 4 — Semana de descanso (monotonia):**
```
Input: 5 dias REST, 2 WODs (RPE 6, 15 min)
  cargas diárias = [0, 90, 0, 0, 90, 0, 0]

Esperado:
  totalLoadCrossfit = 180
  media_diaria = 180 / 7 = 25.71
  pstdev = sqrt(variância_populacional)
  monotonia deve ser < 1.0 (distribuição saudável com muitos zeros)
```

**Cenário 5 — Semana de overtraining (strain alto):**
```
Input: 5 WODs consecutivos (RPE 9, 25 min), sem descanso
  cargas diárias = [225, 225, 225, 225, 225, 0, 0]

Esperado:
  totalLoadCrossfit = 1125
  media_diaria = 1125 / 7 ≈ 160.7
  pstdev ≈ 95.7
  monotonia ≈ 1.68  (acima de 1.5 → risco)
  strain ≈ 1890  (alto)
```

Se qualquer cenário falhar, corrija antes de entregar.

---

## CHECKLIST FINAL — verificar antes de entregar

### Cloud Function Python
- [ ] Dicionário de fatores de categoria removido completamente
- [ ] Dicionário de baselines fixos removido completamente
- [ ] Função `_category_factor()` removida (ou equivalente)
- [ ] Fórmula de carga é `RPE × duração` sem multiplicador extra
- [ ] ICN usa Carga Crônica das últimas 4 semanas (ou menos se houver)
- [ ] Semana 1 retorna ICN = 50.0 e `baselineType = 'cold_start'`
- [ ] Campo `icnBaselineUsed` removido do documento weekly_load
- [ ] Campos `cargaCronica`, `baselineType`, `acwrRaw` adicionados ao weekly_load
- [ ] Campos `weeklyICN`, `weeklyBaselineType` adicionados ao stats/summary
- [ ] ICN clamped em [0, 150]
- [ ] Todos os 5 cenários de teste passaram

### Services Flutter
- [ ] `AthleteStatsSummary` tem campos `weeklyICN` e `weeklyBaselineType`
- [ ] `WeeklyLoadSummary` model criado com todos os campos
- [ ] `fetchWeeklyLoadHistory()` implementado
- [ ] Nenhum service Flutter calcula carga localmente com fator de categoria
- [ ] Nenhuma referência a `icnBaselineUsed` nos services

### IA do Atleta
- [ ] Verificação feita e resultado documentado (o que mudou ou "nenhuma alteração")
- [ ] Se o prompt usava `icnBaselineUsed`: atualizado para `baselineType`
- [ ] Se o prompt usava limites antigos de ICN: atualizado para ACWR (50/75/100)
- [ ] Schema do weekly_load não quebra trigger de IA se existir

### Métricas de estatísticas
- [ ] Confirmado que `totalTrainingDays`, `averageEffort*` e `currentWeek*` não mudaram
- [ ] Confirmado que monotonia e strain usam cargas sem fator de categoria
- [ ] Confirmado que a mudança nos valores de carga (sem fator) é esperada e correta

### Regras Firestore
- [ ] Verificar se `weekly_load` e `prs` já têm regras de leitura/escrita
- [ ] Se não tiver, adicionar dentro de `match /users/{userId}`:
```
match /weekly_load/{weekLabel} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## O QUE NÃO FAZER

- Não reescrever `logic.py` do zero — expandir o que existe
- Não alterar o trigger do `main.py` (já está correto)
- Não alterar a lógica de duração por modalidade (FOR TIME / AMRAP / EMOM)
- Não alterar a classificação de documentos por sufixo (_REST / _OTHER / training)
- Não adicionar dependências novas ao `requirements.txt`
- Não alterar o schema de `users/{uid}/results/` (dados de entrada não mudam)
- Não alterar `users/{uid}/prs/` (schema não muda)

---

## REFERÊNCIAS CIENTÍFICAS DAS MUDANÇAS

Para justificar cada decisão implementada:

- **Remoção do fator de categoria:** HADDAD, M. et al. Session-RPE Method for Training Load Monitoring: Validity, Ecological Usefulness, and Influencing Factors. *Frontiers in Neuroscience*, v. 11, art. 612, 2017. (O RPE é válido "among various expertise levels" — não requer ajuste por nível)

- **Fórmula base:** FOSTER, C. et al. A new approach to monitoring exercise training. *Journal of Strength and Conditioning Research*, v. 15, n. 1, p. 109–115, 2001.

- **ACWR como base do novo ICN:** GABBETT, T. J. The training-injury prevention paradox: should athletes be training smarter and harder? *British Journal of Sports Medicine*, v. 50, n. 4, p. 273–280, 2016.

- **Monotonia e Strain:** FOSTER, C. Monitoring training in athletes with reference to overtraining syndrome. *Medicine and Science in Sports and Exercise*, v. 30, n. 7, p. 1164–1168, 1998.

- **Validação do Session-RPE no CrossFit/HIFT:** MUÑOZ-MARTÍNEZ, F. A. et al. Validity, Reliability, and Application of the Session-RPE Method for Quantifying Training Loads during High Intensity Functional Training. *PMC*, 2018.
