# functions/athlete_insights_module/prompt_builder.py
#
# Prompts para a IA que fala DIRETAMENTE com o atleta.
#
# Regra fundamental — "Dicionário do Atleta":
#   - NUNCA usar termos técnicos: "Monotonia", "Strain", "ICN", "Session-RPE",
#     "AU", "CV", "Desvio Padrão".
#   - Traduções obrigatórias quando precisar mencionar o conceito:
#       Monotonia            -> "Falta de variação" / "Rotina muito parecida"
#       Strain               -> "Desgaste acumulado"
#       ICN                  -> "Volume em relação ao seu normal"
#       Session-RPE/esforço  -> "Nível de esforço sentido"
#
# Tom: empático, curto, motivacional. Como um personal trainer atento,
# nunca como um cientista.

import json
from typing import Any, Dict
from datetime import datetime

from .models import get_weekly_parser, get_evolution_parser


def _json_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()
    return str(o)


def _common_rules() -> str:
    return (
        "**DICIONÁRIO DO ATLETA — REGRAS RÍGIDAS DE LINGUAGEM:**\n"
        "- NUNCA use: 'Monotonia', 'Strain', 'ICN', 'Session-RPE', 'AU',"
        " 'unidades arbitrárias', 'desvio padrão'.\n"
        "- Use SEMPRE estas traduções humanizadas:\n"
        "  * Monotonia alta → 'Sua semana teve pouca variação de treino'\n"
        "  * Strain alto   → 'Você acumulou bastante desgaste'\n"
        "  * ICN alto      → 'Seu volume ficou bem acima do seu normal'\n"
        "  * ICN baixo     → 'Sua carga caiu em relação ao seu normal'\n"
        "  * Esforço alto  → 'Você sentiu os treinos mais puxados'\n"
        "- Fale diretamente com o atleta em 2ª pessoa ('você').\n"
        "- Tom: empático, motivacional, curto. Nada de jargão técnico.\n"
        "- NUNCA cite os números crus internos (ex: 'monotonia 1.8').\n"
        "  Se precisar quantificar, traduza em linguagem comum"
        " ('quase todos os dias com a mesma intensidade').\n"
    )


