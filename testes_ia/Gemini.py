from langchain.llms.base import LLM
from langchain.prompts import PromptTemplate
from pydantic import PrivateAttr
from typing import Any, List, Mapping, Optional, Dict
import google.generativeai as genai
import pandas as pd
import json

# --- 1. Definição da Classe GeminiLLM (adaptada do código anterior) ---
class GeminiLLM(LLM):
    api_key: str = "AIzaSyCQCHhw64I7eoui2o85uhy-XuEWBeBqWqw",
    model: str = "gemini-2.0-flash",
    _client: Any = PrivateAttr()

    def __init__(self, api_key: str, model: str = "gemini-2.0-flash", **kwargs: Any):
        super().__init__(**kwargs)
        self.api_key = api_key
        self.model = model
        genai.configure(api_key=self.api_key)
        self._client = genai.GenerativeModel(model_name=self.model)

    @property
    def _llm_type(self) -> str:
        return "gemini"

    def _call(
        self,
        prompt: str,
        stop: Optional[List[str]] = None,
    ) -> str:
        """Chama o endpoint generate_content do Gemini."""
        response = self._client.generate_content(
            contents=prompt,
        )
        return response.text

    @property
    def _identifying_params(self) -> Mapping[str, Any]:
        return {"model": self.model}

# --- 2. Funções para Carregamento e Preparação de Dados ---

def load_exercise_database(file_path: str) -> pd.DataFrame:
    """Carrega a base de dados de exercícios de um arquivo Excel."""
    try:
        df = pd.read_excel(file_path)
        return df
    except Exception as e:
        print(f"Erro ao carregar a base de dados de exercícios: {e}")
        return pd.DataFrame()

def format_exercise_database(df: pd.DataFrame) -> str:
    """Formata a base de dados de exercícios para inclusão no prompt da LLM.
    Converte o DataFrame em uma string JSON ou Markdown para fácil consumo pela LLM.
    """
    # Exemplo de formatação para JSON. Pode ser adaptado para Markdown ou outro formato.
    return df.to_json(orient="records", indent=2)

