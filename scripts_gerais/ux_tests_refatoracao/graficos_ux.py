from __future__ import annotations

import shutil
import textwrap
from pathlib import Path
from typing import Iterable, Sequence

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from matplotlib.colors import Normalize, TwoSlopeNorm
from matplotlib.patches import Patch

from configuracao import (
    A4_PAISAGEM,
    A4_RETRATO,
    AMOSTRA_MINIMA,
    COR_ALERTA,
    COR_COACH,
    COR_GRADE,
    COR_NEUTRA,
    COR_PRATICANTE,
    COR_TEXTO,
    DADOS_DIR,
    PDF_DIR,
    PNG_DIR,
    aplicar_estilo,
    preparar_diretorios,
)
from dados_ux import (
    COL_GENERO,
    COL_IDADE,
    COL_TEMPO,
    COL_TIPO,
    COLUNAS_HIPOTESES,
    HIPOTESES,
    MAPA_TOPICO_CODIGO,
    TIPO_AMBOS,
    TIPO_COACH,
    TIPO_PRATICANTE,
    analise_hipoteses,
    carregar_respostas,
    escrever_csv,
    expandir_grupos,
    legenda_hipoteses,
    matriz_hipoteses,
    perfis_contagem,
    perfis_prioritarios,
    tabela_contingencia,
)


aplicar_estilo()
sns.set_theme(style="whitegrid", rc=mpl.rcParams)


def _exportar(fig: plt.Figure, nome: str, aliases: Iterable[str] = ()) -> list[Path]:
    preparar_diretorios()
    saidas: list[Path] = []
    for formato, diretorio, kwargs in (
        ("png", PNG_DIR, {"dpi": 300}),
        ("pdf", PDF_DIR, {}),
    ):
        destino = diretorio / f"{nome}.{formato}"
        fig.savefig(destino, bbox_inches="tight", facecolor="white", **kwargs)
        saidas.append(destino)
        for alias in aliases:
            copia = diretorio / f"{alias}.{formato}"
            shutil.copyfile(destino, copia)
            saidas.append(copia)
    plt.close(fig)
    return saidas


def _cor_texto(valor: float, cmap, norm) -> str:
    r, g, b, _ = cmap(norm(valor))
    luminancia = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return "white" if luminancia < 0.52 else COR_TEXTO


def _rotulos_perfis(legenda: pd.DataFrame) -> list[str]:
    coluna_n = "N do Perfil" if "N do Perfil" in legenda else "Número de Respondentes"
    return [
        f"{row['Perfil ID']}\nn={int(row[coluna_n])}{'*' if int(row[coluna_n]) < AMOSTRA_MINIMA else ''}"
        for _, row in legenda.iterrows()
    ]


def _plotar_heatmap_likert(
    matriz: pd.DataFrame,
    legenda: pd.DataFrame,
    titulo: str,
    nome: str,
    mostrar_topicos: bool,
    aliases: Iterable[str] = (),
    fontsize_anotacao: float = 8.5,
) -> list[Path]:
    if matriz.empty:
        raise ValueError(f"Não há dados suficientes para gerar {nome}.")
    legenda_plot = legenda.drop_duplicates("Perfil ID").set_index("Perfil ID").reindex(list(matriz.columns))
    legenda_plot.index.name = "Perfil ID"
    legenda_plot = legenda_plot.reset_index()
    if legenda_plot["N do Perfil"].isna().any():
        ausentes = legenda_plot.loc[legenda_plot["N do Perfil"].isna(), "Perfil ID"].tolist()
        raise ValueError(f"Perfis sem legenda em {nome}: {ausentes}")
    linhas = len(matriz)
    largura = A4_PAISAGEM[0]
    altura = A4_PAISAGEM[1] if linhas > 10 else 6.8
    fig, ax = plt.subplots(figsize=(largura, altura), constrained_layout=True)
    cmap = mpl.colormaps["Blues"]
    norm = Normalize(vmin=1, vmax=5)
    sns.heatmap(
        matriz,
        ax=ax,
        cmap=cmap,
        norm=norm,
        linewidths=0.7,
        linecolor="white",
        cbar_kws={"label": "Média da nota (1–5)", "shrink": 0.9},
        annot=False,
    )
    for i in range(matriz.shape[0]):
        for j in range(matriz.shape[1]):
            valor = matriz.iloc[i, j]
            if pd.notna(valor):
                ax.text(
                    j + 0.5,
                    i + 0.5,
                    f"{valor:.2f}",
                    ha="center",
                    va="center",
                    fontsize=fontsize_anotacao,
                    color=_cor_texto(float(valor), cmap, norm),
                    fontweight="semibold" if abs(float(valor) - 3) >= 1 else "normal",
                )
    if mostrar_topicos:
        ylabels = [f"{codigo} — {MAPA_TOPICO_CODIGO[codigo]}" for codigo in matriz.index]
    else:
        ylabels = list(matriz.index)
    ax.set_yticklabels(ylabels, rotation=0, fontsize=8.7 if linhas > 10 else 9.5)
    ax.set_xticklabels(_rotulos_perfis(legenda_plot), rotation=0, fontsize=8.5)
    for tick, (_, row) in zip(ax.get_xticklabels(), legenda_plot.iterrows()):
        if int(row["N do Perfil"]) < AMOSTRA_MINIMA:
            tick.set_color(COR_ALERTA)
            tick.set_fontweight("bold")
    ax.set_title(titulo, pad=14)
    ax.set_xlabel("Perfis — consulte a legenda de perfis", labelpad=2)
    ax.set_ylabel("Hipóteses")
    ax.grid(False)
    if (legenda_plot["N do Perfil"] < AMOSTRA_MINIMA).any():
        fig.text(
            0.5,
            -0.025,
            f"* Amostra com menos de {AMOSTRA_MINIMA} respondentes; interpretar com cautela.",
            ha="center",
            fontsize=8.5,
            color=COR_ALERTA,
        )
    return _exportar(fig, nome, aliases)


