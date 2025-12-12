# models.py - VERSÃO FINAL CORRIGIDA

from pydantic import BaseModel, Field
from typing import List, Dict

# NENHUMA importação do LangChain aqui no topo.

class Summary(BaseModel):
    overview: str = Field(..., max_length=600, description="Resumo até 600 caracteres")
    key_metrics: List[str] = Field(..., description="Lista de métricas-chave")

class HistoryAnalysis(BaseModel):
    weekly: List[str] = Field(..., description="Pontos de análise semanal")
    muscle_focus: List[str] = Field(..., description="Grupos musculares focados")

class InsightDetail(BaseModel):
    """O valor de um insight, já que o título será a chave."""
    detail: str = Field(..., max_length=600, description="Detalhe até 600 caracteres")

class AlertDetail(BaseModel):
    """O valor de um alerta, já que o tipo será a chave."""
    message: str = Field(..., description="Mensagem descritiva do alerta")

class TrainingAnalysis(BaseModel):
    summary: Summary
    history_analysis: HistoryAnalysis
    
    # Trocamos List[Insight] por Dict[str, InsightDetail]
    insights: Dict[str, InsightDetail] = Field(..., 
        description="Um mapa de insights. A 'chave' (key) é o título do insight, e o 'valor' (value) é o objeto com o detalhe."
    )
    
    # Trocamos List[Alert] por Dict[str, AlertDetail]
    alerts: Dict[str, AlertDetail] = Field(..., 
        description="Um mapa de alertas. A 'chave' (key) é o tipo do alerta (ex: 'sobrecarga'), e o 'valor' (value) é o objeto com a mensagem."
    )

def get_parser():
    """
    Cria e retorna uma instância do PydanticOutputParser sob demanda.
    A importação pesada acontece aqui dentro, evitando timeout no deploy.
    """
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=TrainingAnalysis)