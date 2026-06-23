"""
models.py

Define Pydantic data models for the training analysis JSON schema
and instantiate a PydanticOutputParser for use in LangChain.
"""

from pydantic import BaseModel, Field
from typing import List
from langchain.output_parsers import PydanticOutputParser


class Summary(BaseModel):
    """Breve overview e principais métricas do treino atual."""
    overview: str = Field(..., max_length=500, description="Resumo até 500 caracteres")
    key_metrics: List[str] = Field(..., description="Lista de métricas-chave")


class HistoryAnalysis(BaseModel):
    """Análise do histórico de treinos recentes."""
    weekly: List[str] = Field(..., description="Pontos de análise semanal")
    muscle_focus: List[str] = Field(..., description="Grupos musculares focados")


class Insight(BaseModel):
    """Insight com título e detalhe."""
    title: str = Field(..., description="Título do insight")
    detail: str = Field(..., max_length=500, description="Detalhe até 500 caracteres")


class Alert(BaseModel):
    """Alerta de risco com tipo e mensagem."""
    type: str = Field(..., description="Tipo de alerta, ex: 'sobrecarga', 'desequilíbrio'")
    message: str = Field(..., description="Mensagem descritiva do alerta")


class TrainingAnalysis(BaseModel):
    """Modelo raiz que agrupa toda a análise do treino."""
    summary: Summary
    history_analysis: HistoryAnalysis
    insights: List[Insight]
    alerts: List[Alert]


# Instância global do parser para uso no prompt builder e na execução da chain\parser = PydanticOutputParser(pydantic_object=TrainingAnalysis)