def create_weekly_insights_prompt(
    stats_summary: Dict[str, Any],
    weekly_load: Dict[str, Any],
    recent_results: list,
) -> str:
    """
    Prompt da análise SEMANAL do atleta.

    Entradas:
      stats_summary   — users/{uid}/stats/summary (frequência, estímulos, etc.)
      weekly_load     — users/{uid}/weekly_load/{weekLabel} atual
      recent_results  — lista leve dos últimos treinos da semana (tipo, effort)
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

    parser = get_weekly_parser()
    json_instructions = parser.get_format_instructions()

    prompt = (
        "Você é um assistente pessoal de CrossFit que conversa com o ATLETA.\n"
        "Sua missão: transformar os dados da semana dele em insights humanos,"
        " curtos e acionáveis.\n\n"

        f"{_common_rules()}\n"

        "**DADOS DA SEMANA DO ATLETA:**\n"
        f"1) Resumo (stats/summary):\n```json\n{stats_json}\n```\n\n"
        f"2) Carga da semana atual (weekly_load):\n```json\n{load_json}\n```\n\n"
        f"3) Últimos registros da semana:\n```json\n{recent_json}\n```\n\n"

        "---\n"
        "**INSTRUÇÕES DE ANÁLISE (siga à risca):**\n\n"

        "**1. ALERTAS (`alertas`)** — problemas ou riscos da semana.\n"
        "Use estas regras como gatilho e depois humanize a mensagem:\n"
        "- Se a carga/volume está bem acima do normal (ICN > 100): alerte"
        " sobre risco de sobrecarga — mas fale como 'você treinou bem mais"
        " do que o normal esta semana, cuidado com o desgaste'.\n"
        "- Se a monotonia > 1.5: alerte sobre falta de variação — fale"
        " como 'sua semana teve pouca variação, os treinos se parecem muito'.\n"
        "- Se restDays == 0: alerte sobre ausência de descanso — fale"
        " como 'você não teve nenhum dia de descanso, o corpo pede pausa'.\n"
        "- Se avgRpeAll > 8: alerte sobre esforço muito alto sustentado.\n"
        "- Se houver 3+ dias seguidos treinando estímulo similar, alerte"
        " sobre falta de variação de estímulos.\n"
        "- Chaves sugeridas: 'desgaste_acumulado', 'falta_variacao',"
        " 'sem_descanso', 'esforco_alto', 'estimulo_repetitivo'.\n"
        "- NÃO invente alertas se os dados não justificam.\n"
        "- Se nada merece alerta, retorne `alertas: {}` (mapa vazio).\n\n"

        "**2. INFORMAÇÕES (`informacoes`)** — dicas úteis e reforços"
        " positivos.\n"
        "- Sempre tente incluir pelo menos 1-2 itens aqui.\n"
        "- Pode destacar constância (ex: '4 treinos esta semana, ótimo"
        " ritmo'), estímulo predominante ('sua semana foi muito focada em"
        " condicionamento'), ou uma dica simples de recuperação/nutrição.\n"
        "- Chaves sugeridas: 'constancia_boa', 'estimulo_dominante',"
        " 'dica_recuperacao', 'dica_variacao'.\n\n"

        "**3. REGRAS GERAIS:**\n"
        "- Máximo 3 alertas e 3 informações.\n"
        "- Cada mensagem: no máximo 220 caracteres.\n"
        "- Nada de lista numerada dentro das mensagens — texto corrido.\n"
        "- Não cite nome próprio — fale em 2ª pessoa.\n"
        "---\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        "1. APENAS JSON válido, sem texto fora.\n"
        "2. Sem markdown dentro dos valores.\n"
        f"{json_instructions}\n"
    )
    return prompt


def create_evolution_insights_prompt(
    stats_summary: Dict[str, Any],
    last_12_weeks: list,
    prs_summary: Dict[str, Any],
    stimulus_distribution: Dict[str, int],
) -> str:
    """
    Prompt da análise de EVOLUÇÃO (12 semanas).

    Entradas:
      stats_summary         — stats/summary atual
      last_12_weeks         — lista de weekly_load docs (ordem cronológica asc)
      prs_summary           — {'count12w': X, 'byMovement': {movimento: n}}
      stimulus_distribution — dict consolidado de estímulos das 12 semanas
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

    parser = get_evolution_parser()
    json_instructions = parser.get_format_instructions()

    prompt = (
        "Você é um assistente pessoal de CrossFit que está olhando para a"
        " EVOLUÇÃO do atleta nos últimos 3 meses (12 semanas).\n"
        "Sua missão: identificar tendências de longo prazo e devolver isso"
        " em linguagem humana e motivacional.\n\n"

        f"{_common_rules()}\n"

        "**DADOS DO ATLETA (12 SEMANAS):**\n"
        f"1) Resumo atual:\n```json\n{stats_json}\n```\n\n"
        f"2) Carga semana a semana (cronológico):\n```json\n{weeks_json}\n```\n\n"
        f"3) PRs no período:\n```json\n{prs_json}\n```\n\n"
        f"4) Distribuição de estímulos (12 semanas):\n```json\n{stimulus_json}\n```\n\n"

        "---\n"
        "**INSTRUÇÕES DE ANÁLISE:**\n\n"

        "**1. ALERTAS (`alertas`)** — tendências de risco de médio prazo.\n"
        "- Queda sustentada de volume (3+ semanas caindo): 'seu volume vem"
        " caindo há algumas semanas'.\n"
        "- Estímulo negligenciado (muito baixo na distribuição): 'você quase"
        " não trabalhou [estímulo X] nas últimas semanas'.\n"
        "- Excesso sustentado de esforço/desgaste: 'você vem acumulando"
        " semanas puxadas seguidas, cuidado com o desgaste'.\n"
        "- Muitas semanas sem PR em movimentos que você costumava bater.\n"
        "- Chaves sugeridas: 'volume_em_queda', 'estimulo_negligenciado',"
        " 'desgaste_sustentado', 'pausa_progressao'.\n"
        "- Se tudo está saudável, retorne `alertas: {}`.\n\n"

        "**2. INFORMAÇÕES (`informacoes`)** — conquistas e direcionamento.\n"
        "- Destaque PRs batidos ('você bateu N recordes neste período').\n"
        "- Destaque progressão de volume/consistência quando saudável.\n"
        "- Sugira 1 foco estratégico para o próximo ciclo (ex: 'tente"
        " incluir mais trabalho de força para equilibrar').\n"
        "- Chaves sugeridas: 'prs_periodo', 'evolucao_volume',"
        " 'foco_proximo_ciclo', 'estimulo_dominante_periodo'.\n\n"

        "**3. REGRAS GERAIS:**\n"
        "- Máximo 3 alertas e 4 informações.\n"
        "- Cada mensagem: no máximo 260 caracteres.\n"
        "- Sempre fale em 2ª pessoa, tom encorajador mesmo quando aponta"
        " riscos.\n"
        "---\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        "1. APENAS JSON válido, sem texto fora.\n"
        "2. Sem markdown dentro dos valores.\n"
        f"{json_instructions}\n"
    )
    return prompt
