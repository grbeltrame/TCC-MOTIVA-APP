# functions/athlete_insights_module/prompt_builder.py
#
# Prompts para a IA que fala DIRETAMENTE com o atleta.
#
# Regra fundamental — "Dicionário do Atleta":
#   - NUNCA usar termos técnicos: "Monotonia", "Strain", "ICN", "ACWR",
#     "Session-RPE", "AU", "CV", "Desvio Padrão", "Carga Crônica", "baseline".
#   - A IA recebe TODOS os dados + um glossário explicando o que cada campo
#     significa. Ela deve INTERPRETAR o cenário e traduzir para o atleta em
#     linguagem humana.
#   - Sem thresholds hardcoded: cabe à IA ponderar os números.
#
# Tom: empático, curto, motivacional. Como um personal trainer atento,
# nunca como um cientista.

import json
from typing import Any, Dict, Optional
from datetime import datetime

from .models import (
    get_weekly_parser,
    get_evolution_parser,
    get_pre_workout_parser,
)


# Nomes em PT-BR para o bloco de estágio da semana.
_WEEKDAY_PT = [
    'SEGUNDA-FEIRA', 'TERÇA-FEIRA', 'QUARTA-FEIRA',
    'QUINTA-FEIRA', 'SEXTA-FEIRA', 'SÁBADO', 'DOMINGO',
]
_MONTH_PT = [
    '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
]


def _json_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()
    return str(o)


def _cohort_context_block(cohort: Optional[Dict[str, Any]]) -> str:
    """
    Bloco de contexto da coorte do atleta (pré-computado em cohorts/{key}).
    Se a coorte não está disponível (perfil incompleto, < 5 atletas), o
    bloco vira string vazia e o prompt segue sem comparação.

    Inclui REGRAS RÍGIDAS de framing positivo: jamais comparação negativa.
    """
    if not cohort:
        return ""

    level   = cohort.get('level')
    cat     = cohort.get('category') or '?'
    gender  = cohort.get('gender') or '?'
    bucket  = cohort.get('experienceBucket')
    count   = cohort.get('athleteCount') or 0
    metrics = cohort.get('metrics') or {}

    # Descreve a coorte em PT-BR amigável.
    gender_pt    = {'M': 'masculino', 'F': 'feminino'}.get(gender, gender)
    bucket_pt = {
        'lt1y':  'menos de 1 ano de prática',
        '1-3y':  '1 a 3 anos de prática',
        '3-5y':  '3 a 5 anos de prática',
        'gt5y':  'mais de 5 anos de prática',
    }.get(bucket or '', '')

    label_parts = [f'categoria {cat}', f'gênero {gender_pt}']
    if bucket_pt:
        label_parts.append(bucket_pt)
    cohort_label = ', '.join(label_parts)

    metrics_json = json.dumps(metrics, ensure_ascii=False, indent=2)

    return (
        "**CONTEXTO DA COORTE DO ATLETA (atletas com perfil parecido):**\n"
        f"- Perfil da coorte: {cohort_label}.\n"
        f"- Total de atletas no grupo: {count}.\n"
        f"- Nível de specifidade: {level} "
        f"({'level 3 — refinado por experiência' if level == 3 else 'level 2 — fallback (sem bucket de experiência)'}).\n"
        f"- Métricas agregadas da semana atual:\n```json\n{metrics_json}\n```\n"
        "\n"
        "**REGRAS DE FRAMING COMPARATIVO (RÍGIDAS):**\n"
        "- ❌ JAMAIS use comparação negativa. Proibido:\n"
        "    'Você está pior que perfis parecidos'\n"
        "    'Atletas como você rendem mais que você essa semana'\n"
        "    'Sua carga está abaixo da sua coorte'\n"
        "- ✅ USE como reforço positivo, validação ou contextualização:\n"
        "    'Atletas com perfil parecido também sentem dificuldade em FOR"
        " TIME longos — você está dentro da média'\n"
        "    'Você se destaca em AMRAP em relação ao seu perfil'\n"
        "    'A semana tem sido puxada para perfis como o seu — não está"
        " só nessa'\n"
        "- ⚖️ Se o atleta está PIOR que a média da coorte, NÃO mencione."
        " Foque nos pontos positivos dele individualmente.\n"
        "- ⚖️ Se está MELHOR ou IGUAL, pode destacar: validação ('está"
        " no ritmo do grupo') ou conquista ('está acima da média').\n"
        "- 🎯 Use a coorte para gerar NO MÁXIMO 1-2 insights de"
        " comparação — não transforme tudo em comparativo. A maioria"
        " dos insights ainda deve ser sobre o atleta individualmente.\n"
        "- 🎯 Se a coorte é level 2 (fallback), seja mais cauteloso na"
        " linguagem comparativa: 'atletas da sua categoria' em vez de"
        " 'atletas com seu tempo de prática'.\n"
    )