def _plotar_heatmap_contagem(
    tabela: pd.DataFrame,
    titulo: str,
    xlabel: str,
    ylabel: str,
    nome: str,
    cmap_nome: str,
) -> list[Path]:
    fig, ax = plt.subplots(figsize=(12.6, 8.9), constrained_layout=True)
    cmap = mpl.colormaps[cmap_nome]
    norm = Normalize(vmin=0, vmax=max(1, float(tabela.to_numpy().max())))
    sns.heatmap(
        tabela,
        ax=ax,
        cmap=cmap,
        norm=norm,
        linewidths=1.1,
        linecolor="white",
        cbar_kws={"label": "Número de respondentes", "shrink": 0.92},
        annot=False,
    )
    for i in range(tabela.shape[0]):
        for j in range(tabela.shape[1]):
            valor = int(tabela.iloc[i, j])
            ax.text(
                j + 0.5,
                i + 0.5,
                str(valor),
                ha="center",
                va="center",
                fontsize=19,
                fontweight="bold",
                color=_cor_texto(valor, cmap, norm),
            )
    ax.set_title(titulo, pad=20, fontsize=22)
    ax.set_xlabel(xlabel, fontsize=18, labelpad=12)
    ax.set_ylabel(ylabel, fontsize=18, labelpad=12)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=0, fontsize=16)
    ax.set_yticklabels(ax.get_yticklabels(), rotation=0, fontsize=16)
    colorbar = ax.collections[0].colorbar
    colorbar.ax.tick_params(labelsize=15)
    colorbar.set_label("Número de respondentes", fontsize=17, labelpad=14)
    ax.grid(False)
    return _exportar(fig, nome)


def _perfil_curto(texto: str) -> str:
    return texto


def _plotar_barras_perfis(
    tabela: pd.DataFrame,
    titulo: str,
    nome: str,
    cor: str,
    aliases: Iterable[str] = (),
    altura: float | None = None,
    nota: str | None = None,
    ylabel: str = "",
    rotulos: str = "fora",
) -> list[Path]:
    dados = tabela.iloc[::-1].copy()
    altura = altura or min(18.5, max(6.4, 0.60 * len(dados) + 2.8))
    fig, ax = plt.subplots(figsize=(12.7, altura), constrained_layout=True)
    cores = sns.color_palette(cor, n_colors=len(dados)) if cor in {"Greens_d", "Purples", "Blues_d"} else cor
    barras = ax.barh(
        [_perfil_curto(v) for v in dados["Perfil"]],
        dados["Número de Respondentes"],
        color=cores,
        edgecolor="white",
    )
    maximo = max(1, int(dados["Número de Respondentes"].max()))
    ax.set_xlim(0, maximo * 1.18)
    if rotulos != "nenhum":
        dentro = rotulos.startswith("dentro")
        cor_rotulo = "white" if rotulos == "dentro_claro" else COR_TEXTO
        ax.bar_label(
            barras,
            padding=-10 if dentro else 5,
            label_type="edge",
            fontsize=15,
            fontweight="bold",
            color=cor_rotulo,
        )
    if nota:
        fig.suptitle(titulo, fontsize=22, fontweight="semibold")
        ax.set_title(nota, pad=16, fontsize=13.5, fontweight="normal", color=COR_NEUTRA)
    else:
        ax.set_title(titulo, pad=20, fontsize=22)
    ax.set_xlabel("Número de respondentes", fontsize=17, labelpad=12)
    ax.set_ylabel(ylabel, fontsize=17, labelpad=14)
    ax.tick_params(axis="x", labelsize=15)
    ax.tick_params(axis="y", labelsize=14.5)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.grid(axis="x")
    ax.grid(axis="y", visible=False)
    return _exportar(fig, nome, aliases)


