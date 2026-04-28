# functions/athlete_insights_module/models.py
#
# Schemas Pydantic para insights do ATLETA (não confundir com ia_module, que
# é dedicado ao coach/professor). Seguem o mesmo padrão de Dict[str, DetailObj]
# usado em ia_module.models.TrainingAnalysis para manter a saída previsível.

from pydantic import BaseModel, Field
from typing import Dict


class AlertDetail(BaseModel):
    """Alerta humanizado para o atleta (sem jargão técnico)."""
    message: str = Field(..., description="Mensagem curta, empática e direta.")


class InfoDetail(BaseModel):
    """Informação/insight positivo ou neutro para o atleta."""
    detail: str = Field(..., description="Texto curto com contexto/dica.")


class WeeklyInsights(BaseModel):
    """
    Saída da análise SEMANAL. Roda quando o atleta para de registrar por um
    tempo (debounce de 15-20 min após o último write em
    users/{uid}/results/{resultId}).
    """
    alertas: Dict[str, AlertDetail] = Field(
        ...,
        description=(
            "Mapa de alertas. Chave = tipo do alerta (ex: 'desgaste_acumulado',"
            " 'falta_variacao', 'sem_descanso'). Valor = objeto com a mensagem."
        ),
    )
    informacoes: Dict[str, InfoDetail] = Field(
        ...,
        description=(
            "Mapa de informações/dicas positivas. Chave = título curto"
            " (ex: 'constancia_boa', 'estimulo_dominante'). Valor = detalhe."
        ),
    )


class EvolutionInsights(BaseModel):
    """
    Saída da análise de EVOLUÇÃO (últimas 12 semanas).
    Invocada on-demand (onCall) pela tela de evolução. Cache de 4 dias.
    """
    alertas: Dict[str, AlertDetail] = Field(
        ...,
        description=(
            "Mapa de alertas de longo prazo. Chave = tipo (ex:"
            " 'volume_em_queda', 'estimulo_negligenciado'). Valor = mensagem."
        ),
    )
    informacoes: Dict[str, InfoDetail] = Field(
        ...,
        description=(
            "Mapa de conquistas/tendências positivas e dicas estratégicas."
        ),
    )


class PreWorkoutInsights(BaseModel):
    """
    Saída da análise PRÉ-TREINO. Gerada por atleta a cada vez que o coach
    publica/atualiza um treino em exercises/{workoutId}.

    Foco: comportamento do ATLETA naquele tipo/modalidade. NUNCA sobre a
    montagem do treino em si — isso é escopo do professor.

    Total combinado de 5 insights (alertas + informacoes).
    """
    alertas: Dict[str, AlertDetail] = Field(
        ...,
        description=(
            "Mapa de alertas pré-treino. Chave = tipo (ex:"
            " 'modalidade_desafiadora', 'horario_subotimo',"
            " 'pos_descanso_curto'). Valor = mensagem curta com ação"
            " sugerida ao atleta."
        ),
    )
    informacoes: Dict[str, InfoDetail] = Field(
        ...,
        description=(
            "Mapa de pontos fortes e contexto positivo do atleta naquele"
            " tipo de treino (ex: 'modalidade_forte', 'horario_otimo',"
            " 'pr_recente_no_movimento')."
        ),
    )


def get_weekly_parser():
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=WeeklyInsights)


def get_evolution_parser():
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=EvolutionInsights)


def get_pre_workout_parser():
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=PreWorkoutInsights)
