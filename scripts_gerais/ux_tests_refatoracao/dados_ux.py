from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

import pandas as pd

from configuracao import (
    AMOSTRA_MINIMA,
    ARQUIVO_RESPOSTAS,
    DEMOGRAFIA_COMPLETA_ESPERADA,
    GENERO_ORDEM,
    IDADE_ORDEM,
    TEMPO_ORDEM,
    TOTAL_ESPERADO,
)


COL_TIPO = "Com qual dessas opções você se identifica?"
COL_TEMPO = "Há quanto tempo você treina crossfit?"
COL_IDADE = "Qual sua faixa de idade?"
COL_GENERO = "Qual seu gênero"

TIPO_COACH = "Sou coach/instrutor de CrossFit"
TIPO_PRATICANTE = "Sou praticante/" + "al" + "uno de CrossFit"
ROTULO_PRATICANTE = "Sou praticante/atleta de CrossFit"
TIPO_AMBOS = "Ambos"


@dataclass(frozen=True)
class Hipotese:
    codigo: str
    topico: str
    texto: str


HIPOTESES = [
    Hipotese("H01", "Interação fora do box", "Eu desejo uma forma prática e rápida de interagir com pessoas fora do meu box."),
    Hipotese("H02", "Apps e sociabilidade", "Os aplicativos atualmente usados não atendem à minha necessidade de sociabilidade."),
    Hipotese("H03", "Comparação com perfis semelhantes", "Comparar meu desempenho com pessoas de perfil físico semelhante (idade, gênero, peso, comorbidades etc.) é interessante para mim."),
    Hipotese("H04", "Desempenho público", "Ter a opção de cadastrar meu desempenho no esporte e deixá-lo público é algo que me atrai."),
    Hipotese("H05", "Rankings de atletas e WODs", "Rankings de atletas por WOD e de WODs mais curtidos/concluídos tornam a minha experiência no aplicativo mais interessante."),
    Hipotese("H06", "Feed e comunidade", "Um feed com postagens de WODs, conteúdos, espaço para comentar e acompanhar outros atletas é algo que me interessa."),
    Hipotese("H07", "Selos e conquistas", "Eu valorizo selos e conquistas virtuais como forma de reconhecimento pelo meu esforço."),
    Hipotese("H08", "Dificuldade dos coaches", "Eu considero que meus coaches têm dificuldade em montar WODs equilibrados."),
    Hipotese("H09", "Desmotivação com WODs", "Eu me sinto desmotivado com WODs mal estruturados."),
    Hipotese("H10", "Avaliação da evolução", "Avaliar minha evolução física e esportiva dentro de um aplicativo é algo que considero importante."),
    Hipotese("H11", "Avaliação por profissionais", "A possibilidade de ter meu desempenho avaliado por profissionais dentro da plataforma é algo positivo para mim"),
    Hipotese("H12", "Sugestões automáticas de WODs", "Receber sugestões automáticas de WODs com base no meu perfil/histórico me interessa."),
    Hipotese("H13", "Análise visual da evolução", "Ter uma análise visual da minha evolução (gráficos, comparações, registros) me motiva a usar o aplicativo com mais frequência."),
    Hipotese("H14", "Comunicação de campeonatos", "Eu considero que centralizar a comunicação entre atletas e organizadores de campeonatos no aplicativo é algo importante."),
    Hipotese("H15", "Acompanhar campeonatos", "Acompanhar campeonatos externos ao meu box, com transmissões ao vivo e leaderboards, é algo que me interessa."),
    Hipotese("H16", "Agenda de eventos", "Ter uma agenda de eventos futuros (com lembretes) é útil para mim."),
    Hipotese("H17", "Vídeos de qualificação", "Permitir envio de vídeos para qualificação em campeonatos (Open, Monstar, TCB e outros) é uma funcionalidade relevante para mim."),
    Hipotese("H18", "Loja de produtos", "Uma loja com produtos relacionados ao esporte (roupas, equipamentos, suplementos etc.) dentro do aplicativo me interessa."),
    Hipotese("H19", "Condições com marcas", "Eu gostaria de ter acesso a condições especiais com marcas parceiras dentro do aplicativo."),
    Hipotese("H20", "Serviços de profissionais", "Ter acesso a serviços de profissionais como nutricionistas e fisioterapeutas dentro do aplicativo me interessa."),
]

COLUNAS_HIPOTESES = [h.texto for h in HIPOTESES]
MAPA_CODIGO = {h.texto: h.codigo for h in HIPOTESES}
MAPA_TOPICO = {h.texto: h.topico for h in HIPOTESES}
MAPA_TEXTO = {h.codigo: h.texto for h in HIPOTESES}
MAPA_TOPICO_CODIGO = {h.codigo: h.topico for h in HIPOTESES}