def _plotar_legenda(
    tabela: pd.DataFrame,
    titulo: str,
    nome: str,
    colunas: Sequence[str],
    larguras: Sequence[float],
    wrap: dict[str, int] | None = None,
) -> list[Path]:
    wrap = wrap or {}
    dados = tabela[list(colunas)].copy()
    for coluna, largura in wrap.items():
        dados[coluna] = dados[coluna].map(lambda valor: textwrap.fill(str(valor), width=largura))
    linhas = len(dados)
    altura = min(11.69, max(4.5, 0.58 * linhas + 1.6))
    fig, ax = plt.subplots(figsize=(8.27, altura), constrained_layout=True)
    ax.axis("off")
    ax.set_title(titulo, fontsize=14, fontweight="semibold", pad=12)
    tabela_plot = ax.table(
        cellText=dados.values,
        colLabels=list(colunas),
        colWidths=list(larguras),
        cellLoc="left",
        colLoc="left",
        loc="center",
    )
    tabela_plot.auto_set_font_size(False)
    tabela_plot.set_fontsize(8.6)
    tabela_plot.scale(1, 1.55 if linhas > 12 else 1.8)
    for (linha, coluna), celula in tabela_plot.get_celld().items():
        celula.set_edgecolor(COR_GRADE)
        celula.set_linewidth(0.6)
        if linha == 0:
            celula.set_facecolor("#16324F")
            celula.get_text().set_color("white")
            celula.get_text().set_weight("bold")
        else:
            celula.set_facecolor("#F4F7FA" if linha % 2 else "white")
            celula.get_text().set_va("center")
            if "Amostra" in dados.columns and dados.iloc[linha - 1]["Amostra"].startswith("Atenção"):
                celula.set_facecolor("#FFF4E5")
    return _exportar(fig, nome)


def gerar_distribuicao_perfis_genero_tempo() -> list[Path]:
    df = carregar_respostas()
    tabela = tabela_contingencia(df, COL_GENERO, COL_TEMPO)
    tabela.reset_index().to_csv(DADOS_DIR / "distribuicao_perfis_genero_tempo.csv", index=False, encoding="utf-8-sig")
    return _plotar_heatmap_contagem(
        tabela,
        "Distribuição de Respondentes por Gênero e Tempo de Prática",
        "Tempo de prática no CrossFit",
        "Gênero",
        "distribuicao_perfis_genero_tempo",
        "Purples",
    )


def gerar_distribuicao_perfis_idade_genero() -> list[Path]:
    df = carregar_respostas()
    tabela = tabela_contingencia(df, COL_IDADE, COL_GENERO)
    tabela.reset_index().to_csv(DADOS_DIR / "distribuicao_perfis_idade_genero.csv", index=False, encoding="utf-8-sig")
    return _plotar_heatmap_contagem(
        tabela,
        "Distribuição de Respondentes por Faixa Etária e Gênero",
        "Gênero",
        "Faixa etária",
        "distribuicao_perfis_idade_genero",
        "BuPu",
    )


def gerar_distribuicao_perfis_idade_tempo() -> list[Path]:
    df = carregar_respostas()
    tabela = tabela_contingencia(df, COL_IDADE, COL_TEMPO)
    tabela.reset_index().to_csv(DADOS_DIR / "distribuicao_perfis_idade_tempo.csv", index=False, encoding="utf-8-sig")
    return _plotar_heatmap_contagem(
        tabela,
        "Distribuição de Respondentes por Faixa Etária e Tempo de Prática",
        "Tempo de Prática",
        "Faixa etária",
        "distribuicao_perfis_idade_tempo",
        "Blues",
    )


def gerar_perfis_praticante() -> list[Path]:
    df = carregar_respostas()
    tabela = perfis_contagem(df[df[COL_TIPO] == TIPO_PRATICANTE])
    csv_antigo = tabela[["Perfil", "Número de Respondentes"]].rename(
        columns={"Perfil": "Perfil Praticante"}
    )
    escrever_csv(csv_antigo, DADOS_DIR / "perfis_praticante.csv")
    for nome_obsoleto in (
        "perfis_praticante_resumo",
        "perfis_praticante_detalhe_01",
        "perfis_praticante_detalhe_02",
    ):
        (PNG_DIR / f"{nome_obsoleto}.png").unlink(missing_ok=True)
        (PDF_DIR / f"{nome_obsoleto}.pdf").unlink(missing_ok=True)
    return _plotar_barras_perfis(
        tabela,
        "Perfis de Praticantes (Idade | Tempo | Gênero)",
        "perfis_praticante",
        "Greens_d",
        ylabel="Perfil",
        rotulos="dentro_claro",
    )


def gerar_perfis_coach() -> list[Path]:
    df = carregar_respostas()
    tabela = perfis_contagem(df, grupo="Coach")
    csv_antigo = tabela[["Perfil", "Número de Respondentes"]]
    escrever_csv(csv_antigo, DADOS_DIR / "perfis_coach.csv")
    escrever_csv(csv_antigo, DADOS_DIR / "perfis_completos_coach.csv")
    return _plotar_barras_perfis(
        tabela,
        "Perfis de Coachs (Idade | Tempo | Gênero)",
        "perfis_coach",
        "Purples",
        aliases=["perfis_completos_coach"],
        ylabel="Perfil",
        rotulos="dentro_escuro",
    )


def gerar_perfis_completos() -> list[Path]:
    df = carregar_respostas()
    tabela = perfis_contagem(df, incluir_tipo=True)
    csv_antigo = tabela[["Perfil", "Número de Respondentes"]].rename(
        columns={"Perfil": "Perfil Completo"}
    )
    escrever_csv(csv_antigo, DADOS_DIR / "perfis_combinados.csv")
    return _plotar_barras_perfis(
        tabela.head(10),
        "Top 10 Perfis Combinados de Respondentes",
        "perfis_combinados_top10",
        "Blues_d",
        altura=9.1,
        ylabel="Perfil (Idade | Tempo | Gênero | Categoria)",
        rotulos="nenhum",
    )


