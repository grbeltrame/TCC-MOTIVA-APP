"""
run_analysis.py

Entry point para executar a análise: carrega dados, monta prompt, chama o Gemini via LangChain,
valida a resposta com PydanticOutputParser e imprime/retorna o JSON estruturado.
"""
import json
import pandas as pd
from langchain import LLMChain, PromptTemplate
from prompt_builder import create_evaluation_prompt
from llm_wrapper import GeminiLLM
from models import parser


def get_current_workout_data() -> dict:
    """Simula obtenção dos dados do treino atual (substituir por leitura real)."""
    return {
        "name": "Treino Exemplo 1",
        "date": "2025-07-07",
        "exercises": [
            {"name": "air_squat", "reps": 50, "sets": 1},
            {"name": "shoulder_press", "reps": 10, "sets": 3, "load": "medium"},
            {"name": "deadlift", "reps": 5, "sets": 5, "load": "heavy"},
            {"name": "burpee", "reps": 20, "sets": 1}
        ],
        "type": "AMRAP",
        "duration_minutes": 20
    }


def get_last_15_days_workouts() -> list:
    """Simula obtenção do histórico dos últimos 15 dias (substituir por leitura real)."""
    # Exemplo de treinos dos últimos 15 dias
    past_workouts = [
        {"name": "Treino A", "date": "2025-07-06", "exercises": [{"name": "air_squat", "reps": 100}], "focus": "pernas"},
        {"name": "Treino B", "date": "2025-07-05", "exercises": [{"name": "shoulder_press", "reps": 15}], "focus": "ombros"},
        {"name": "Treino C", "date": "2025-07-04", "exercises": [{"name": "deadlift", "reps": 3}], "focus": "costas"},
        {"name": "Treino D", "date": "2025-07-03", "exercises": [{"name": "air_squat", "reps": 80}], "focus": "pernas"},
        {"name": "Treino E", "date": "2025-07-02", "exercises": [{"name": "shoulder_press", "reps": 12}], "focus": "ombros"},
        {"name": "Treino F", "date": "2025-07-01", "exercises": [{"name": "burpee", "reps": 30}], "focus": "cardio"},
        {"name": "Treino G", "date": "2025-06-30", "exercises": [{"name": "deadlift", "reps": 4}], "focus": "costas"},
        {"name": "Treino H", "date": "2025-06-29", "exercises": [{"name": "air_squat", "reps": 90}], "focus": "pernas"},
        {"name": "Treino I", "date": "2025-06-28", "exercises": [{"name": "shoulder_press", "reps": 10}], "focus": "ombros"},
        {"name": "Treino J", "date": "2025-06-27", "exercises": [{"name": "burpee", "reps": 25}], "focus": "cardio"},
        {"name": "Treino K", "date": "2025-06-26", "exercises": [{"name": "deadlift", "reps": 5}], "focus": "costas"},
        {"name": "Treino L", "date": "2025-06-25", "exercises": [{"name": "air_squat", "reps": 70}], "focus": "pernas"},
        {"name": "Treino M", "date": "2025-06-24", "exercises": [{"name": "shoulder_press", "reps": 13}], "focus": "ombros"},
        {"name": "Treino N", "date": "2025-06-23", "exercises": [{"name": "burpee", "reps": 18}], "focus": "cardio"},
        {"name": "Treino O", "date": "2025-06-22", "exercises": [{"name": "deadlift", "reps": 6}], "focus": "costas"}
    ]
    return past_workouts


def main():
    # 1. Carregar base de dados de exercícios (pode vir do Cloud Storage)
    exercise_db = pd.read_excel("D:\Faculdade\TCC\TCC-MOTIVA-APP\testes_ia\Exercicio_banco.xlsx")

    # 2. Obter dados de treino
    current = get_current_workout_data()
    past    = get_last_15_days_workouts()

    # 3. Construir prompt
    prompt_text = create_evaluation_prompt(current, past, exercise_db)

    # 4. Configurar e chamar a LLM
    gemini = GeminiLLM(api_key="SUA_API_KEY")
    template = PromptTemplate(input_variables=[], template=prompt_text)
    chain = LLMChain(llm=gemini, prompt=template)
    raw_output = chain.run({})

    # 5. Validar e converter em objeto Python
    result = parser.parse(raw_output)
    structured = result.dict()

    # 6. Imprimir ou retornar o JSON final
    print(json.dumps(structured, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