def get_current_workout_data() -> Dict[str, Any]:
    """Simula a obtenção dos dados do treino atual que o professor está cadastrando.
    Em um ambiente real, esta função buscaria os dados do Firebase.
    """
    # Exemplo de estrutura de um treino atual
    current_workout = {
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
    return current_workout

def get_last_15_days_workouts() -> List[Dict[str, Any]]:
    """Simula a obtenção dos treinos dos últimos 15 dias.
    Em um ambiente real, esta função buscaria os dados do Firebase.
    """
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

def get_student_performance_data() -> List[Dict[str, Any]]:
    """Simula a obtenção de dados de desempenho dos alunos.
    Esta função está comentada conforme sua solicitação inicial.
    Em um ambiente real, buscaria dados de desempenho do Firebase.
    """
    # student_data = [
    #     {"student_id": "s001", "workout_name": "Treino A", "completion_time": "15:30", "load_used": "medium"},
    #     {"student_id": "s002", "workout_name": "Treino A", "completion_time": "14:00", "load_used": "heavy"},
    #     {"student_id": "s001", "workout_name": "Treino B", "completion_time": "10:00", "load_used": "light"},
    # ]
    return [] # Retorna lista vazia por enquanto

# --- 3. Estrutura do Prompt para a LLM Gemini ---

def create_evaluation_prompt(
    current_workout: Dict[str, Any],
    past_workouts: List[Dict[str, Any]],
    exercise_db: pd.DataFrame,
    student_performance_data: List[Dict[str, Any]]
) -> str:
    """Cria o prompt detalhado para a LLM Gemini para avaliação do treino.

    O prompt instrui a IA a analisar o treino atual em contexto com treinos passados
    e a base de dados de exercícios, fornecendo insights e sugestões.
    """

    # Convertendo dados para string para inclusão no prompt
    current_workout_str = json.dumps(current_workout, indent=2)
    past_workouts_str = json.dumps(past_workouts, indent=2)
    exercise_db_str = format_exercise_database(exercise_db)

    prompt_content = (
        "Você é um assistente de IA especializado em avaliação e otimização de treinos de CrossFit.\n"
        "Sua tarefa é analisar um treino que um professor está prestes a cadastrar, \n"
        "considerando o histórico de treinos recentes e uma base de dados de exercícios.\n"
        "Forneça insights, sugestões e alertas importantes para o professor.\n\n"
        "**Instruções para a Análise:**\n"
        "1.  **Análise do Treino Atual:** Avalie a estrutura, exercícios, repetições, séries, duração e tipo do treino atual.\n"
        "2.  **Análise do Histórico (Últimos 15 Dias):** Identifique padrões, focos musculares predominantes, frequência de certos movimentos ou grupos musculares, e possíveis desequilíbrios ao longo dos últimos 15 dias.\n"
        "3.  **Uso da Base de Dados de Exercícios:** Utilize as informações da `exercise_database_data` para entender as categorias, padrões de movimento, músculos primários e secundários, equipamentos e modalidades de cada exercício presente no treino atual e nos treinos passados.\n"
        "4.  **Geração de Insights:** Com base nas análises acima, gere insights relevantes para o professor. Exemplos de insights esperados:\n"
        "    -   Identificação de foco muscular excessivo ou insuficiente (ex: \"Este é o 4º treino da semana com foco em ombros.\").\n"
        "    -   Potenciais riscos de lesão devido a sobrecarga ou desequilíbrio (ex: \"Risco potencial de lesão no joelho devido à alta frequência de agachamentos pesados sem recuperação adequada.\").\n"
        "    -   Sugestões para balanceamento do treino (ex: \"Considere adicionar exercícios para a cadeia posterior, pois houve pouco foco em pernas nos últimos 15 dias.\").\n"
        "    -   Variações de exercícios ou progressões/regressões com base na base de dados.\n"
        "    -   Análise da intensidade e volume do treino em relação ao histórico.\n"
        "5.  **Formato da Resposta:** A resposta deve ser clara, concisa e estruturada em seções, como:\n"
        "    -   **Resumo do Treino Atual:** Breve descrição do treino que está sendo avaliado.\n"
        "    -   **Análise do Histórico Recente:** Padrões e focos dos últimos 15 dias.\n"
        "    -   **Insights e Sugestões:** As principais observações e recomendações.\n"
        "    -   **Alertas de Risco (se houver):** Quaisquer preocupações com lesões ou sobrecarga.\n\n"
        "**Dados Fornecidos:**\n\n"
        "**Treino Atual (current_workout_data):**\n"
        f"```json\n{current_workout_str}\n```\n\n"
        "**Histórico de Treinos (past_workouts_data - Últimos 15 Dias):**\n"
        f"```json\n{past_workouts_str}\n```\n\n"
        "**Base de Dados de Exercícios (exercise_database_data):**\n"
        f"```json\n{exercise_db_str}\n```\n\n"
        "Por favor, forneça sua análise e insights agora.\n"

        # === AQUI COMEÇA A MUDANÇA PRINCIPAL ===
        "⚠️ **Importante**: retorne **APENAS** um objeto JSON com este exato esquema:\n"
        "```json\n"
        "{\n"
        '  "summary": { "overview": string, "key_metrics": string[] },\n'
        '  "history_analysis": { "weekly": string[], "muscle_focus": string[] },\n'
        '  "insights": [ { "title": string, "detail": string } ],\n'
        '  "alerts": [ { "type": string, "message": string } ]\n'
        "}\n"
        "```\n"
        "– Cada lista deve ter no máximo 5 itens.\n"
        "– Cada string em `overview` e `detail` deve ter no máximo 500 caracteres.\n"
        # === FIM DA MUDANÇA PRINCIPAL ===

        "\nPor favor, forneça sua análise **já formatada** nesse JSON e nada mais.\n"
    )

    return prompt_content

# --- 4. Lógica Principal de Execução ---

def main():
    API_KEY = "AIzaSyCQCHhw64I7eoui2o85uhy-XuEWBeBqWqw"  # Substitua pela sua chave de API real
    EXERCISE_DB_PATH = "Exercicio_banco.xlsx"

    # Carregar base de dados de exercícios
    exercise_db = load_exercise_database(EXERCISE_DB_PATH)
    if exercise_db.empty:
        print("Não foi possível carregar a base de dados de exercícios. Encerrando.")
        return

    # Obter dados simulados (em um ambiente real, viriam do Firebase)
    current_workout = get_current_workout_data()
    past_workouts = get_last_15_days_workouts()
    student_performance_data = get_student_performance_data() # Comentado por enquanto

    # Inicializar o modelo Gemini
    gemini_llm = GeminiLLM(api_key=API_KEY)

    # Criar o prompt para a avaliação
    evaluation_prompt = create_evaluation_prompt(
        current_workout,
        past_workouts,
        exercise_db,
        student_performance_data
    )

    print("\n--- Prompt Gerado para o Gemini ---")
    print(evaluation_prompt)
    print("\n-----------------------------------")

    # Executar a avaliação com o Gemini
    print("\n--- Executando a avaliação com o Gemini (pode demorar um pouco) ---")
    try:
        response_text = gemini_llm.invoke(evaluation_prompt)
        print("\n--- Resposta do Gemini ---")
        print(response_text)
    except Exception as e:
        print(f"Erro ao chamar a LLM Gemini: {e}")
        print("Verifique se a API Key está correta e se há conectividade.")

if __name__ == "__main__":
    main()


