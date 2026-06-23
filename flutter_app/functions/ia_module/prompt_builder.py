import json
from typing import Any, Dict, List, Optional
from datetime import datetime
from .models import get_parser
from .models import get_cycle_parser

# Função auxiliar para converter datas antes de serializar
def json_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()

def create_evaluation_prompt(
    current_workout: Dict[str, Any],
    past_workouts: List[Dict[str, Any]],
    exercise_db: List[Dict[str, Any]],
    class_context: Optional[Dict[str, Any]] = None,
) -> str:
    """Cria o prompt detalhado para a LLM Gemini com lógica de análise distinta.

    `class_context` (opcional) traz as médias da turma na semana corrente:
      - averageEffortCurrentWeek (0-10)
      - averageMonotony
      - averageIcnAll
      - athletesCount
    Essas médias permitem alertar o professor quando a turma como um todo
    está fatigada.
    """

    # Usa o conversor customizado para lidar com Timestamps do Firestore
    cw_json = json.dumps(current_workout, indent=2, ensure_ascii=False, default=json_converter)
    pw_json = json.dumps(past_workouts, indent=2, ensure_ascii=False, default=json_converter)
    ed_json = json.dumps(exercise_db, indent=2, ensure_ascii=False, default=json_converter)
    cc_json = json.dumps(
        class_context or {}, indent=2, ensure_ascii=False, default=json_converter
    )

    base_prompt = (
        "Você é um assistente de IA especializado em avaliação e otimização de treinos de CrossFit.\n"
        "Sua tarefa é analisar o **Treino Atual** que um professor está cadastrando, considerando o **Histórico** e a **Base de Dados de Exercícios**.\n\n"
        "**Dados Fornecidos:**\n"
        f"**1. Treino Atual:**\n```json\n{cw_json}\n```\n\n"
        f"**2. Histórico (Últimos 15 Dias):**\n```json\n{pw_json}\n```\n\n"
        f"**3. Inventário do Box (Movimentos Disponíveis):**\n```json\n{ed_json}\n```\n\n"
        f"**4. Contexto da Turma (médias da semana atual):**\n```json\n{cc_json}\n```\n\n"

        "**Contexto Importante:**\n"
        "Utilize sempre os dados do histórico e da base de exercícios como contexto para sua análise do treino atual, e utilize suas estruturas e suas proprias explicações para cada vez mais melhorar seu feedback dos treinos.\n"
        "Não analise o treino no vácuo: o que aconteceu há 2 dias importa tanto quanto o que vai acontecer hoje.\n\n"

        "---"
        "**INSTRUÇÕES DE ANÁLISE (SIGA RIGOROSAMENTE):**\n"
        "Analise os dados e gere o feedback estruturado. Siga estas 4 etapas e **NÃO** repita informações entre os campos.\n\n"
        "- **Tom de Voz:** Profissional, colaborativo e técnico. Nunca seja arrogante.\n"
        "- **Regra de Ouro (Inventário):** Ao sugerir exercícios, consulte o **Inventário**. Se não estiver na lista, não sugira.\n"
        "- **Visão Holística:** Não olhe o exercício isolado. Olhe o padrão de movimento (Empurrar, Puxar, Agachar) e a via metabólica.\n"
        "- **Regra de Estímulos (ESTRITA):** Ao identificar os estímulos do treino atual, considere **APENAS os 3 estímulos mais relevantes**. IGNORE aquecimento (`WARM UP`), skill isolado de baixo volume e partes acessórias. Se algo não for um dos 3 principais, não o cite como estímulo dominante.\n\n"

        "**Etapa 1: Análise de Histórico (Preenche o campo `history_analysis`)**\n"
        "> Seja um analista de dados. Compare o **Treino Atual** com o **Histórico (Últimos 15 Dias)** procurando padrões de treinamento, grupos musculares, frequência de exercícios, intervalor e lacunas, tudo que for relavante para a analise.\n"
        "> Verifique a lista de treinos e os grupos musculares e extraia oque você achar melhor na sua analise.\n"
        "> Liste **APENAS FATOS objetivos**. Não dê opiniões, alertas ou sugestões aqui.\n"
        "> **Exemplos de Fatos:** 'WOD [Nome WOD] foi realizado há 2 dias', 'Foco em ombros pelo 3º dia consecutivo', 'Alto volume de treinos de perna nos últimos 15 dias', 'Nenhum treino de bíceps registrado nos últimos 15 dias e este treino também não inclui'.\n"
        "> Em `weekly`: Cite fatos sobre as frequências. Ex: 'Primeiro treino de perna em 6 dias (músculo descansado)' OU '3º dia seguido de ombro (alto risco de fadiga)' como você analisou no passo de cima.\n"
        "> Em `muscle_focus`: Liste os grupos musculares dominantes cruzando com essa análise de intervalo.\n"

        "**Etapa 2: Alertas de Risco (Preenche o campo `alerts`)**\n"
        "> Seja um gerente de risco. Identifique riscos ou sobrecarga **NO TREINO ATUAL**.\n"
        "> Procure por: Alta carga com alta repetição, excesso de volume para um grupo muscular *neste treino*, movimentos tecnicamente complexos.\n"
        "> **Fadiga Acumulada (Olhar Clínico):** Verifique o histórico (especialmente dos ultimos 3 dias). Procure por fadiga de 'SNC' (Sistema Nervoso), 'Grip' (Pegada) e 'Lombar'.\n"
        "> Exemplo: Se houve muito Deadlift ou Toes-to-Bar ontem/anteontem, alerte sobre a fadiga de pegada para o treino de hoje.\n"
        "> **Use a Etapa 1 como CONTEXTO:** Se o treino atual tem muito exercício de perna (alerta) E o histórico mostra muitas pernas (fato), seu alerta deve ser: 'Risco de sobrecarga nas pernas. O treino de hoje tem alto volume, o que é agravado pelo foco excessivo em pernas nos últimos 15 dias.'\n"
        "> **Contexto da Turma (CRÍTICO):** Se `class_context.averageMonotony` > 1.5, ou `class_context.averageEffortCurrentWeek` > 7, ou `class_context.averageIcnAll` > 100, ADICIONE um alerta humanizado para o professor (ex: 'A turma está chegando cansada — a média de esforço percebido da semana está em 7.8/10. Considere reduzir a intensidade ou aumentar o descanso entre séries.').\n"
        "> Se os alunos estiverem priorizando descanso/extra no lugar do WOD (visível em `class_context`), sinalize isso de forma empática (ex: 'Vários alunos optaram por descanso nos últimos dias — sinal de fadiga acumulada na turma').\n"
        "> **Formato:** A chave (key) do mapa deve ser o tipo de alerta (ex: 'sobrecarga', 'risco_tecnico', 'fadiga_pegada', 'risco_lombar', 'fadiga_turma', 'baixa_adesao_wod') e o valor (message) a descrição detalhada.\n\n"

        "**Etapa 3: Insights e Otimizações (Preenche o campo `insights`)**\n"
        "> Seja um coach assistente. Forneça dicas práticas para *melhorar a sessão* de treino. **NÃO** sugira mudanças nos exercícios e **NÃO** repita os alertas.\n"
        "> Foque em:"
        "> * **Mobilidade/Aquecimento:** Sugira alongamentos ou exercícios de mobilidade específicos para os movimentos do dia (ex: 'Mobilidade de tornozelo e punho para o Power Clean').Lembre-se de detalhar oque está sendo sugerido e por quê.\n"
        "> * **Logística e Fluxo:** Vá além do óbvio. Se a turma for cheia e o equipamento limitado (ver Inventário), sugira **Baterias (Heats)**, layout da sala ou revezamento inteligente.\n"
        "> * **Variações Compatíveis:** Sugira exercícios da **Base de Dados de Exercícios** que sejam variações ou acessórios (ex: 'Para Pull-ups, variações como Ring Row ou Chest-to-Bar podem ser usadas para diferentes níveis')."
        "> * **Dicas de Progressão/Execução:** Dê dicas sobre progressão de carga ou foco técnico (ex: 'Para progressão de carga no Power Clean, foque em aumentar o peso apenas se a técnica de tripla extensão estiver perfeita').\n"
        "> **Substituições (Equivalência):** Se sugerir trocar um movimento (ex: por chuva ou logística), sugira algo do Inventário (`exercise_db`) que tenha o **mesmo estímulo** (ex: Cardio por Cardio, Empurrar por Empurrar).\n"
        "> * **Scaling Inteligente (Iniciantes):** Sugira regressões do **Inventário** que preservam o estímulo (ex: 'Box Jump -> Step Up pois mantém trabalho unilateral sem impacto').\n"
        "> **Formato:** A chave (key) do mapa deve ser o título do insight (ex: 'Mobilidade Recomendada', 'Variações de Exercício') e o valor (detail) a dica.\n\n"
        "> Importante: Se sugerir substituições de exercícios, verifique na 'Lista de Exercícios do Box' se temos o equipamento necessário.\n"

        "**Etapa 4: Resumo (Preenche o campo `summary`)**\n"
        "> Seja um editor. Crie um resumo conciso de tudo.\n"
        "> * No campo `overview`: Faça um resumo do treino do dia (foco, tipo de WOD), os principais músculos usados, e uma breve menção às análises (ex: 'Treino focado em LPO e um AMRAP intenso para o core. A análise principal indica um [risco de alerta X], mas oferece [insights sobre Y]')."
        "> * No campo `key_metrics`: Escolha os **TOP 3** estímulos físicos mais relevantes para ESTE treino específico (ex: 'Força', 'Potência', 'Resistência Cardiovascular'). MÁXIMO 3 itens — se o treino trabalhar mais de 3, escolha os 3 predominantes. NUNCA retorne mais de 3.\n"
        "---"
    )

    # Obtém o parser e as instruções na hora de usar
    parser = get_parser()
    json_instructions = parser.get_format_instructions()

    footer = (
        "⚠️ **Regras RÍGIDAS de Formatação**:\n"
        "1. Responda APENAS com o JSON válido.\n"
        "2. Seja EXTREMAMENTE CONCISO. Seus textos serão lidos em celular.\n"
        "3. **Tamanho Máximo:** Cada campo de texto (overview, detail, message) DEVE ter no máximo 400 caracteres (aprox 40 palavras). Resuma brutalmente se necessário.\n"
        "4. Não use Markdown (negrito/itálico) dentro dos valores JSON.\n"
        "5. Sua resposta DEVE ser um único bloco de código JSON, sem nenhum texto ou formatação extra fora dele.\n"
        f"{json_instructions}"
    )

    return f"{base_prompt}\n{footer}"



