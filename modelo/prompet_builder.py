"""
prompt_builder.py

Responsável por construir o prompt para a LLM Gemini, incluindo a injeção
 de instruções de formatação JSON usando o parser do models.py.
"""
import json
from typing import Any, Dict, List
import pandas as pd
from models import parser


def format_exercise_database(df: pd.DataFrame) -> str:
    """Converte o DataFrame de exercícios em JSON (orientação records) para inclusão no prompt."""
    try:
        return df.to_json(orient="records", indent=2)
    except Exception as e:
        raise ValueError(f"Erro ao formatar base de exercícios: {e}")


def create_evaluation_prompt(
    current_workout: Dict[str, Any],
    past_workouts: List[Dict[str, Any]],
    exercise_db: pd.DataFrame
) -> str:
    """
    Cria o prompt detalhado para a LLM Gemini, incluindo contexto e instruções de formato JSON.

    Parâmetros:
    - current_workout: dict com dados do treino atual
    - past_workouts: lista de dicts com histórico dos últimos 15 dias
    - exercise_db: DataFrame com a base de dados de exercícios

    Retorna:
    - string contendo todo o prompt (contexto + parser.get_format_instructions())
    """
    # Serializa os dados de entrada
    cw_json = json.dumps(current_workout, indent=2, ensure_ascii=False)
    pw_json = json.dumps(past_workouts, indent=2, ensure_ascii=False)
    ed_json = format_exercise_database(exercise_db)

    # Bloco base de contexto e instruções de análise
    base_prompt = (
        "Você é um assistente de IA especializado em avaliação e otimização de treinos de CrossFit.\n"
        "Sua tarefa é analisar um treino que um professor está prestes a cadastrar, considerando o histórico de treinos recentes "
        "e uma base de dados de exercícios.\n\n"
        "**Dados Fornecidos:**\n"
        f"**Treino Atual:**\n```json\n{cw_json}\n```\n\n"
        f"**Histórico (Últimos 15 Dias):**\n```json\n{pw_json}\n```\n\n"
        f"**Base de Dados de Exercícios:**\n```json\n{ed_json}\n```\n\n"
    )

    # Instruções de formatação geradas pelo PydanticOutputParser
    json_instructions = parser.get_format_instructions()

    # Rodapé que força saída JSON estruturado
    footer = (
        "⚠️ **Importante**: retorne **APENAS** um JSON que satisfaça este esquema exato:\n"
        f"{json_instructions}\n\n"
        "- Cada lista deve ter no máximo 5 itens.\n"
        "- Cada string nos campos de texto deve ter no máximo 500 caracteres.\n"
        "Por favor, nada além desse JSON."
    )

    return base_prompt + footer