def _week_stage_context(now: datetime, week_start: datetime) -> str:
    """
    Bloco de contexto temporal para que a IA calibre tempo verbal e
    profundidade dos insights conforme o estágio da semana.

    A IA recebe o estágio JÁ COMPUTADO (não precisa fazer aritmética
    de data — modelos LLM são ruins nisso). A função é determinística
    e testável.
    """
    # day_index: 1 = primeiro dia da semana (domingo), 7 = sábado.
    day_index = (now.date() - week_start.date()).days + 1
    day_index = max(1, min(7, day_index))
    progress_pct = round((day_index / 7.0) * 100)

    weekday_pt = _WEEKDAY_PT[now.weekday()]
    date_pt = f'{now.day} de {_MONTH_PT[now.month]} de {now.year}'

    if day_index <= 2:
        stage = 'INÍCIO'
    elif day_index <= 5:
        stage = 'MEIO'
    else:
        stage = 'FIM'

    return (
        "**ESTÁGIO DA SEMANA (calibre seus insights por aqui):**\n"
        f"- Hoje é {weekday_pt}, {date_pt}.\n"
        f"- Dia {day_index} de 7 da semana corrente "
        f"(~{progress_pct}% concluída).\n"
        f"- Estágio: {stage}.\n"
        "\n"
        "Calibre seus insights conforme o estágio:\n"
        "- INÍCIO (dia 1-2): foque em INTENÇÃO e PRÓXIMOS DIAS. Ainda"
        " não há padrão semanal — NÃO fale em 'variação',"
        " 'monotonia', 'queda de carga' ou 'pouca variação na semana'."
        " Use o histórico anterior como referência se quiser comparar.\n"
        "- MEIO (dia 3-5): MISTURE leitura do que está se desenhando +"
        " projeção. Pode comentar tendência ('os primeiros dias têm"
        " sido'), mas evite conclusões fechadas sobre a semana toda.\n"
        "- FIM (dia 6-7): pode falar com confiança sobre o que JÁ"
        " aconteceu na semana, usar passado para padrões consolidados.\n"
        "\n"
        "**TEMPO VERBAL:**\n"
        "- O tempo verbal deve refletir onde você está no tempo. Use"
        " passado APENAS para o que já é fato consolidado. Presente"
        " para o que está acontecendo. Futuro próximo para o que"
        " ainda virá.\n"
        "- Você TEM A INTELIGÊNCIA para misturar tempos quando faz"
        " sentido — exemplo na quinta-feira (dia 5):\n"
        "    ✓ 'A semana TEM SIDO puxada — os próximos dias VÃO"
        " determinar se você desacelera.'\n"
        "    ✓ 'Você descansou bem nos primeiros dias — agora ESTÁ"
        " na hora de buscar volume.'\n"
        "- Evite generalizar para a semana inteira no início:\n"
        "    ✗ 'Sua semana TEVE pouca variação' (no domingo, dia 1)\n"
        "    ✓ 'A semana ESTÁ começando — mantenha a regularidade.'\n"
    )


def _common_rules() -> str:
    return (
        "**CONTEXTO TEÓRICO PARA A SUA ANÁLISE (NÃO REPASSE ESTES TERMOS AO ATLETA):**\n"
        "- **ACWR / ICN (Gabbett, 2016):** ICN=50 representa manutenção (carga"
        " da semana = média das últimas 4). A faixa 40-65 é o 'sweet spot'"
        " evolutivo — progride sem risco excessivo. Acima de 75 indica que"
        " o volume subiu muito rápido e literalmente dobra o risco de lesão"
        " (Gabbett: ACWR >1.5 = ~2x chance de lesão na semana seguinte).\n"
        "- **Session-RPE (Foster, 2001):** Mede CARGA INTERNA, não externa."
        " Um RPE 9 de iniciante desgasta o corpo tanto quanto um RPE 9 de"
        " atleta de elite — a escala é subjetiva e individual. Nunca assuma"
        " que 'o treino foi leve' baseado em dados externos.\n"
        "- **Monotonia (Foster):** Indica falta de variação na carga diária."
        " Treinar todo dia 'médio/forte' sem descanso real (monotonia >1.5)"
        " aumenta risco de overtraining mesmo com volume total moderado.\n"
        "- **Strain:** Desgaste sistêmico acumulado = carga × monotonia."
        " Strain alto combinado com monotonia alta é o cenário clássico de"
        " esgotamento mesmo antes do ICN disparar.\n"
        "\n"
        "**DICIONÁRIO DO ATLETA — REGRAS RÍGIDAS DE LINGUAGEM:**\n"
        "- NUNCA use: 'Monotonia', 'Strain', 'ICN', 'ACWR', 'Session-RPE',"
        " 'AU', 'unidades arbitrárias', 'desvio padrão', 'carga crônica',"
        " 'baseline', 'semana base', 'sweet spot'.\n"
        "- Traduza sempre para linguagem humana:\n"
        "  * Monotonia alta → 'Sua semana teve pouca variação de intensidade'\n"
        "  * Strain alto   → 'Você acumulou bastante desgaste'\n"
        "  * ICN alto      → 'Seu volume ficou bem acima do seu normal'\n"
        "  * ICN baixo     → 'Sua carga caiu em relação ao seu normal'\n"
        "  * Carga alta    → 'Você treinou pesado / em volume elevado'\n"
        "  * Esforço alto  → 'Você sentiu os treinos mais puxados'\n"
        "- Fale diretamente com o atleta em 2ª pessoa ('você').\n"
        "- Tom: empático, motivacional, curto. Nada de jargão técnico.\n"
        "- NUNCA cite os números crus internos (ex: 'ICN 82', 'monotonia 1.8').\n"
        "  Se precisar quantificar, traduza em linguagem comum"
        " ('quase todos os dias com a mesma intensidade').\n"
    )