def gerar_distribuicao_coach_vs_praticante() -> list[Path]:
    df = carregar_respostas()
    grupos = df.copy()
    grupos["Grupo"] = grupos[COL_TIPO].map(
        {
            TIPO_COACH: "Coach",
            TIPO_AMBOS: "Coach",
            TIPO_PRATICANTE: "Praticante",
        }
    )
    grupos = grupos.dropna(subset=["Grupo"])
    dimensoes = [
        (COL_GENERO, "Distribuição por gênero", "Gênero"),
        (COL_IDADE, "Distribuição por faixa etária", "Faixa etária"),
        (COL_TEMPO, "Distribuição por tempo de prática", "Tempo de prática"),
    ]
    registros = []
    fig, axes = plt.subplots(3, 1, figsize=(12.6, 17.8))
    fig.subplots_adjust(left=0.22, right=0.96, top=0.87, bottom=0.07, hspace=0.52)
    for ax, (coluna, titulo, ylabel) in zip(axes, dimensoes):
        tabela = grupos.groupby([coluna, "Grupo"]).size().unstack(fill_value=0)
        ordem = {
            COL_GENERO: ["Homem", "Mulher"],
            COL_IDADE: ["Entre 20 e 30 anos", "Entre 30 e 40 anos", "Entre 40 e 50 anos", "Mais de 50 anos"],
            COL_TEMPO: ["Menos de 1 ano", "Entre 1 e 3 anos", "Entre 3 e 5 anos", "Mais de 5 anos"],
        }[coluna]
        tabela = tabela.reindex(ordem, fill_value=0)
        for categoria, linha in tabela.iterrows():
            for grupo, valor in linha.items():
                registros.append({"Dimensão": ylabel, "Categoria": categoria, "Grupo": grupo, "Número de Pessoas": int(valor)})
        y = np.arange(len(tabela))
        altura_barra = 0.34
        coach = ax.barh(y - altura_barra / 2, tabela.get("Coach", 0), altura_barra, color="#6A1B9A", label="Coach")
        praticante = ax.barh(y + altura_barra / 2, tabela.get("Praticante", 0), altura_barra, color="#283593", label="Praticante")
        rotulos_coach = [str(int(v)) if v else "" for v in tabela.get("Coach", 0)]
        rotulos_praticante = [str(int(v)) if v else "" for v in tabela.get("Praticante", 0)]
        ax.bar_label(coach, labels=rotulos_coach, padding=6, fontsize=15, fontweight="bold")
        ax.bar_label(praticante, labels=rotulos_praticante, padding=6, fontsize=15, fontweight="bold")
        ax.set_yticks(y, tabela.index, fontsize=16)
        ax.invert_yaxis()
        ax.set_title(titulo, fontsize=20, pad=18)
        ax.set_xlabel("Número de pessoas", fontsize=17, labelpad=10)
        ax.set_ylabel(ylabel, fontsize=17, labelpad=14)
        ax.tick_params(axis="x", labelsize=15)
        ax.set_xlim(0, max(1, tabela.to_numpy().max()) * 1.15)
        ax.spines[["top", "right", "left"]].set_visible(False)
        ax.grid(axis="x")
        ax.grid(axis="y", visible=False)
    handles = [Patch(color="#6A1B9A", label="Coach"), Patch(color="#283593", label="Praticante")]
    fig.legend(handles=handles, loc="upper center", ncol=2, frameon=False, bbox_to_anchor=(0.5, 0.92), fontsize=17)
    fig.suptitle("Coaches e praticantes — comparação demográfica", y=0.97, fontsize=24, fontweight="semibold")
    escrever_csv(pd.DataFrame(registros), DADOS_DIR / "distribuicao_coach_vs_praticante.csv")
    return _exportar(fig, "distribuicao_coach_vs_praticante")


ANALISES = {
    "genero_idade": ([COL_GENERO, COL_IDADE], "Gênero × faixa etária", "hipoteses_por_genero_idade"),
    "genero_tempo": ([COL_GENERO, COL_TEMPO], "Gênero × tempo de prática", "hipoteses_por_genero_tempo"),
    "idade_tempo": ([COL_IDADE, COL_TEMPO], "Faixa etária × tempo de prática", "hipoteses_por_idade_tempo"),
}