def create_cycle_prompt(
    month_workouts: List[Dict[str, Any]],
    previous_cycle_data: Optional[Dict[str, Any]] = None,
    month_name: str = "Atual",
    class_context: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Cria o prompt para a Análise de Ciclo Mensal (Macroanálise).
    Recebe todos os treinos do mês e, opcionalmente, o resumo do ciclo anterior.
    `class_context` traz médias agregadas da turma para humanizar alertas.
    """

    # 1. Serializa os dados
    mw_json = json.dumps(month_workouts, indent=2, ensure_ascii=False, default=json_converter)
    prev_json = "Sem dados do ciclo anterior."
    if previous_cycle_data:
        prev_json = json.dumps(previous_cycle_data, indent=2, ensure_ascii=False, default=json_converter)
    cc_json = json.dumps(
        class_context or {}, indent=2, ensure_ascii=False, default=json_converter
    )

    # 2. Obtém o parser específico de Ciclo (que criamos no models.py)
    # Importante: Precisamos importar get_cycle_parser no topo ou aqui dentro

    parser = get_cycle_parser()
    json_instructions = parser.get_format_instructions()

    cycle_prompt = (
        "Você é um **Especialista em Periodização e Head Coach de CrossFit**.\n"
        f"Sua tarefa é realizar a **MACROANÁLISE DO CICLO MENSAL: {month_name}**.\n"
        "Seu objetivo é identificar tendências, desequilíbrios de volume e progressão ao longo do mês.\n\n"

        "**DADOS FORNECIDOS:**\n"
        f"**1. Treinos Realizados neste Mês ({len(month_workouts)} treinos):**\n```json\n{mw_json}\n```\n\n"
        f"**2. Resumo do Ciclo Anterior (Para Comparação):**\n```json\n{prev_json}\n```\n\n"
        f"**3. Contexto da Turma (médias da semana atual):**\n```json\n{cc_json}\n```\n\n"

        "---"
        "**ROTEIRO DE ANÁLISE MACRO (Siga rigorosamente):**\n"
        "Analise o conjunto da obra e gere o JSON de saída.\n\n"

        "**1. Comparação e Progressão (Campo `comparison`)**\n"
        "> Compare este mês com o anterior (se houver dados) ou analise a evolução dentro das semanas.\n"
        "> **Progressão:** O volume total subiu ou desceu? A intensidade aumentou?\n"
        "> **Distribuição:** A variabilidade de movimentos foi boa? Houve predominância excessiva de Empurrar vs Puxar?\n"
        "> **Variação:** Houve equilíbrio entre LPO, Ginástica e Monoestrutural?\n"
        "> **Esforço:** O esforço percebido (se disponível) condiz com o volume?\n\n"

        "**2. Recomendações Inteligentes (Campo `recommendations`)**\n"
        "> Atue como Consultor Estratégico.\n"
        "> **Negligenciados:** Quais padrões de movimento ou grupos musculares foram esquecidos neste mês?\n"
        "> **Ajustes:** O que deve mudar para o resto do mês ou para o próximo ciclo? (Ex: 'Reduzir volume de ombro nas próximas semanas').\n"
        "> **Notas:** Observações sobre PRs ou feedbacks gerais.\n\n"

        "**3. Pontos Positivos (Campo `positives`)**\n"
        "> Liste acertos do planejamento (ex: 'Boa progressão de carga no Back Squat', 'Distribuição equilibrada de cardio').\n\n"

        "**4. Alertas Técnicos de Macro (Campo `technical_alerts`)**\n"
        "> Identifique riscos de longo prazo.\n"
        "> Exemplo: 'Alta repetição de agachamento por 4 semanas seguidas aumenta risco articular'.\n"
        "> Exemplo: 'Distribuição desigual: 70% dos treinos focaram em membros inferiores'.\n\n"

        "**5. Resumo Executivo (Campo `overview`)**\n"
        "> Um parágrafo resumindo a 'identidade' deste ciclo até agora.\n\n"

        "**6. Alertas Rápidos (Campo `quick_alerts`)**\n"
        "> Crie de 3 a 5 alertas curtos, diretos e chamativos (máximo de 20 palavras cada).\n"
        "> Eles devem resumir os pontos mais críticos do mês (riscos iminentes, falta de algum estímulo, sucesso do volume, etc).\n"
        "> Eles aparecerão em um carrossel na tela do professor.\n"
        "> Exemplo 1: 'Cuidado: Volume de perna muito alto nas últimas 2 semanas.'\n"
        "> Exemplo 2: 'Excelente: Equilíbrio perfeito entre força e cardio neste mês.'\n"
        "> **Contexto da Turma:** Se `class_context.averageMonotony` > 1.5 ou `class_context.averageEffortCurrentWeek` > 7, inclua OBRIGATORIAMENTE pelo menos 1 alerta humanizado sobre o estado da turma (ex: 'Alunos estão chegando mais cansados — esforço médio em 7.8/10 nesta semana.').\n"
        "> Também priorize alertar quando a turma está trocando o WOD por descanso/extra com frequência.\n\n"

        "**FORMATO DE RESPOSTA:**\n"
        f"{json_instructions}\n"
    )

    return cycle_prompt