def _weekly_glossary() -> str:
    """Explica os campos de weekly_load e stats/summary para a IA."""
    return (
        "**GLOSSÁRIO DOS CAMPOS (para SUA interpretação — NÃO expor ao atleta):**\n"
        "\n"
        "**weekly_load (semana atual):**\n"
        "- `totalLoadAll`: carga total da semana = soma de (esforço × duração)"
        " de TODOS os registros (WODs + atividades externas). Quanto maior,"
        " maior o volume total.\n"
        "- `totalLoadCrossfit`: mesma soma, só contando WODs oficiais.\n"
        "- `totalLoadOther`: idem, só atividades externas (corrida,"
        " musculação etc.).\n"
        "- `cargaCronica`: média da carga semanal das últimas 4 semanas"
        " (ou menos, ver `baselineType`). É o 'normal recente' do atleta.\n"
        "- `acwrRaw`: razão entre carga da semana atual e a carga crônica."
        " Guia de interpretação (Gabbett, 2016):\n"
        "    <0.8  → destreino / subcarga\n"
        "    0.8–1.3 → zona ótima / sustentável\n"
        "    1.3–1.5 → alerta leve de aumento brusco\n"
        "    >1.5  → zona de alto risco de lesão\n"
        "- `icnAll`: índice normalizado = acwrRaw × 50, limitado a [0,150].\n"
        "    ≈50   → em linha com o normal\n"
        "    <40   → bem abaixo do normal\n"
        "    60–75 → acima do normal, sustentável\n"
        "    75–100 → alerta (aumento importante)\n"
        "    >100  → risco claro\n"
        "- `icnCrossfit`: mesma lógica, só considerando WODs.\n"
        "- `baselineType`:\n"
        "    'cold_start'          → atleta sem histórico suficiente (semana 1)."
        " NÃO fale em 'comparação com semanas anteriores' nesse caso.\n"
        "    'partial_N_weeks'     → tem N semanas anteriores (N<4)."
        " Use comparação com cautela, falando em 'últimas semanas'.\n"
        "    'historical_4_weeks'  → base sólida de 4+ semanas."
        " Comparações são totalmente válidas.\n"
        "- `avgRpeAll`: esforço médio percebido na semana (0–10)."
        " Lembre-se: 7-8 é 'puxado', 9-10 é 'máximo'.\n"
        "- `avgRpeCrossfit`: idem, só WODs.\n"
        "- `wodDays`: dias com WOD oficial.\n"
        "- `otherDays`: dias com atividade externa.\n"
        "- `restDays`: dias de descanso explícito.\n"
        "- `monotony`: indicador de repetitividade dos dias."
        " Guia (Foster, 2001): <1.0 variada; 1.0-1.5 ok; >1.5 pouca variação"
        " (acumulo de risco); >2.0 muito repetitiva.\n"
        "- `strain`: desgaste acumulado = totalLoad × monotony."
        " Valores altos combinados com monotonia alta = alerta.\n"
        "- `restRatio`: fração da semana descansada.\n"
        "- `prsCount`: recordes pessoais batidos nessa semana.\n"
        "- `dailyLoadsCrossfit` / `dailyLoadsOther`: carga por dia (0 = sem"
        " treino). Útil para ver se houve picos isolados ou excesso consecutivo.\n"
        "\n"
        "**stats/summary (consolidado do atleta):**\n"
        "- `totalTrainingDays`: total histórico de dias treinados.\n"
        "- `averageEffortAllTime`, `averageEffortCurrentMonth`,"
        " `averageEffortCurrentWeek`: esforço médio percebido em cada janela.\n"
        "- `currentMonthTrainingDays` / `currentWeekTrainingDays`: frequência"
        " recente.\n"
        "- `currentWeekStimuli`: dict com contagem de estímulos da semana"
        " (ex: {'Força': 3, 'Ritmo': 2}). Use pra ver se algum estímulo está"
        " dominando ou ausente.\n"
        "- `currentWeekCalendar`: array com o que aconteceu em cada dia"
        " (WOD/OTHER/REST/vazio).\n"
        "- `weeklyICN`, `weeklyBaselineType`: atalhos dos mesmos campos do"
        " weekly_load (para referência rápida).\n"
    )


