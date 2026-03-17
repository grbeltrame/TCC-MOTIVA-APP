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

class CycleDetail(BaseModel):
    description: str = Field(..., description="A explicação detalhada deste ponto")

class CycleComparison(BaseModel):
    progression: str = Field(..., description="Comparação de volume/intensidade com o ciclo anterior")
    distribution: str = Field(..., description="Análise da variabilidade e padrões de movimento")
    variation: str = Field(..., description="Análise da variação de estímulos (monoestrutural, lpo, etc)")
    effort: str = Field(..., description="Análise de esforço percebido e volume")

class CycleRecommendation(BaseModel):
    neglected: str = Field(..., description="Estímulos que foram pouco trabalhados")
    adjustments: str = Field(..., description="Sugestão de ajuste de volume/carga para o resto do mês")
    notes: str = Field(..., description="Outras observações estratégicas")

class CycleAnalysis(BaseModel):
    month_year: str = Field(..., description="Mês e Ano de referência (ex: '02-2026')")
    
    # 1. Comparação (Objeto fixo com campos fixos)
    comparison: CycleComparison
    
    # 2. Recomendações (Mapa: Chave=Titulo, Valor=Objeto CycleDetail)
    # Ex: "Atenção Ombros": { "description": "Volume subiu 20%..." }
    recommendations: Dict[str, CycleDetail] = Field(..., description="Recomendações estratégicas.")
    
    # 3. Pontos Positivos (Lista simples de strings mantém assim, pois são itens curtos)
    positives: List[str] = Field(..., description="Lista de acertos do planejamento neste mês")
    
    # 4. Alertas Técnicos (Mapa: Chave=Titulo, Valor=Objeto CycleDetail)
    technical_alerts: Dict[str, CycleDetail] = Field(..., description="Alertas de desequilíbrio ou risco no macrociclo")

    # Resumo Geral
    overview: str = Field(..., description="Um parágrafo resumindo a 'cara' deste ciclo até agora.")

    quick_alerts: List[str] = Field(..., description="3 a 5 alertas rápidos e diretos (máximo 20 palavras cada) destacando volume, estímulos ou riscos do mês.")
# ... (Mantenha os parsers no final) ...


def get_parser():
    """
    Cria e retorna uma instância do PydanticOutputParser sob demanda.
    A importação pesada acontece aqui dentro, evitando timeout no deploy.
    """
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=TrainingAnalysis)


def get_cycle_parser():
    from langchain_core.output_parsers import PydanticOutputParser
    return PydanticOutputParser(pydantic_object=CycleAnalysis)