from __future__ import annotations

from pathlib import Path

import matplotlib as mpl


BASE_DIR = Path(__file__).resolve().parent
SCRIPTS_DIR = BASE_DIR.parent
ARQUIVO_RESPOSTAS = SCRIPTS_DIR / "respostas_formulario.csv"

DADOS_DIR = BASE_DIR / "dados"
PNG_DIR = BASE_DIR / "graficos" / "png"
PDF_DIR = BASE_DIR / "graficos" / "pdf"

A4_RETRATO = (8.27, 11.69)
A4_PAISAGEM = (11.69, 8.27)
FIGURA_PADRAO = (7.2, 4.8)

COR_TEXTO = "#17212B"
COR_GRADE = "#D9E0E7"
COR_COACH = "#0072B2"
COR_PRATICANTE = "#D55E00"
COR_ALERTA = "#B45309"
COR_NEUTRA = "#6B7280"

IDADE_ORDEM = [
    "Entre 20 e 30 anos",
    "Entre 30 e 40 anos",
    "Entre 40 e 50 anos",
    "Mais de 50 anos",
]

TEMPO_ORDEM = [
    "Menos de 1 ano",
    "Entre 1 e 3 anos",
    "Entre 3 e 5 anos",
    "Mais de 5 anos",
]

GENERO_ORDEM = ["Homem", "Mulher"]

AMOSTRA_MINIMA = 7
TOTAL_ESPERADO = 79
DEMOGRAFIA_COMPLETA_ESPERADA = 77


def preparar_diretorios() -> None:
    for diretorio in (DADOS_DIR, PNG_DIR, PDF_DIR):
        diretorio.mkdir(parents=True, exist_ok=True)


def aplicar_estilo() -> None:
    mpl.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 10,
            "axes.titlesize": 14,
            "axes.titleweight": "semibold",
            "axes.labelsize": 10.5,
            "axes.edgecolor": COR_TEXTO,
            "axes.labelcolor": COR_TEXTO,
            "axes.grid": True,
            "axes.axisbelow": True,
            "grid.color": COR_GRADE,
            "grid.linewidth": 0.7,
            "xtick.color": COR_TEXTO,
            "ytick.color": COR_TEXTO,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "text.color": COR_TEXTO,
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "savefig.facecolor": "white",
            "savefig.bbox": "tight",
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )
