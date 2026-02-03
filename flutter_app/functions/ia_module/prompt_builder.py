import json
from typing import Any, Dict, List
from datetime import datetime
# Importa a FUNÇÃO em vez do objeto
from .models import get_parser

# Função auxiliar para converter datas antes de serializar
def json_converter(o):
    if isinstance(o, datetime):
        return o.isoformat()

def create_evaluation_prompt(
    current_workout: Dict[str, Any],
    past_workouts: List[Dict[str, Any]],
    exercise_db: List[Dict[str, Any]]
) -> str:
    """Cria o prompt detalhado para a LLM Gemini com lógica de análise distinta."""
    
    # Usa o conversor customizado para lidar com Timestamps do Firestore
    cw_json = json.dumps(current_workout, indent=2, ensure_ascii=False, default=json_converter)
    pw_json = json.dumps(past_workouts, indent=2, ensure_ascii=False, default=json_converter)
    ed_json = json.dumps(exercise_db, indent=2, ensure_ascii=False, default=json_converter)

    base_prompt = (
        "Você é um assistente de IA especializado em avaliação e otimização de treinos de CrossFit.\n"
        "Sua tarefa é analisar o **Treino Atual** que um professor está cadastrando, considerando o **Histórico** e a **Base de Dados de Exercícios**.\n\n"
        "**Dados Fornecidos:**\n"
        f"**1. Treino Atual:**\n```json\n{cw_json}\n```\n\n"
        f"**2. Histórico (Últimos 15 Dias):**\n```json\n{pw_json}\n```\n\n"
        f"**3. Inventário do Box (Movimentos Disponíveis):**\n```json\n{ed_json}\n```\n\n"

        "Utilize sempre os dados do histórico e da base de exercícios como contexto para sua análise do treino atual, e utilize suas estruturas e suas proprias explicações para cada vez mais melhorar seu feedback dos treinos.\n"
        
        "---"
        "**INSTRUÇÕES DE ANÁLISE (SIGA RIGOROSAMENTE):**\n"
        "Analise os dados e gere o feedback estruturado. Siga estas 4 etapas e **NÃO** repita informações entre os campos.\n\n"

        "**Etapa 1: Análise de Histórico (Preenche o campo `history_analysis`)**\n"
        "> Seja um analista de dados. Compare o **Treino Atual** com o **Histórico (Últimos 15 Dias)**.\n"
        "> Verifique a lista de treinos e os grupos musculares e extraia oque você achar melhor na sua analise.\n"
        "> Liste **APENAS FATOS objetivos**. Não dê opiniões, alertas ou sugestões aqui.\n"
        "> **Exemplos de Fatos:** 'WOD [Nome WOD] foi realizado há 2 dias', 'Foco em ombros pelo 3º dia consecutivo', 'Alto volume de treinos de perna nos últimos 15 dias', 'Nenhum treino de bíceps registrado nos últimos 15 dias e este treino também não inclui'.\n"
        "> Preencha os campos `weekly` e `muscle_focus` com estas observações fatuais, combinando seu conhecimento com a lsita de exercicios fornecida.\n\n"

        "**Etapa 2: Alertas de Risco (Preenche o campo `alerts`)**\n"
        "> Seja um gerente de risco. Identifique riscos **NO TREINO ATUAL**.\n"
        "> Procure por: Alta carga com alta repetição, excesso de volume para um grupo muscular *neste treino*, movimentos tecnicamente complexos.\n"
        "> **Use a Etapa 1 como CONTEXTO:** Se o treino atual tem muito exercício de perna (alerta) E o histórico mostra muitas pernas (fato), seu alerta deve ser: 'Risco de sobrecarga nas pernas. O treino de hoje tem alto volume, o que é agravado pelo foco excessivo em pernas nos últimos 15 dias.'\n"
        "> **Formato:** A chave (key) do mapa deve ser o tipo de alerta (ex: 'sobrecarga', 'risco_tecnico') e o valor (message) a descrição detalhada.\n\n"

        "**Etapa 3: Insights e Otimizações (Preenche o campo `insights`)**\n"
        "> Seja um coach assistente. Forneça dicas práticas para *melhorar a sessão* de treino. **NÃO** sugira mudanças nos exercícios e **NÃO** repita os alertas.\n"
        "> Foque em:"
        "> * **Mobilidade/Aquecimento:** Sugira alongamentos ou exercícios de mobilidade específicos para os movimentos do dia (ex: 'Mobilidade de tornozelo e punho para o Power Clean')."
        "> * **Variações Compatíveis:** Sugira exercícios da **Base de Dados de Exercícios** que sejam variações ou acessórios (ex: 'Para Pull-ups, variações como Ring Row ou Chest-to-Bar podem ser usadas para diferentes níveis')."
        "> * **Dicas de Progressão/Execução:** Dê dicas sobre progressão de carga ou foco técnico (ex: 'Para progressão de carga no Power Clean, foque em aumentar o peso apenas se a técnica de tripla extensão estiver perfeita').\n"
        "> **Formato:** A chave (key) do mapa deve ser o título do insight (ex: 'Mobilidade Recomendada', 'Variações de Exercício') e o valor (detail) a dica.\n\n"
        "> Importante: Se sugerir substituições de exercícios, verifique na 'Lista de Exercícios do Box' se temos o equipamento necessário.\n"

        "**Etapa 4: Resumo (Preenche o campo `summary`)**\n"
        "> Seja um editor. Crie um resumo conciso de tudo.\n"
        "> * No campo `overview`: Faça um resumo do treino do dia (foco, tipo de WOD), os principais músculos usados, e uma breve menção às análises (ex: 'Treino focado em LPO e um AMRAP intenso para o core. A análise principal indica um [risco de alerta X], mas oferece [insights sobre Y]')."
        "> * No campo `key_metrics`: Liste as capacidades físicas (ex: 'Força', 'Potência', 'Resistência Cardiovascular') lembre-se de utilizar bem a lista de exercicios que você recebeu.\n"
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