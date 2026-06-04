from __future__ import annotations

import json
import logging
import re
from typing import Any


class LLMJsonParseError(ValueError):
    """Raised when an LLM response does not contain a valid JSON object."""


_FENCED_BLOCK_RE = re.compile(
    r"```(?:json)?\s*(.*?)```",
    flags=re.IGNORECASE | re.DOTALL,
)


def _short_preview(text: str, limit: int = 240) -> str:
    preview = " ".join(str(text or "").split())
    return preview[:limit]


def _first_balanced_json_object(text: str) -> str | None:
    start = text.find("{")
    if start < 0:
        return None

    depth = 0
    in_string = False
    escape = False

    for index in range(start, len(text)):
        char = text[index]

        if in_string:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_string = False
            continue

        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start:index + 1]

    return None


def extract_json_object(raw: Any) -> str:
    """
    Returns a normalized JSON object string from an LLM response.

    The Gemini response can be pure JSON, fenced markdown, or include short text
    before/after the JSON. We accept those shapes but still validate that the
    extracted payload is valid JSON before handing it to Pydantic.
    """
    if raw is None:
        raise LLMJsonParseError("Resposta vazia do LLM.")

    text = str(raw).strip()
    if not text:
        raise LLMJsonParseError("Resposta vazia do LLM.")

    candidates = [text]
    candidates.extend(match.group(1).strip() for match in _FENCED_BLOCK_RE.finditer(text))

    for candidate in candidates:
        for payload in (candidate, _first_balanced_json_object(candidate)):
            if not payload:
                continue
            try:
                parsed = json.loads(payload)
            except json.JSONDecodeError:
                continue
            if not isinstance(parsed, dict):
                continue
            return json.dumps(parsed, ensure_ascii=False)

    raise LLMJsonParseError(
        f"Resposta do LLM não contém JSON válido. preview={_short_preview(text)!r}"
    )


def parse_llm_response(raw: Any, parser, *, flow: str, uid: str | None = None) -> dict:
    clean = extract_json_object(raw)
    try:
        parsed = parser.parse(clean)
    except Exception as exc:
        logging.warning(
            "[%s] falha ao validar JSON do LLM uid=%s response_chars=%s: %s",
            flow,
            uid or "-",
            len(str(raw or "")),
            exc,
        )
        raise

    if hasattr(parsed, "model_dump"):
        return parsed.model_dump()
    return parsed.dict()