def texto_publicacao(valor: object) -> str:
    return str(valor).replace(TIPO_PRATICANTE, ROTULO_PRATICANTE)


def carregar_respostas() -> pd.DataFrame:
    df = pd.read_csv(ARQUIVO_RESPOSTAS)
    obrigatorias = [COL_TIPO, COL_TEMPO, COL_IDADE, COL_GENERO, *COLUNAS_HIPOTESES]
    faltantes = [col for col in obrigatorias if col not in df.columns]
    if faltantes:
        raise ValueError(f"Colunas obrigatórias ausentes: {faltantes}")
    if len(df) != TOTAL_ESPERADO:
        raise ValueError(f"Esperadas {TOTAL_ESPERADO} respostas; encontradas {len(df)}.")
    for coluna in COLUNAS_HIPOTESES:
        df[coluna] = pd.to_numeric(df[coluna], errors="coerce")
    invalidas = int((~df[COLUNAS_HIPOTESES].isin([1, 2, 3, 4, 5])).sum().sum())
    if invalidas:
        raise ValueError(f"Foram encontradas {invalidas} notas Likert inválidas ou ausentes.")
    completas = int(df[[COL_TIPO, COL_TEMPO, COL_IDADE, COL_GENERO]].notna().all(axis=1).sum())
    if completas != DEMOGRAFIA_COMPLETA_ESPERADA:
        raise ValueError(
            f"Esperados {DEMOGRAFIA_COMPLETA_ESPERADA} registros demográficos completos; encontrados {completas}."
        )
    return df


def expandir_grupos(df: pd.DataFrame) -> pd.DataFrame:
    coach = df[df[COL_TIPO].isin([TIPO_COACH, TIPO_AMBOS])].copy()
    coach["Grupo"] = "Coach"
    praticante = df[df[COL_TIPO] == TIPO_PRATICANTE].copy()
    praticante["Grupo"] = "Praticante"
    return pd.concat([coach, praticante], ignore_index=True)


def filtrar_grupo(df: pd.DataFrame, grupo: str) -> pd.DataFrame:
    if grupo == "Coach":
        return df[df[COL_TIPO].isin([TIPO_COACH, TIPO_AMBOS])].copy()
    if grupo == "Praticante":
        return df[df[COL_TIPO] == TIPO_PRATICANTE].copy()
    raise ValueError(f"Grupo desconhecido: {grupo}")


def _ordem_dimensao(coluna: str) -> list[str]:
    return {
        COL_IDADE: IDADE_ORDEM,
        COL_TEMPO: TEMPO_ORDEM,
        COL_GENERO: GENERO_ORDEM,
    }[coluna]


def preparar_categorias(df: pd.DataFrame) -> pd.DataFrame:
    resultado = df.copy()
    resultado[COL_IDADE] = pd.Categorical(resultado[COL_IDADE], IDADE_ORDEM, ordered=True)
    resultado[COL_TEMPO] = pd.Categorical(resultado[COL_TEMPO], TEMPO_ORDEM, ordered=True)
    resultado[COL_GENERO] = pd.Categorical(resultado[COL_GENERO], GENERO_ORDEM, ordered=True)
    return resultado


def tabela_contingencia(df: pd.DataFrame, linhas: str, colunas: str) -> pd.DataFrame:
    validos = preparar_categorias(df.dropna(subset=[linhas, colunas]))
    tabela = pd.crosstab(validos[linhas], validos[colunas], dropna=False)
    return tabela.reindex(index=_ordem_dimensao(linhas), columns=_ordem_dimensao(colunas), fill_value=0)


def perfis_contagem(df: pd.DataFrame, grupo: str | None = None, incluir_tipo: bool = False) -> pd.DataFrame:
    base = filtrar_grupo(df, grupo) if grupo else df.copy()
    dimensoes = [COL_IDADE, COL_TEMPO, COL_GENERO]
    if incluir_tipo:
        dimensoes.append(COL_TIPO)
    base = preparar_categorias(base.dropna(subset=dimensoes))
    contagem = (
        base.groupby(dimensoes, observed=True)
        .size()
        .rename("Número de Respondentes")
        .reset_index()
        .sort_values("Número de Respondentes", ascending=False, kind="stable")
    )
    contagem["Perfil"] = contagem[dimensoes].astype(str).agg(" | ".join, axis=1)
    contagem["Perfil"] = contagem["Perfil"].map(texto_publicacao)
    return contagem[["Perfil", "Número de Respondentes", *dimensoes]].reset_index(drop=True)