def create_weekly_insights_prompt(
    stats_summary: Dict[str, Any],
    weekly_load: Dict[str, Any],
    recent_results: list,
    recent_weeks: list = None,
    now: Optional[datetime] = None,
    cohort: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Prompt da análise SEMANAL do atleta.

    A IA recebe TODOS os campos de weekly_load + stats/summary + histórico
    recente, com um glossário explicando o que cada um significa e como
    interpretá-lo. Não há thresholds hardcoded: a IA decide o que merece
    virar alerta/informação.
    """
    stats_json = json.dumps(
        stats_summary, indent=2, ensure_ascii=False, default=_json_converter
    )
    load_json = json.dumps(
        weekly_load, indent=2, ensure_ascii=False, default=_json_converter
    )
    recent_json = json.dumps(
        recent_results, indent=2, ensure_ascii=False, default=_json_converter
    )
    history_json = json.dumps(
        recent_weeks or [], indent=2, ensure_ascii=False, default=_json_converter
    )

    has_history = bool(recent_weeks)
    baseline_type = (weekly_load or {}).get('baselineType', 'cold_start')

    # Estágio da semana — só injeta se 'now' e o weekStart estão disponíveis.
    week_stage_block = ""
    week_start_str = (weekly_load or {}).get('weekStart')
    if now is not None and week_start_str:
        try:
            week_start_dt = datetime.strptime(week_start_str, '%Y-%m-%d')
            # Replica tzinfo do `now` para evitar erro de comparação naive/aware.
            if now.tzinfo is not None:
                week_start_dt = week_start_dt.replace(tzinfo=now.tzinfo)
            week_stage_block = _week_stage_context(now, week_start_dt) + "\n"
        except ValueError:
            pass

    cohort_block = _cohort_context_block(cohort)

    parser = get_weekly_parser()
    json_instructions = parser.get_format_instructions()

    prompt = (
        "Você é um assistente pessoal de CrossFit que conversa com o ATLETA.\n"
        "Sua missão: transformar TODOS os dados da semana em insights humanos,"
        " curtos e acionáveis. Analise o cenário como um todo — não use"
        " thresholds fixos, pondere os números em conjunto com o histórico e"
        " com o perfil do atleta.\n\n"

        f"{week_stage_block}"

        f"{cohort_block}"

        f"{_common_rules()}\n"

        "**REGRA ABSOLUTA DE TOM:**\n"
        "- NUNCA faça perguntas ao atleta. Ele não pode te responder.\n"
        "- Sempre use afirmações motivacionais. Troque perguntas por"
        " orientações diretas.\n"
        "  ✗ Errado: 'Foi descanso intencional ou falta de tempo?'\n"
        "  ✓ Correto: 'Descanso é parte do treino, mas mantenha o ritmo"
        " na próxima semana.'\n\n"

        f"{_weekly_glossary()}\n"

        "**DADOS COMPLETOS DA SEMANA DO ATLETA:**\n"
        f"1) Resumo consolidado (stats/summary):\n```json\n{stats_json}\n```\n\n"
        f"2) Carga da semana atual (weekly_load):\n```json\n{load_json}\n```\n\n"
        f"3) Registros da semana:\n```json\n{recent_json}\n```\n\n"
    )

    if has_history:
        prompt += (
            f"4) Histórico das últimas semanas:\n```json\n{history_json}\n```\n\n"
        )

    prompt += (
        "---\n"
        "**CONTEXTO DO BASELINE:**\n"
        f"- baselineType atual: `{baseline_type}`.\n"
        "- Se 'cold_start': NUNCA diga 'acima/abaixo do seu normal' — o"
        " atleta ainda não tem histórico. Foque em observações da própria"
        " semana (variação, descanso, esforço, estímulos).\n"
        "- Se 'partial_N_weeks': você pode comparar, mas usando linguagem"
        " como 'nas últimas semanas', sem afirmar um padrão consolidado.\n"
        "- Se 'historical_4_weeks': você pode falar com confiança sobre"
        " 'seu normal dos últimos tempos'.\n\n"

        "---\n"
        "**INSTRUÇÕES DE CRUZAMENTO DE DADOS (faça antes de escrever os"
        " insights):**\n"
        "Você deve ATIVAMENTE cruzar variáveis para extrair insights"
        " profundos — não se limite a ler um campo por vez.\n"
        "\n"
        "1. **avgRpe × currentWeekStimuli** — O atleta reporta RPE máximo"
        " (9-10) sempre ligado a algum estímulo específico? (ex: sempre em"
        " dias de Resistência). Isso pode indicar deficiência naquele"
        " estímulo ou que ele é o gargalo atual.\n"
        "\n"
        "2. **dailyLoadsCrossfit — Padrões de microciclo:** Olhe a sequência"
        " diária. REGRA: se houver 3 ou mais dias seguidos de carga alta"
        " (dias com load >0 sem 0 entre eles, e com cargas acima da média"
        " do atleta), gere um alerta focado em NECESSIDADE DE RECUPERAÇÃO."
        " Dias zerados são descanso — valorize a distribuição.\n"
        "\n"
        "3. **modalidade dos recent_results** — Identifique se alguma"
        " modalidade (AMRAP, FOR TIME, EMOM, etc.) tem RPE consistentemente"
        " menor/maior que as outras. Se houver padrão claro, destaque:"
        " 'você rende melhor em AMRAP' ou 'FOR TIME tem sido seu maior"
        " desafio'.\n"
        "\n"
        "4. **icnAll + monotony + restDays combinados** — icn alto isolado"
        " pode ser sustentável; icn alto + monotonia alta + poucos restDays"
        " é cenário clássico de esgotamento. Combine os três antes de"
        " decidir o peso do alerta.\n"
        "\n"
        "5. **currentWeekStimuli vs. histórico** — Se possível, veja se"
        " algum estímulo está dominando há várias semanas ou se algum"
        " sumiu. Desequilíbrios sustentados viram alertas de médio prazo.\n"

        "---\n"
        "**INSTRUÇÕES DE ANÁLISE:**\n\n"

        "**1. ALERTAS (`alertas`)** — riscos, excessos, faltas de descanso,"
        " quedas de consistência, monotonia alta, desgaste acumulado, ICN"
        " em zona de alerta/risco, ausência prolongada de algum estímulo,"
        " microciclos sem recuperação.\n"
        "- NÃO invente. Só gere alerta se os dados justificam.\n"
        "- Considere o BASELINE ao interpretar — cold_start nunca deve"
        " gerar alerta de 'carga acima do normal'.\n"
        "- **REGRA ESTRITA — ALERTAS ACIONÁVEIS:** todo alerta DEVE"
        " terminar com uma sugestão PRÁTICA de ação. Exemplos:\n"
        "    ✓ 'Você emendou vários dias puxados seguidos. Considere um"
        " treino adaptado ou um day off amanhã.'\n"
        "    ✓ 'Sua semana foi muito repetitiva em intensidade. Alterne"
        " um dia leve no próximo ciclo para recuperar.'\n"
        "    ✗ 'Seu volume subiu muito.' (sem ação — INVÁLIDO)\n"
        "- Se nada merece alerta, retorne `alertas: {}`.\n"
        "- Chaves sugeridas (use as que se aplicam):"
        " 'desgaste_acumulado', 'carga_acima_normal', 'falta_variacao',"
        " 'sem_descanso', 'esforco_alto', 'queda_frequencia',"
        " 'estimulo_ausente', 'risco_lesao', 'microciclo_sem_pausa',"
        " 'gargalo_modalidade'.\n\n"

        "**2. INFORMAÇÕES (`informacoes`)** — conquistas, consistência, boas"
        " tendências, estímulos bem distribuídos, PRs, dicas práticas,"
        " modalidades em que o atleta brilha.\n"
        "- Sempre tente achar pelo menos 2 pontos positivos (mesmo em"
        " semanas ruins, valorize o que o atleta fez bem).\n"
        "- Use comparações com o histórico quando disponível.\n"
        "- Destaque PRs quando houver.\n"
        "- Destaque modalidades/estímulos onde o atleta rende melhor.\n"
        "- Chaves sugeridas: 'constancia_boa', 'melhor_semana',"
        " 'estimulo_dominante', 'dica_recuperacao', 'prs_batidos',"
        " 'equilibrio_estimulos', 'volume_saudavel', 'modalidade_forte',"
        " 'recuperacao_adequada'.\n\n"

        "**3. PROCESSO DE GERAÇÃO (siga em duas etapas):**\n"
        "- **Etapa 1 (interna):** Gere MUITOS candidatos — idealmente"
        " 10 ou mais — cruzando todas as variáveis que fizerem sentido.\n"
        "- **Etapa 2 (saída):** SELECIONE os **6 insights mais relevantes**"
        " no total (alertas + informações somados). Priorize os que:\n"
        "    (a) envolvem cruzamento de múltiplas variáveis;\n"
        "    (b) são acionáveis;\n"
        "    (c) trazem informação não-óbvia para o atleta.\n"
        "- **Distribuição obrigatória:** NUNCA retorne só alertas ou só"
        " informações. Sempre misture — no mínimo 1 de cada lado."
        " Distribuição típica: 2-3 alertas + 3-4 informações em semanas"
        " de risco; 1-2 alertas + 4-5 informações em semanas saudáveis.\n\n"

        "**4. REGRAS GERAIS:**\n"
        "- Cada mensagem: no máximo 240 caracteres (o alerta acionável"
        " costuma precisar de um pouco mais de espaço).\n"
        "- Texto corrido, sem listas dentro das mensagens.\n"
        "- 2ª pessoa, sem nome próprio, ZERO perguntas.\n"
        "- Evite redundância: não repita a mesma ideia com palavras"
        " diferentes.\n"
        "---\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        "1. APENAS JSON válido, sem texto fora.\n"
        "2. Sem markdown dentro dos valores.\n"
        f"{json_instructions}\n"
    )
    return prompt


def _evolution_glossary() -> str:
    return (
        "**GLOSSÁRIO DOS CAMPOS (para SUA interpretação):**\n"
        "- `last_12_weeks`: lista cronológica (asc) dos weekly_load. Cada"
        " item tem os mesmos campos da análise semanal: totalLoadAll,"
        " icnAll, acwrRaw, cargaCronica, baselineType, avgRpeAll, wodDays,"
        " restDays, monotony, strain, prsCount etc.\n"
        "- Compare as 12 semanas entre si para achar TENDÊNCIAS:\n"
        "    • Carga vem subindo/caindo de forma sustentada?\n"
        "    • ICN tem ficado em zona saudável (<75) ou repetidamente alto?\n"
        "    • Monotonia tem aumentado? (rotina ficando repetitiva)\n"
        "    • Frequência (wodDays) tem oscilado ou se mantido?\n"
        "    • Strain acumulado em semanas seguidas?\n"
        "- `prs_summary.count`: total de PRs nas 12 semanas."
        " `byMovement` mostra em quais movimentos o atleta progrediu.\n"
        "- `stimulus_distribution`: contagem consolidada de estímulos"
        " (keyMetrics) nas 12 semanas. Revela estímulos dominantes e"
        " negligenciados.\n"
        "- `stats_summary`: snapshot atual (frequência, esforço médio,"
        " carga da última semana).\n"
    )


def create_evolution_insights_prompt(
    stats_summary: Dict[str, Any],
    last_12_weeks: list,
    prs_summary: Dict[str, Any],
    stimulus_distribution: Dict[str, int],
    cohort: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Prompt da análise de EVOLUÇÃO (12 semanas).

    A IA recebe a série completa de 12 semanas + PRs + distribuição de
    estímulos + summary atual. Deve identificar tendências de médio prazo.
    """
    stats_json = json.dumps(
        stats_summary, indent=2, ensure_ascii=False, default=_json_converter
    )
    weeks_json = json.dumps(
        last_12_weeks, indent=2, ensure_ascii=False, default=_json_converter
    )
    prs_json = json.dumps(
        prs_summary, indent=2, ensure_ascii=False, default=_json_converter
    )
    stimulus_json = json.dumps(
        stimulus_distribution, indent=2, ensure_ascii=False,
        default=_json_converter,
    )

    cohort_block = _cohort_context_block(cohort)

    parser = get_evolution_parser()
    json_instructions = parser.get_format_instructions()

    prompt = (
        "Você é um assistente pessoal de CrossFit analisando a EVOLUÇÃO do"
        " atleta nos últimos 3 meses (até 12 semanas).\n"
        "Sua missão: encontrar tendências de médio prazo nos dados e traduzir"
        " em linguagem humana e motivacional.\n\n"

        f"{cohort_block}"

        f"{_common_rules()}\n"

        "**REGRA ABSOLUTA DE TOM:**\n"
        "- NUNCA faça perguntas ao atleta.\n"
        "- Mesmo ao apontar risco, soe encorajador.\n\n"

        f"{_evolution_glossary()}\n"

        "**DADOS DO ATLETA (até 12 semanas):**\n"
        f"1) Snapshot atual:\n```json\n{stats_json}\n```\n\n"
        f"2) Série semanal (cronológica):\n```json\n{weeks_json}\n```\n\n"
        f"3) PRs no período:\n```json\n{prs_json}\n```\n\n"
        f"4) Distribuição consolidada de estímulos:\n```json\n{stimulus_json}\n```\n\n"

        "---\n"
        "**INSTRUÇÕES DE CRUZAMENTO DE DADOS (faça antes de escrever os"
        " insights):**\n"
        "Você deve cruzar múltiplas dimensões — nada de olhar um campo por"
        " vez. Os insights mais valiosos vêm das correlações.\n"
        "\n"
        "1. **stimulus_distribution × prs_summary.byMovement** —"
        " Causa e efeito da progressão. Os PRs estão concentrados em"
        " movimentos cujos estímulos (ex: 'Força') são dominantes na"
        " distribuição? Ou ao contrário, um estímulo negligenciado coincide"
        " com falta de PRs nos movimentos dependentes dele? Verbalize:"
        " 'Seus recordes vieram nos movimentos que você mais trabalhou' ou"
        " 'A falta de progressão em X pode estar ligada à pouca prática de"
        " [estímulo]'.\n"
        "\n"
        "2. **Validação do Sweet Spot — PRs × ICN semana-a-semana** —"
        " Cruze a semana em que cada PR aconteceu (via weekLabel) com o"
        " icnAll daquela semana. Em que zona de fadiga este atleta ESPECÍFICO"
        " costuma render melhor? Alguns quebram PR em ICN baixo (descansados);"
        " outros em ICN médio-alto (em ritmo). Descubra o padrão DELE e"
        " avise-o em linguagem humana (ex: 'você costuma bater seus"
        " recordes em semanas mais leves — vale priorizar descanso antes"
        " de tentar números novos').\n"
        "\n"
        "3. **Tendência de ICN ao longo das 12 semanas** — A série está"
        " subindo progressivamente (progressão saudável), oscilando em"
        " zona segura (manutenção), ou passando tempo demais >75"
        " (fadiga crônica)?\n"
        "\n"
        "4. **Monotonia crônica × PRs** — Várias semanas com monotonia"
        " alta seguidas geralmente correlacionam com estagnação. Confirme"
        " isso com a janela de PRs.\n"
        "\n"
        "5. **Frequência (wodDays semana-a-semana) × consistência de"
        " estímulos** — Frequência estável com bom mix de estímulos é o"
        " cenário ideal. Frequência oscilante ou estímulo dominante por"
        " muitas semanas viram informações estratégicas.\n"

        "---\n"
        "**INSTRUÇÕES DE ANÁLISE:**\n\n"

        "**1. ALERTAS (`alertas`)** — tendências de risco sustentadas.\n"
        "- Queda prolongada de volume/frequência.\n"
        "- Sequência de semanas com ICN alto (>75) ou monotonia alta.\n"
        "- Estímulos negligenciados (muito abaixo dos demais na distribuição).\n"
        "- Períodos longos sem PR em movimentos que o atleta costumava"
        " progredir.\n"
        "- Strain acumulado em várias semanas seguidas.\n"
        "- **REGRA ESTRITA — ALERTAS ACIONÁVEIS:** todo alerta DEVE vir"
        " com sugestão prática de ação. Ex: 'reduza um dia na próxima"
        " semana', 'adicione um treino focado em [estímulo negligenciado]',"
        " 'priorize descanso antes de tentar novos números'.\n"
        "- Se tudo está saudável, retorne `alertas: {}`.\n"
        "- Chaves sugeridas: 'volume_em_queda', 'estimulo_negligenciado',"
        " 'desgaste_sustentado', 'pausa_progressao', 'monotonia_cronica',"
        " 'icn_alto_sustentado', 'estagnacao_pr', 'desequilibrio_estimulo'.\n\n"

        "**2. INFORMAÇÕES (`informacoes`)** — conquistas e direcionamento"
        " estratégico.\n"
        "- Destaque PRs batidos ('você bateu N recordes nesses 3 meses').\n"
        "- Causa e efeito: relacione PRs aos estímulos que os produziram.\n"
        "- Zona de fadiga ótima DESTE atleta (a partir do cruzamento PRs×ICN).\n"
        "- Progressão saudável de volume/consistência.\n"
        "- Sugira 1 foco estratégico para o próximo ciclo.\n"
        "- Chaves sugeridas: 'prs_periodo', 'evolucao_volume',"
        " 'foco_proximo_ciclo', 'estimulo_dominante_periodo',"
        " 'consistencia_longa', 'zona_otima_rendimento',"
        " 'relacao_pr_estimulo'.\n\n"

        "**3. PROCESSO DE GERAÇÃO (siga em duas etapas):**\n"
        "- **Etapa 1 (interna):** Gere MUITOS candidatos — idealmente 15"
        " ou mais — cruzando todas as variáveis relevantes.\n"
        "- **Etapa 2 (saída):** SELECIONE os **10 insights mais relevantes**"
        " no total (alertas + informações somados). Priorize os que:\n"
        "    (a) revelam correlações não-óbvias (ex: PRs em ICN baixo);\n"
        "    (b) são acionáveis;\n"
        "    (c) ajudam o atleta a planejar o próximo ciclo.\n"
        "- **Distribuição obrigatória:** NUNCA retorne só alertas ou só"
        " informações. Distribuição típica: 3-4 alertas + 6-7 informações em"
        " cenários de risco; 1-2 alertas + 8-9 informações em cenários"
        " saudáveis. Mínimo 1 de cada lado.\n\n"

        "**4. REGRAS GERAIS:**\n"
        "- Cada mensagem: no máximo 280 caracteres.\n"
        "- Sempre fale em 2ª pessoa, tom encorajador mesmo quando aponta"
        " riscos.\n"
        "- Zero perguntas.\n"
        "---\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        "1. APENAS JSON válido, sem texto fora.\n"
        "2. Sem markdown dentro dos valores.\n"
        f"{json_instructions}\n"
    )
    return prompt


# =============================================================================
# PROMPT — INSIGHTS PRÉ-TREINO
# =============================================================================

def _pre_workout_glossary() -> str:
    """Explica os campos do bloco pré-treino para a IA."""
    return (
        "**GLOSSÁRIO DOS CAMPOS PRÉ-TREINO (para SUA interpretação):**\n"
        "\n"
        "**workout (treino do dia, publicado pelo coach):**\n"
        "- `wodType`: tipo macro do treino (ex: 'WOD', 'LPO', 'GINÁSTICA').\n"
        "- `modalidade`: formato (ex: 'AMRAP', 'FOR TIME', 'EMOM',"
        " '3 ROUNDS FOR TIME').\n"
        "- `duracaoMinutos`: tempo previsto da parte principal.\n"
        "- `partes`: estrutura completa (warm up, parte principal, etc.)."
        " NÃO opine sobre a montagem; isso é escopo do professor.\n"
        "- `keyMetrics`: estímulos do treino segundo o coach (Força,"
        " Resistência, Potência, etc.).\n"
        "- `dataTreinoIso`: data do treino.\n"
        "\n"
        "**athlete_history_same_type (últimos N treinos do atleta no MESMO"
        " tipo/modalidade):**\n"
        "- Cada item tem `date`, `effort` (RPE 1-10), `modalidade`,"
        " `wodType`, `completed`, `forTimeSec`, `amrapRounds`, `amrapReps`,"
        " `keyMetrics`, `trainingTime` (HH:MM).\n"
        "- Use para ler PADRÕES: RPE médio nessa modalidade, taxa de"
        " conclusão, melhor horário do atleta nesse tipo, evolução de"
        " desempenho ao longo do tempo.\n"
        "\n"
        "**athlete_current_load (semana atual via weekly_load):**\n"
        "- Mesma semântica do glossário semanal — use para entender se o"
        " atleta está descansado, sob desgaste alto, ou em zona ideal"
        " ANTES do treino.\n"
        "\n"
        "**athlete_recent_prs (PRs recentes nas últimas 8 semanas):**\n"
        "- Liste os movimentos onde o atleta vem progredindo. Útil para"
        " linkar com movimentos do treino do dia se houver overlap.\n"
        "\n"
        "**athlete_profile (perfil detalhado opcional):**\n"
        "- `hasDetailedProfile=false` significa que o atleta escolheu o"
        " perfil atleta, mas ainda não salvou o perfil detalhado.\n"
        "- Se categoria, gênero, peso, altura ou tempo de prática estiverem"
        " ausentes, NÃO invente esses dados e NÃO faça inferências sobre"
        " nível, corpo ou experiência.\n"
        "- Use o perfil detalhado apenas como complemento quando os campos"
        " existirem. A base principal deve ser histórico, carga atual, PRs"
        " e treino publicado.\n"
    )


def create_pre_workout_insights_prompt(
    workout: Dict[str, Any],
    athlete_profile: Dict[str, Any],
    athlete_history_same_type: list,
    athlete_current_load: Dict[str, Any],
    athlete_recent_prs: list,
    now: Optional[datetime] = None,
    cohort: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Prompt da análise PRÉ-TREINO. Gera 5 insights focados no atleta naquele
    tipo de treino — NUNCA sobre a montagem do treino em si.
    """
    workout_json = json.dumps(
        workout, indent=2, ensure_ascii=False, default=_json_converter
    )
    profile_json = json.dumps(
        athlete_profile, indent=2, ensure_ascii=False, default=_json_converter
    )
    history_json = json.dumps(
        athlete_history_same_type, indent=2,
        ensure_ascii=False, default=_json_converter,
    )
    load_json = json.dumps(
        athlete_current_load, indent=2,
        ensure_ascii=False, default=_json_converter,
    )
    prs_json = json.dumps(
        athlete_recent_prs, indent=2,
        ensure_ascii=False, default=_json_converter,
    )

    # Estágio da semana — só injeta se houver weekStart no current_load
    week_stage_block = ""
    week_start_str = (athlete_current_load or {}).get('weekStart')
    if now is not None and week_start_str:
        try:
            week_start_dt = datetime.strptime(week_start_str, '%Y-%m-%d')
            if now.tzinfo is not None:
                week_start_dt = week_start_dt.replace(tzinfo=now.tzinfo)
            week_stage_block = _week_stage_context(now, week_start_dt) + "\n"
        except ValueError:
            pass

    cohort_block = _cohort_context_block(cohort)

    parser = get_pre_workout_parser()
    json_instructions = parser.get_format_instructions()

    prompt = (
        "Você é um assistente pessoal de CrossFit que conversa com o ATLETA"
        " ANTES dele começar o treino do dia.\n"
        "Sua missão: gerar 5 insights curtos, ÚTEIS e ACIONÁVEIS sobre como"
        " o atleta tende a se comportar nesse tipo de treino. Use APENAS"
        " padrões observáveis do histórico do próprio atleta.\n\n"

        f"{week_stage_block}"

        f"{cohort_block}"

        f"{_common_rules()}\n"

        "**🚫 ESCOPO — REGRAS RÍGIDAS DE TÓPICO:**\n"
        "Você está falando com o ATLETA, não com o professor. Portanto:\n"
        "- ✅ PERMITIDO falar sobre:\n"
        "    - Como o atleta costuma se sentir/render nesse tipo de treino\n"
        "    - Horários em que o atleta costuma ir melhor/pior\n"
        "    - Movimentos do treino onde o atleta tem PR recente\n"
        "    - Estado físico atual do atleta vs exigência prevista\n"
        "    - Sugestões práticas de ritmo/cadência baseadas no histórico\n"
        "    - Modalidades onde o atleta costuma se destacar ou penar\n"
        "\n"
        "- ❌ ESTRITAMENTE PROIBIDO falar sobre:\n"
        "    - Montagem do treino ('esse AMRAP tem volume alto')\n"
        "    - Sugestões técnicas ao coach ('seria melhor adicionar X')\n"
        "    - Avaliação da progressão programada pelo coach\n"
        "    - Crítica ou opinião sobre a estrutura/escolhas do treino\n"
        "    - Sugestões para mudar o treino\n"
        "\n"
        "Se você não tem dados suficientes do histórico do atleta naquele"
        " tipo, retorne MENOS insights — nunca preencha com palpites sobre"
        " a montagem do treino.\n\n"

        f"{_pre_workout_glossary()}\n"

        "**DADOS COMPLETOS:**\n"
        f"1) Treino publicado para hoje:\n```json\n{workout_json}\n```\n\n"
        f"2) Perfil do atleta:\n```json\n{profile_json}\n```\n\n"
        f"3) Histórico do atleta no MESMO tipo/modalidade:\n```json\n"
        f"{history_json}\n```\n\n"
        f"4) Estado atual do atleta (semana corrente):\n```json\n"
        f"{load_json}\n```\n\n"
        f"5) PRs recentes do atleta:\n```json\n{prs_json}\n```\n\n"

        "---\n"
        "**INSTRUÇÕES DE CRUZAMENTO DE DADOS:**\n"
        "\n"
        "1. **modalidade do treino × histórico naquela modalidade** — RPE"
        " médio do atleta nessa modalidade está alto (8+) ou baixo (5-)?"
        " Taxa de conclusão é alta? Tempo para FOR TIME tem caído?\n"
        "\n"
        "2. **trainingTime histórico × hora atual presumida** — Se o atleta"
        " costuma render melhor pela manhã (RPE menor + completion maior)"
        " e o treino é pra hoje à noite, pode mencionar.\n"
        "\n"
        "3. **keyMetrics do treino × PRs recentes** — Se o treino tem"
        " 'Força' e o atleta bateu PR de Back Squat semana passada,"
        " linkar como contexto positivo.\n"
        "\n"
        "4. **athlete_current_load.icnAll × exigência prevista** — Se ICN"
        " está em zona de sobrecarga (>75) e o treino é puxado, sugerir"
        " cuidado com ritmo. Se ICN está baixo (recuperação), liberar.\n"
        "\n"
        "5. **dailyLoadsCrossfit dos últimos dias** — Se o atleta treinou"
        " 3 dias seguidos pesado, mencione o estado de recuperação ANTES"
        " do treino do dia.\n\n"

        "---\n"
        "**INSTRUÇÕES DE GERAÇÃO:**\n"
        "\n"
        "**1. ALERTAS (`alertas`)** — riscos ou pontos de atenção"
        " específicos do atleta nesse tipo de treino.\n"
        "- Sempre acionável: 'considere começar mais leve', 'foque em"
        " manter a respiração', 'adapte se sentir desgaste do dia"
        " anterior'.\n"
        "- Chaves sugeridas: 'modalidade_desafiadora', 'horario_subotimo',"
        " 'pos_desgaste_acumulado', 'modalidade_ritmo_alto',"
        " 'recuperacao_curta'.\n"
        "\n"
        "**2. INFORMAÇÕES (`informacoes`)** — pontos fortes do atleta"
        " naquele tipo de treino, contexto positivo, oportunidades.\n"
        "- Chaves sugeridas: 'modalidade_forte', 'horario_otimo',"
        " 'pr_recente_no_movimento', 'estado_descansado',"
        " 'historico_consistente'.\n"
        "\n"
        "**3. PROCESSO DE GERAÇÃO (duas etapas):**\n"
        "- **Etapa 1 (interna):** gere ~8 candidatos cruzando variáveis.\n"
        "- **Etapa 2 (saída):** SELECIONE os **5 melhores** (alertas +"
        " informações somados). Priorize:\n"
        "    (a) padrões claros do histórico do atleta\n"
        "    (b) acionabilidade prática\n"
        "    (c) NÃO-OBVIEDADE (algo que o atleta não notaria sozinho)\n"
        "- **Distribuição:** Sempre misture — mínimo 1 alerta + 1"
        " informação. Distribuição típica: 1-2 alertas + 3-4 informações"
        " em cenários neutros; 2-3 alertas + 2-3 informações se houver"
        " sinais de risco/desgaste.\n"
        "\n"
        "**4. REGRAS DE QUALIDADE:**\n"
        "- Se histórico do atleta tem MENOS de 5 registros do mesmo tipo,"
        " gere insights mais GENÉRICOS (sobre estado atual, descanso,"
        " PRs) e menos sobre 'você costuma' — não há base estatística.\n"
        "- NUNCA invente padrões que o histórico não suporta.\n"
        "- Se for cold_start (semana 1 do atleta), foque só no treino"
        " do dia + estado atual; não compare com histórico inexistente.\n"
        "\n"
        "**5. REGRAS DE FORMATO:**\n"
        "- Cada mensagem: no máximo 240 caracteres.\n"
        "- 2ª pessoa, ZERO perguntas, tom motivacional.\n"
        "- Sem números crus internos (ICN, RPE 7.8, etc.).\n"
        "---\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        "1. APENAS JSON válido, sem texto fora.\n"
        "2. Sem markdown dentro dos valores.\n"
        f"{json_instructions}\n"
    )
    return prompt
