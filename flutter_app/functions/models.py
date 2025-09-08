# models.py - VERSÃO FINAL CORRIGIDA

from pydantic import BaseModel, Field
from typing import List

# NENHUMA importação do LangChain aqui no topo.

class Summary(BaseModel):
    overview: str = Field(..., max_length=500, description="Resumo até 500 caracteres")
    key_metrics: List[str] = Field(..., description="Lista de métricas-chave")

class HistoryAnalysis(BaseModel):
    weekly: List[str] = Field(..., description="Pontos de análise semanal")
    muscle_focus: List[str] = Field(..., description="Grupos musculares focados")

class Insight(BaseModel):
    title: str = Field(..., description="Título do insight")
    detail: str = Field(..., max_length=500, description="Detalhe até 500 caracteres")

class Alert(BaseModel):
    type: str = Field(..., description="Tipo de alerta, ex: 'sobrecarga', 'desequilíbrio'")
    message: str = Field(..., description="Mensagem descritiva do alerta")

class TrainingAnalysis(BaseModel):
    summary: Summary
    history_analysis: HistoryAnalysis
    insights: List[Insight]
    alerts: List[Alert]

def get_parser():
    """
    Cria e retorna uma instância do PydanticOutputParser sob demanda.
    A importação pesada acontece aqui dentro, evitando timeout no deploy.
    """
    from langchain.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=TrainingAnalysis)