def analise_hipoteses(df: pd.DataFrame, dimensoes: Sequence[str], nome_dimensao: str) -> tuple[pd.DataFrame, pd.DataFrame]:
    base = preparar_categorias(df.dropna(subset=[*dimensoes, *COLUNAS_HIPOTESES]))
    medias = base.groupby(list(dimensoes), observed=True)[COLUNAS_HIPOTESES].mean()
    tamanhos = base.groupby(list(dimensoes), observed=True).size().rename("N do Perfil")
    medias = medias.join(tamanhos).reset_index()
    medias["Perfil"] = medias[list(dimensoes)].astype(str).agg(" | ".join, axis=1)
    medias = medias.sort_values(list(dimensoes), kind="stable").reset_index(drop=True)
    medias["Perfil ID"] = [f"P{i:02d}" for i in range(1, len(medias) + 1)]
    legenda = medias[["Perfil ID", "Perfil", "N do Perfil"]].copy()
    legenda["Amostra"] = legenda["N do Perfil"].map(
        lambda n: f"Atenção: n < {AMOSTRA_MINIMA}" if n < AMOSTRA_MINIMA else "Resumo elegível"
    )
    longa = medias.melt(
        id_vars=[*dimensoes, "Perfil", "Perfil ID", "N do Perfil"],
        value_vars=COLUNAS_HIPOTESES,
        var_name="Hipótese",
        value_name="Média da Nota",
    )
    longa["Hipótese ID"] = longa["Hipótese"].map(MAPA_CODIGO)
    longa["Tópico"] = longa["Hipótese"].map(MAPA_TOPICO)
    longa["Média da Nota"] = longa["Média da Nota"].round(2)
    longa["Amostra < 7"] = longa["N do Perfil"] < AMOSTRA_MINIMA
    longa["Análise"] = nome_dimensao
    ordem_colunas = [
        "Análise",
        "Perfil ID",
        "Perfil",
        "N do Perfil",
        "Amostra < 7",
        "Hipótese ID",
        "Tópico",
        "Hipótese",
        "Média da Nota",
        *dimensoes,
    ]
    return longa[ordem_colunas], legenda


def matriz_hipoteses(longa: pd.DataFrame, somente_resumo: bool = False) -> tuple[pd.DataFrame, pd.DataFrame]:
    base = longa[longa["N do Perfil"] >= AMOSTRA_MINIMA] if somente_resumo else longa
    legenda = base[["Perfil ID", "Perfil", "N do Perfil", "Amostra < 7"]].drop_duplicates()
    matriz = base.pivot(index="Hipótese ID", columns="Perfil ID", values="Média da Nota")
    ordem_h = [h.codigo for h in HIPOTESES]
    ordem_p = legenda["Perfil ID"].tolist()
    return matriz.reindex(index=ordem_h, columns=ordem_p), legenda.reset_index(drop=True)


def perfis_prioritarios(df: pd.DataFrame, grupo: str, quantidade: int) -> tuple[pd.DataFrame, pd.DataFrame]:
    base = filtrar_grupo(df, grupo)
    contagem = perfis_contagem(df, grupo=grupo).head(quantidade)
    perfis = set(contagem["Perfil"])
    base = base.dropna(subset=[COL_IDADE, COL_TEMPO, COL_GENERO, *COLUNAS_HIPOTESES]).copy()
    base["Perfil"] = base[[COL_IDADE, COL_TEMPO, COL_GENERO]].astype(str).agg(" | ".join, axis=1)
    base = base[base["Perfil"].isin(perfis)]
    medias = base.groupby("Perfil")[COLUNAS_HIPOTESES].mean()
    ordem = contagem["Perfil"].tolist()
    medias = medias.reindex(ordem)
    ids = [f"P{i:02d}" for i in range(1, len(ordem) + 1)]
    medias.columns.name = None
    medias.index = ids
    matriz = medias.T
    matriz.index = [MAPA_CODIGO[col] for col in matriz.index]
    legenda = contagem[["Perfil", "Número de Respondentes"]].copy()
    legenda.insert(0, "Perfil ID", ids)
    legenda = legenda.rename(columns={"Número de Respondentes": "N do Perfil"})
    return matriz, legenda


def legenda_hipoteses() -> pd.DataFrame:
    return pd.DataFrame(
        [{"Hipótese ID": h.codigo, "Tópico": h.topico, "Hipótese": h.texto} for h in HIPOTESES]
    )


def escrever_csv(df: pd.DataFrame, caminho) -> None:
    df.to_csv(caminho, index=False, encoding="utf-8-sig")
