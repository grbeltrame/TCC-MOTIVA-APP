from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd
from PIL import Image


PASTA = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PASTA))

from configuracao import AMOSTRA_MINIMA  # noqa: E402
from dados_ux import (  # noqa: E402
    COL_GENERO,
    COL_IDADE,
    COL_TEMPO,
    COL_TIPO,
    COLUNAS_HIPOTESES,
    analise_hipoteses,
    carregar_respostas,
    expandir_grupos,
    matriz_hipoteses,
    tabela_contingencia,
    texto_publicacao,
)


def test_base_tem_79_respostas_e_likert_valido():
    df = carregar_respostas()
    assert len(df) == 79
    assert df[COLUNAS_HIPOTESES].notna().all().all()
    assert set(pd.unique(df[COLUNAS_HIPOTESES].to_numpy().ravel())) <= {1, 2, 3, 4, 5}


def test_demografia_completa_tem_77_registros():
    df = carregar_respostas()
    assert int(df[[COL_TIPO, COL_TEMPO, COL_IDADE, COL_GENERO]].notna().all(axis=1).sum()) == 77


def test_classificacao_replica_regra_antiga_para_ambos():
    grupos = expandir_grupos(carregar_respostas())
    assert int((grupos["Grupo"] == "Coach").sum()) == 13
    assert int((grupos["Grupo"] == "Praticante").sum()) == 66


def test_contingencias_preservam_registros_validos():
    df = carregar_respostas()
    for linhas, colunas, nome_csv in (
        (COL_GENERO, COL_TEMPO, "distribuicao_perfis_genero_tempo.csv"),
        (COL_IDADE, COL_GENERO, "distribuicao_perfis_idade_genero.csv"),
        (COL_IDADE, COL_TEMPO, "distribuicao_perfis_idade_tempo.csv"),
    ):
        esperado = int(df[[linhas, colunas]].notna().all(axis=1).sum())
        assert int(tabela_contingencia(df, linhas, colunas).to_numpy().sum()) == esperado
        tabela_antiga = pd.crosstab(df[linhas], df[colunas]).sort_index().sort_index(axis=1)
        tabela_nova = pd.read_csv(PASTA / "dados" / nome_csv).set_index(linhas).sort_index().sort_index(axis=1)
        pd.testing.assert_frame_equal(tabela_nova, tabela_antiga, check_names=False)


def test_detalhe_preserva_todos_os_perfis_e_resumo_filtra_n():
    longa, legenda = analise_hipoteses(carregar_respostas(), [COL_GENERO, COL_IDADE], "teste")
    completa, _ = matriz_hipoteses(longa, somente_resumo=False)
    resumo, legenda_resumo = matriz_hipoteses(longa, somente_resumo=True)
    assert completa.shape == (20, len(legenda))
    assert resumo.shape == (20, len(legenda_resumo))
    assert (legenda_resumo["N do Perfil"] >= AMOSTRA_MINIMA).all()


def test_csvs_gerados_correspondem_a_base_e_aos_grupos():
    dados = PASTA / "dados"
    for nome in (
        "distribuicao_perfis_genero_tempo.csv",
        "distribuicao_perfis_idade_genero.csv",
        "distribuicao_perfis_idade_tempo.csv",
    ):
        tabela = pd.read_csv(dados / nome)
        assert int(tabela.select_dtypes("number").to_numpy().sum()) == 77

    comparacao = pd.read_csv(dados / "distribuicao_coach_vs_praticante.csv")
    genero = comparacao[comparacao["Dimensão"] == "Gênero"]
    grupos = expandir_grupos(carregar_respostas())
    for grupo in ("Coach", "Praticante"):
        esperado = int(grupos.loc[grupos["Grupo"] == grupo, COL_GENERO].notna().sum())
        observado = int(genero.loc[genero["Grupo"] == grupo, "Número de Pessoas"].sum())
        assert observado == esperado

    coach = pd.read_csv(dados / "perfis_coach.csv")
    alias = pd.read_csv(dados / "perfis_completos_coach.csv")
    pd.testing.assert_frame_equal(coach, alias)
    praticante = pd.read_csv(dados / "perfis_praticante.csv")
    for grupo, tabela in (("Coach", coach), ("Praticante", praticante)):
        base_grupo = grupos[grupos["Grupo"] == grupo]
        esperado = int(base_grupo[[COL_IDADE, COL_TEMPO, COL_GENERO]].notna().all(axis=1).sum())
        assert int(tabela["Número de Respondentes"].sum()) == esperado

    praticante_antigo = pd.read_csv(PASTA.parent / "ux_tests" / "perfis_praticante.csv")
    colunas = ["Perfil Praticante", "Número de Respondentes"]
    pd.testing.assert_frame_equal(
        praticante[colunas].sort_values(colunas).reset_index(drop=True),
        praticante_antigo[colunas].sort_values(colunas).reset_index(drop=True),
    )

    for nome, coluna_perfil in (
        ("perfis_coach.csv", "Perfil"),
        ("perfis_completos_coach.csv", "Perfil"),
    ):
        novo = pd.read_csv(dados / nome)
        antigo = pd.read_csv(PASTA.parent / "ux_tests" / nome)
        colunas_comparacao = [coluna_perfil, "Número de Respondentes"]
        pd.testing.assert_frame_equal(
            novo[colunas_comparacao].sort_values(colunas_comparacao).reset_index(drop=True),
            antigo[colunas_comparacao].sort_values(colunas_comparacao).reset_index(drop=True),
        )

    base = carregar_respostas()[[COL_IDADE, COL_TEMPO, COL_GENERO, COL_TIPO]].dropna().copy()
    base["Perfil Completo"] = base[[COL_IDADE, COL_TEMPO, COL_GENERO, COL_TIPO]].astype(str).agg(" | ".join, axis=1)
    base["Perfil Completo"] = base["Perfil Completo"].map(texto_publicacao)
    combinado_esperado = base["Perfil Completo"].value_counts().rename("Número de Respondentes").reset_index()
    combinado_novo = pd.read_csv(dados / "perfis_combinados.csv")
    colunas_combinado = ["Perfil Completo", "Número de Respondentes"]
    pd.testing.assert_frame_equal(
        combinado_novo[colunas_combinado].sort_values(colunas_combinado).reset_index(drop=True),
        combinado_esperado[colunas_combinado].sort_values(colunas_combinado).reset_index(drop=True),
    )


def test_pngs_e_pdfs_tem_paridade_e_resolucao_para_publicacao():
    png_dir = PASTA / "graficos" / "png"
    pdf_dir = PASTA / "graficos" / "pdf"
    pngs = {arquivo.stem for arquivo in png_dir.glob("*.png")}
    pdfs = {arquivo.stem for arquivo in pdf_dir.glob("*.pdf")}
    assert pngs == pdfs
    assert {
        "perfis_completos_coach",
        "heatmap_todos_os_perfis_resumo",
        "heatmap_todos_os_perfis_detalhe_01",
        "heatmap_todos_os_perfis_detalhe_02",
    } <= pngs
    assert {
        "perfis_praticante_resumo",
        "perfis_praticante_detalhe_01",
        "perfis_praticante_detalhe_02",
    }.isdisjoint(pngs)
    for arquivo in png_dir.glob("*.png"):
        with Image.open(arquivo) as imagem:
            assert min(imagem.size) >= 1300
            dpi = imagem.info.get("dpi", (0, 0))
            assert min(dpi) >= 299
    for arquivo in pdf_dir.glob("*.pdf"):
        assert arquivo.stat().st_size > 1_000
        assert arquivo.read_bytes()[:4] == b"%PDF"