def _plotar_heatmap_texto_completo(
    matriz: pd.DataFrame,
    titulo: str,
    nome: str,
    figsize: tuple[float, float],
    xlabel: str,
    cmap_nome: str,
    limites: tuple[float, float] | None = None,
    cbar_label: str = "Média da Nota",
    wrap_hipotese: int = 52,
    wrap_perfil: int = 14,
    fontsize_anotacao: float | None = None,
    fontsize_hipotese: float | None = None,
    fontsize_perfil: float | None = None,
    fontsize_titulo: float | None = None,
    linecolor: str = "#8A8A8A",
) -> list[Path]:
    """Plota o heatmap sem códigos: hipóteses e perfis aparecem por extenso."""
    if matriz.empty:
        raise ValueError(f"Não há dados suficientes para gerar {nome}.")
    fig, ax = plt.subplots(figsize=figsize)
    detalhe = len(matriz) <= 10
    cmap = mpl.colormaps[cmap_nome]
    minimo, maximo = limites or (float(matriz.min().min()), float(matriz.max().max()))
    norm = Normalize(vmin=minimo, vmax=maximo if maximo > minimo else minimo + 1)
    sns.heatmap(
        matriz,
        ax=ax,
        cmap=cmap,
        norm=norm,
        linewidths=0.8,
        linecolor=linecolor,
        cbar_kws={"label": cbar_label, "shrink": 0.92},
        annot=False,
    )
    anotacao = fontsize_anotacao or (13.5 if detalhe else 14)
    for linha in range(matriz.shape[0]):
        for coluna in range(matriz.shape[1]):
            valor_bruto = matriz.iloc[linha, coluna]
            if pd.isna(valor_bruto):
                continue
            valor = float(valor_bruto)
            ax.text(
                coluna + 0.5,
                linha + 0.5,
                f"{valor:.2f}",
                ha="center",
                va="center",
                fontsize=anotacao,
                color=_cor_texto(valor, cmap, norm),
            )

    hipoteses = [textwrap.fill(str(hipotese), width=wrap_hipotese) for hipotese in matriz.index]
    perfis = [_perfil_multilinha(str(perfil), wrap_perfil) for perfil in matriz.columns]
    fs_hip = fontsize_hipotese or (13.2 if detalhe else 13)
    fs_perf = fontsize_perfil or (11 if detalhe else 12)
    ax.set_yticklabels(hipoteses, rotation=0, fontsize=fs_hip, fontweight="bold")
    ax.set_xticklabels(perfis, rotation=0, ha="center", fontsize=fs_perf, fontweight="bold")
    ax.tick_params(axis="y", pad=9)
    ax.tick_params(axis="x", pad=10)
    ax.set_title(titulo, fontsize=fontsize_titulo or (18 if detalhe else 20), pad=18 if detalhe else 20, fontweight="bold")
    ax.set_xlabel(xlabel, fontsize=fs_perf, labelpad=14, fontweight="bold")
    ax.set_ylabel("Hipóteses (Escala de Likert)", fontsize=fs_hip, labelpad=16, fontweight="bold")
    ax.grid(False)
    colorbar = ax.collections[0].colorbar
    colorbar.ax.tick_params(labelsize=fontsize_anotacao or 16)
    colorbar.set_label(cbar_label, fontsize=fontsize_perfil or 18, labelpad=14)
    return _exportar(fig, nome)


def _perfil_multilinha(perfil: str, largura: int) -> str:
    partes = [parte.strip() for parte in perfil.split(" | ")]
    linhas: list[str] = []
    for parte in partes:
        linhas.extend(textwrap.wrap(parte, width=largura) or [parte])
    return "\n".join(linhas)


def _remover_saidas_graficas(*nomes: str) -> None:
    for nome in nomes:
        for diretorio, extensao in ((PNG_DIR, "png"), (PDF_DIR, "pdf")):
            (diretorio / f"{nome}.{extensao}").unlink(missing_ok=True)


