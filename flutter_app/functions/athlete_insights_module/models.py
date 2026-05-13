# functions/athlete_insights_module/models.py
#
# Schemas Pydantic para insights do ATLETA (não confundir com ia_module, que
# é dedicado ao coach/professor). Seguem o mesmo padrão de Dict[str, DetailObj]
# usado em ia_module.models.TrainingAnalysis para manter a saída previsível.

from __future__ import annotations

import re
from typing import ClassVar, Dict

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


_KEY_MAX_CHARS = 64


def _squash_text(value) -> str:
    text = " ".join(str(value or "").split())
    return text.strip()


def _clip_text(text: str, max_chars: int) -> str:
    text = _squash_text(text)
    if len(text) <= max_chars:
        return text

    suffix = "..."
    limit = max(1, max_chars - len(suffix))
    clipped = text[:limit].rstrip()
    last_space = clipped.rfind(" ")
    if last_space >= int(limit * 0.65):
        clipped = clipped[:last_space].rstrip()
    return f"{clipped}{suffix}"


def _normalize_key(key, fallback: str) -> str:
    text = str(key or "").strip().lower()
    text = re.sub(r"[^a-z0-9_]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    if not text:
        text = fallback
    return text[:_KEY_MAX_CHARS]


def _dedupe_key(key: str, used: set[str]) -> str:
    if key not in used:
        used.add(key)
        return key

    base = key[: max(1, _KEY_MAX_CHARS - 3)]
    index = 2
    while True:
        candidate = f"{base}_{index}"[:_KEY_MAX_CHARS]
        if candidate not in used:
            used.add(candidate)
            return candidate
        index += 1


def _dump_model(model: BaseModel) -> dict:
    if hasattr(model, "model_dump"):
        return model.model_dump()
    return model.dict()


def _balanced_counts(
    alert_count: int,
    info_count: int,
    *,
    max_total: int,
    max_alertas: int,
) -> tuple[int, int]:
    total = alert_count + info_count
    if total <= max_total:
        return alert_count, info_count

    if alert_count and info_count:
        keep_alerts = min(alert_count, max_alertas, max_total - 1)
        keep_infos = min(info_count, max_total - keep_alerts)
        remaining = max_total - keep_alerts - keep_infos
        if remaining > 0:
            extra_alerts = min(alert_count - keep_alerts, remaining)
            keep_alerts += extra_alerts
            remaining -= extra_alerts
            keep_infos += min(info_count - keep_infos, remaining)
        return keep_alerts, keep_infos

    if alert_count:
        return min(alert_count, max_total), 0
    return 0, min(info_count, max_total)


class AlertDetail(BaseModel):
    """Alerta humanizado para o atleta (sem jargão técnico)."""
    model_config = ConfigDict(extra="ignore")

    message: str = Field(..., description="Mensagem curta, empática e direta.")

    @field_validator("message", mode="before")
    @classmethod
    def _clean_message(cls, value):
        text = _squash_text(value)
        if not text:
            raise ValueError("message não pode ser vazio.")
        return text


class InfoDetail(BaseModel):
    """Informação/insight positivo ou neutro para o atleta."""
    model_config = ConfigDict(extra="ignore")

    detail: str = Field(..., description="Texto curto com contexto/dica.")

    @field_validator("detail", mode="before")
    @classmethod
    def _clean_detail(cls, value):
        text = _squash_text(value)
        if not text:
            raise ValueError("detail não pode ser vazio.")
        return text


class _InsightEnvelope(BaseModel):
    model_config = ConfigDict(extra="ignore")

    max_total_insights: ClassVar[int]
    max_alertas: ClassVar[int]
    max_message_chars: ClassVar[int]

    alertas: Dict[str, AlertDetail]
    informacoes: Dict[str, InfoDetail]

    @model_validator(mode="after")
    def _normalize_limits(self):
        keep_alerts, keep_infos = _balanced_counts(
            len(self.alertas),
            len(self.informacoes),
            max_total=self.max_total_insights,
            max_alertas=self.max_alertas,
        )

        used_keys: set[str] = set()
        normalized_alerts: Dict[str, AlertDetail] = {}
        for index, (key, detail) in enumerate(self.alertas.items()):
            if index >= keep_alerts:
                break
            normalized_key = _dedupe_key(
                _normalize_key(key, f"alerta_{index + 1}"), used_keys
            )
            data = _dump_model(detail)
            data["message"] = _clip_text(data.get("message", ""), self.max_message_chars)
            normalized_alerts[normalized_key] = AlertDetail(**data)

        normalized_infos: Dict[str, InfoDetail] = {}
        for index, (key, detail) in enumerate(self.informacoes.items()):
            if index >= keep_infos:
                break
            normalized_key = _dedupe_key(
                _normalize_key(key, f"informacao_{index + 1}"), used_keys
            )
            data = _dump_model(detail)
            data["detail"] = _clip_text(data.get("detail", ""), self.max_message_chars)
            normalized_infos[normalized_key] = InfoDetail(**data)

        if not normalized_alerts and not normalized_infos:
            raise ValueError("A resposta precisa ter pelo menos um insight.")

        self.alertas = normalized_alerts
        self.informacoes = normalized_infos
        return self


class WeeklyInsights(_InsightEnvelope):
    """
    Saída da análise SEMANAL. Roda quando o atleta para de registrar por um
    tempo (debounce de 15-20 min após o último write em
    users/{uid}/results/{resultId}).
    """
    max_total_insights: ClassVar[int] = 6
    max_alertas: ClassVar[int] = 3
    max_message_chars: ClassVar[int] = 240

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


class EvolutionInsights(_InsightEnvelope):
    """
    Saída da análise de EVOLUÇÃO (últimas 12 semanas).
    Invocada on-demand (onCall) pela tela de evolução. Cache de 4 dias.
    """
    max_total_insights: ClassVar[int] = 10
    max_alertas: ClassVar[int] = 4
    max_message_chars: ClassVar[int] = 280

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


class PreWorkoutInsights(_InsightEnvelope):
    """
    Saída da análise PRÉ-TREINO. Gerada por atleta a cada vez que o coach
    publica/atualiza um treino em exercises/{workoutId}.

    Foco: comportamento do ATLETA naquele tipo/modalidade. NUNCA sobre a
    montagem do treino em si — isso é escopo do professor.

    Total combinado de 5 insights (alertas + informacoes).
    """
    max_total_insights: ClassVar[int] = 5
    max_alertas: ClassVar[int] = 3
    max_message_chars: ClassVar[int] = 240

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
