# prompet_builder.py - VERSÃO FINAL CORRIGIDA

import json
from typing import Any, Dict, List
# Importa a FUNÇÃO em vez do objeto
from models import get_parser

def create_evaluation_prompt(
    current_workout: Dict[str, Any],
    past_workouts: List[Dict[str, Any]],
    exercise_db: List[Dict[str, Any]]
) -> str:
    """Cria o prompt detalhado para a LLM Gemini."""
    cw_json = json.dumps(current_workout, indent=2, ensure_ascii=False)
    pw_json = json.dumps(past_workouts, indent=2, ensure_ascii=False)
    ed_json = json.dumps(exercise_db, indent=2, ensure_ascii=False)

    base_prompt = (
        "Você é um assistente de IA especializado em avaliação e otimização de treinos de CrossFit.\n"
        "Sua tarefa é analisar um treino que um professor está prestes a cadastrar, considerando o histórico de treinos recentes "
        "e uma base de dados de exercícios.\n\n"
        "**Dados Fornecidos:**\n"
        f"**Treino Atual:**\n```json\n{cw_json}\n```\n\n"
        f"**Histórico (Últimos 15 Dias):**\n```json\n{pw_json}\n```\n\n"
        f"**Base de Dados de Exercícios:**\n```json\n{ed_json}\n```\n\n"
        "Analise os dados e forneça um feedback estruturado sobre o treino proposto, incluindo um resumo, "
        "análise de histórico, insights para melhoria e alertas sobre possíveis riscos (como sobrecarga ou desequilíbrio muscular). "
        "Seja objetivo e foque em dados práticos para o professor.\n"
    )
    
    # Obtém o parser e as instruções na hora de usar
    parser = get_parser()
    json_instructions = parser.get_format_instructions()
    
    footer = (
        "⚠️ **Importante**: Sua resposta DEVE ser um único bloco de código JSON, sem nenhum texto ou formatação extra fora dele.\n"
        f"{json_instructions}"
    )

    return f"{base_prompt}\n{footer}"