def _matriz_analise_antiga(
    perfil_colunas: Sequence[str],
    drop_colunas: Sequence[str],
    minimo_perfil: int,
    csv_nome: str,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Replica os scripts antigos de hipóteses, mantendo seus filtros originais."""
    df = carregar_respostas().dropna(subset=[*drop_colunas, *COLUNAS_HIPOTESES]).copy()
    df["Perfil"] = df[list(perfil_colunas)].astype(str).agg(" | ".join, axis=1)
    contagem = df["Perfil"].value_counts()
    perfis_antigos = contagem[contagem >= minimo_perfil].index.tolist()
    filtrado = df[df["Perfil"].isin(perfis_antigos)]
    medias = filtrado.groupby("Perfil")[COLUNAS_HIPOTESES].mean()

    registros = []
    for perfil, linha in medias.iterrows():
        for hipotese, media in linha.items():
            registros.append(
                {"Perfil": perfil, "Hipótese": hipotese, "Média da Nota": round(float(media), 2)}
            )
    resultado = pd.DataFrame(registros)
    escrever_csv(resultado, DADOS_DIR / f"{csv_nome}.csv")

    matriz = resultado.pivot(index="Hipótese", columns="Perfil", values="Média da Nota")
    ordem = matriz.mean(axis=1).sort_values(ascending=False).index
    matriz = matriz.reindex(ordem)
    return resultado, matriz


ANALISES_ANTIGAS = {
    "genero_tempo": {
        "perfil_colunas": [COL_GENERO, COL_TEMPO],
        "drop_colunas": [COL_GENERO, COL_TEMPO],
        "minimo": 12,
        "csv": "hipoteses_por_genero_tempo",
        "titulo": "Média das Respostas por Hipótese\n(Perfis com ≥ 12 respondentes | Gênero + Tempo de Prática)",
        "xlabel": "Perfil (Gênero + Tempo)",
        "cmap": "Blues",
        "fig_completa": (14.8, 16.0),
        "fig_detalhe": A4_PAISAGEM,
        "wrap_perfil": 13,
    },
    "genero_idade": {
        "perfil_colunas": [COL_GENERO, COL_IDADE],
        "drop_colunas": [COL_GENERO, COL_TEMPO],
        "minimo": 7,
        "csv": "hipoteses_por_genero_idade",
        "titulo": "Média das Respostas por Hipótese\n(Perfis com ≥ 11 respondentes | Gênero + Idade)",
        "xlabel": "Perfil (Gênero + Idade)",
        "cmap": "BuPu",
        "fig_completa": (17.2, 16.0),
        "fig_detalhe": (14.4, 8.8),
        "wrap_perfil": 13,
    },
    "idade_tempo": {
        "perfil_colunas": [COL_IDADE, COL_TEMPO],
        "drop_colunas": [COL_GENERO, COL_TEMPO],
        "minimo": 7,
        "csv": "hipoteses_por_idade_tempo",
        "titulo": "Média das Respostas por Hipótese\n(Perfis com ≥ 7 respondentes | Idade + Tempo de Prática)",
        "xlabel": "Perfil (Idade + Tempo)",
        "cmap": "Purples",
        "fig_completa": (18.8, 16.0),
        "fig_detalhe": (16.4, 9.0),
        "wrap_perfil": 13,
    },
}


def _gerar_analise_hipoteses_antiga(slug: str) -> list[Path]:
    config = ANALISES_ANTIGAS[slug]
    _, matriz = _matriz_analise_antiga(
        config["perfil_colunas"],
        config["drop_colunas"],
        int(config["minimo"]),
        str(config["csv"]),
    )
    limites = (float(matriz.min().min()), float(matriz.max().max()))
    titulo_base = str(config["titulo"])
    saidas = _plotar_heatmap_texto_completo(
        matriz,
        titulo_base,
        f"heatmap_hipoteses_{slug}",
        config["fig_completa"],
        str(config["xlabel"]),
        str(config["cmap"]),
        wrap_perfil=int(config["wrap_perfil"]),
    )
    for numero, bloco in enumerate((matriz.iloc[:10], matriz.iloc[10:]), start=1):
        saidas += _plotar_heatmap_texto_completo(
            bloco,
            f"{titulo_base}\nParte {numero} de 2",
            f"heatmap_hipoteses_{slug}_detalhe_{numero:02d}",
            config["fig_detalhe"],
            str(config["xlabel"]),
            str(config["cmap"]),
            limites=limites,
            wrap_perfil=int(config["wrap_perfil"]),
        )

    # A legenda externa deixa de ser necessária porque todos os textos estão no gráfico.
    _remover_saidas_graficas(f"legenda_perfis_{slug}")
    return saidas


def gerar_analise_hipoteses(slug: str) -> list[Path]:
    if slug in ANALISES_ANTIGAS:
        return _gerar_analise_hipoteses_antiga(slug)
    dimensoes, titulo_dimensao, csv_nome = ANALISES[slug]
    df = carregar_respostas()
    longa, legenda = analise_hipoteses(df, dimensoes, titulo_dimensao)
    escrever_csv(longa, DADOS_DIR / f"{csv_nome}.csv")
    escrever_csv(legenda, DADOS_DIR / f"legenda_perfis_{slug}.csv")
    resumo, legenda_resumo = matriz_hipoteses(longa, somente_resumo=True)
    completa, legenda_completa = matriz_hipoteses(longa, somente_resumo=False)
    saidas = _plotar_heatmap_likert(
        resumo,
        legenda_resumo,
        f"Média das hipóteses por perfil — {titulo_dimensao}\nResumo com n ≥ {AMOSTRA_MINIMA}",
        f"heatmap_hipoteses_{slug}",
        mostrar_topicos=True,
    )
    blocos = [completa.iloc[:10], completa.iloc[10:]]
    for numero, bloco in enumerate(blocos, start=1):
        saidas += _plotar_heatmap_likert(
            bloco,
            legenda_completa,
            f"Média das hipóteses por perfil — {titulo_dimensao}\nDetalhe {numero} de 2 — todos os perfis",
            f"heatmap_hipoteses_{slug}_detalhe_{numero:02d}",
            mostrar_topicos=True,
        )
    saidas += _plotar_legenda(
        legenda,
        f"Legenda de perfis — {titulo_dimensao}",
        f"legenda_perfis_{slug}",
        ["Perfil ID", "Perfil", "N do Perfil", "Amostra"],
        [0.11, 0.57, 0.12, 0.20],
        wrap={"Perfil": 52, "Amostra": 24},
    )
    return saidas


def gerar_distribuicao_prioridade() -> list[Path]:
    df = carregar_respostas().dropna(subset=[COL_TIPO, COL_TEMPO, COL_IDADE, COL_GENERO]).copy()

    def classificar_tipo(valor: str) -> str | None:
        if valor in [TIPO_COACH, TIPO_AMBOS]:
            return "Coach"
        if valor == TIPO_PRATICANTE:
            return "Praticante"
        return None

    df["Tipo"] = df[COL_TIPO].apply(classificar_tipo)
    df = df.dropna(subset=["Tipo"]).copy()
    df["Perfil"] = (
        df["Tipo"]
        + " | "
        + df[COL_GENERO].astype(str)
        + " | "
        + df[COL_IDADE].astype(str)
        + " | "
        + df[COL_TEMPO].astype(str)
    )
    for coluna in COLUNAS_HIPOTESES:
        df[coluna] = pd.to_numeric(df[coluna], errors="coerce")

    perfis_coach = [
        "Coach | Homem | Entre 30 e 40 anos | Mais de 5 anos",
        "Coach | Homem | Entre 40 e 50 anos | Mais de 5 anos",
        "Coach | Homem | Entre 20 e 30 anos | Entre 1 e 3 anos",
    ]
    perfis_atleta = [
        "Praticante | Mulher | Entre 20 e 30 anos | Entre 3 e 5 anos",
        "Praticante | Homem | Entre 30 e 40 anos | Entre 1 e 3 anos",
        "Praticante | Mulher | Entre 40 e 50 anos | Mais de 5 anos",
        "Praticante | Homem | Entre 30 e 40 anos | Entre 3 e 5 anos",
    ]

    def matriz_prioridade(perfis: Sequence[str], csv_nome: str) -> pd.DataFrame:
        selecionado = df[df["Perfil"].isin(perfis)].copy()
        if selecionado.empty:
            raise ValueError(f"Nenhum dado encontrado para {csv_nome}.")
        longo = selecionado[["Perfil", *COLUNAS_HIPOTESES]].melt(
            id_vars="Perfil",
            var_name="Hipótese",
            value_name="Nota",
        )
        longo["Nota"] = pd.to_numeric(longo["Nota"], errors="coerce")
        longo = longo.dropna(subset=["Nota"])
        tabela = longo.groupby(["Hipótese", "Perfil"])["Nota"].mean().unstack()
        ordem = tabela.mean(axis=1).sort_values(ascending=False).index
        tabela = tabela.reindex(ordem)
        registros = []
        for hipotese, linha in tabela.iterrows():
            for perfil, media in linha.items():
                registros.append(
                    {"Perfil": perfil, "Hipótese": hipotese, "Média da Nota": round(float(media), 2)}
                )
        escrever_csv(pd.DataFrame(registros), DADOS_DIR / f"{csv_nome}.csv")
        tabela.columns = [coluna.split(" | ", 1)[1] for coluna in tabela.columns]
        return tabela

    saidas: list[Path] = []
    for perfis, titulo, nome, figura_completa in (
        (
            perfis_coach,
            "Média das Hipóteses por Perfil — Coaches",
            "heatmap_coaches",
            (13.8, 16.0),
        ),
        (
            perfis_atleta,
            "Média das Hipóteses por Perfil — Atletas",
            "heatmap_praticantes",
            (15.0, 16.0),
        ),
    ):
        matriz = matriz_prioridade(perfis, nome)
        cmap_perfil = "Greens" if nome == "heatmap_coaches" else "Blues"
        saidas += _plotar_heatmap_texto_completo(
            matriz,
            titulo,
            nome,
            figura_completa,
            "Perfil",
            cmap_perfil,
            limites=(1, 5),
            cbar_label="Média da Nota (1–5)",
            wrap_perfil=13,
            fontsize_anotacao=13.5,
        )
        for numero, bloco in enumerate((matriz.iloc[:10], matriz.iloc[10:]), start=1):
            n_linhas = len(bloco)
            n_colunas = len(bloco.columns)
            fig_w = 6.0 + n_colunas * 2.5
            fig_h = 3.0 + n_linhas * 1.2
            saidas += _plotar_heatmap_texto_completo(
                bloco,
                f"{titulo}\nParte {numero} de 2",
                f"{nome}_detalhe_{numero:02d}",
                (fig_w, fig_h),
                "Perfil",
                cmap_perfil,
                limites=(1, 5),
                cbar_label="Média da Nota (1–5)",
                wrap_perfil=16,
                wrap_hipotese=60,
                fontsize_anotacao=19.0,
                fontsize_hipotese=20.0,
                fontsize_perfil=18.0,
                fontsize_titulo=22.0,
            )

    _remover_saidas_graficas("legenda_heatmap_coaches", "legenda_heatmap_praticantes")
    return saidas


def gerar_legenda_hipoteses() -> list[Path]:
    tabela = legenda_hipoteses()
    caminho = DADOS_DIR / "legenda_hipoteses.csv"
    escrever_csv(tabela, caminho)
    _remover_saidas_graficas("legenda_hipoteses_detalhe_01", "legenda_hipoteses_detalhe_02")
    return [caminho]


def gerar_hipoteses_todos_perfis() -> list[Path]:
    dfs_filtrados = []
    for slug in ("genero_tempo", "idade_tempo", "genero_idade"):
        config = ANALISES_ANTIGAS[slug]
        resultado, _ = _matriz_analise_antiga(
            config["perfil_colunas"],
            config["drop_colunas"],
            int(config["minimo"]),
            str(config["csv"]),
        )
        contagem = resultado["Perfil"].value_counts()
        perfis_validos = contagem[contagem >= AMOSTRA_MINIMA].index
        dfs_filtrados.append(resultado[resultado["Perfil"].isin(perfis_validos)])

    consolidado = pd.concat(dfs_filtrados, ignore_index=True).dropna()
    escrever_csv(consolidado, DADOS_DIR / "hipoteses_todos_os_perfis.csv")
    matriz = consolidado.pivot(index="Hipótese", columns="Perfil", values="Média da Nota")
    ordem = matriz.mean(axis=1).sort_values(ascending=False).index
    matriz = matriz.reindex(ordem)
    limites = (float(matriz.min().min()), float(matriz.max().max()))

    titulo_consolidado = "Média das Hipóteses por Perfil Prioritário"
    saidas = _plotar_heatmap_texto_completo(
        matriz,
        titulo_consolidado,
        "heatmap_todos_os_perfis",
        (32.0, 16.5),
        "Perfil",
        "Blues",
        cbar_label="Média da Nota",
        wrap_perfil=12,
        fontsize_anotacao=9.6,
        fontsize_perfil=9.3,
        fontsize_hipotese=12.2,
        fontsize_titulo=21,
    )
    saidas += _plotar_heatmap_texto_completo(
        matriz,
        f"{titulo_consolidado}\nVisão geral",
        "heatmap_todos_os_perfis_resumo",
        (32.0, 16.5),
        "Perfil",
        "Blues",
        limites=limites,
        cbar_label="Média da Nota",
        wrap_perfil=12,
        fontsize_anotacao=9.6,
        fontsize_perfil=9.3,
        fontsize_hipotese=12.2,
        fontsize_titulo=21,
    )
    grupos_colunas = np.array_split(np.asarray(matriz.columns), 2)
    for numero, colunas in enumerate(grupos_colunas, start=1):
        saidas += _plotar_heatmap_texto_completo(
            matriz.loc[:, list(colunas)],
            f"{titulo_consolidado}\nDetalhe {numero} de 2",
            f"heatmap_todos_os_perfis_detalhe_{numero:02d}",
            (22.0, 16.2),
            "Perfil",
            "Blues",
            limites=limites,
            cbar_label="Média da Nota",
            wrap_perfil=12,
            fontsize_anotacao=11.4,
            fontsize_perfil=10.4,
            fontsize_hipotese=12.6,
            fontsize_titulo=20,
        )

    _remover_saidas_graficas("legenda_perfis_todos")
    df = carregar_respostas()
    medias = pd.DataFrame(
        {
            "Hipótese ID": [h.codigo for h in HIPOTESES],
            "Tópico": [h.topico for h in HIPOTESES],
            "Média Geral": [round(float(df[h.texto].mean()), 2) for h in HIPOTESES],
        }
    ).sort_values("Média Geral", ascending=True)
    escrever_csv(medias.sort_values("Média Geral", ascending=False), DADOS_DIR / "resumo_hipoteses.csv")
    fig, ax = plt.subplots(figsize=A4_RETRATO, constrained_layout=True)
    norm_resumo = Normalize(vmin=1, vmax=5)
    cores = [mpl.colormaps["Blues"](norm_resumo(valor)) for valor in medias["Média Geral"]]
    barras = ax.barh(
        [f"{codigo} — {topico}" for codigo, topico in zip(medias["Hipótese ID"], medias["Tópico"])],
        medias["Média Geral"],
        color=cores,
    )
    ax.bar_label(barras, fmt="%.2f", padding=4, fontsize=9, fontweight="bold")
    ax.axvline(3, color=COR_NEUTRA, linestyle="--", linewidth=1.2, label="Ponto médio da escala")
    ax.set_xlim(1, 5)
    ax.set_xlabel("Média geral das 79 respostas")
    ax.set_ylabel("")
    ax.set_title("Prioridade geral das hipóteses", pad=12)
    ax.legend(frameon=False, loc="lower right")
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.grid(axis="x")
    ax.grid(axis="y", visible=False)
    saidas += _exportar(fig, "resumo_hipoteses_todos_perfis")
    return saidas


def gerar_resumo_validacao() -> Path:
    df = carregar_respostas()
    grupos = expandir_grupos(df)
    resumo = pd.DataFrame(
        [
            {"Indicador": "Respostas totais", "Valor": len(df)},
            {"Indicador": "Respostas Likert completas", "Valor": int(df[COLUNAS_HIPOTESES].notna().all(axis=1).sum())},
            {"Indicador": "Demografia completa", "Valor": int(df[[COL_TIPO, COL_TEMPO, COL_IDADE, COL_GENERO]].notna().all(axis=1).sum())},
            {"Indicador": "Grupo Coach (inclui Ambos)", "Valor": int((grupos["Grupo"] == "Coach").sum())},
            {"Indicador": "Grupo Praticante (exclusivo)", "Valor": int((grupos["Grupo"] == "Praticante").sum())},
            {"Indicador": "Respostas Ambos", "Valor": int((df[COL_TIPO] == "Ambos").sum())},
        ]
    )
    caminho = DADOS_DIR / "resumo_validacao.csv"
    escrever_csv(resumo, caminho)
    return caminho


def gerar_todos() -> list[Path]:
    preparar_diretorios()
    saidas: list[Path] = [gerar_resumo_validacao()]
    saidas += gerar_legenda_hipoteses()
    saidas += gerar_distribuicao_perfis_genero_tempo()
    saidas += gerar_distribuicao_perfis_idade_genero()
    saidas += gerar_distribuicao_perfis_idade_tempo()
    saidas += gerar_perfis_praticante()
    saidas += gerar_perfis_coach()
    saidas += gerar_perfis_completos()
    saidas += gerar_distribuicao_coach_vs_praticante()
    for slug in ANALISES:
        saidas += gerar_analise_hipoteses(slug)
    saidas += gerar_distribuicao_prioridade()
    saidas += gerar_hipoteses_todos_perfis()
    return saidas