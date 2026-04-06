import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import textwrap
import os

df = pd.read_csv("scripts_gerais/respostas_formulario.csv")

col_tipo = "Com qual dessas opções você se identifica?"
col_tempo = "Há quanto tempo você treina crossfit?"
col_idade = "Qual sua faixa de idade?"
col_genero = "Qual seu gênero"

colunas_hipoteses = [
    "Eu desejo uma forma prática e rápida de interagir com pessoas fora do meu box.",
    "Os aplicativos atualmente usados não atendem à minha necessidade de sociabilidade.",
    "Comparar meu desempenho com pessoas de perfil físico semelhante (idade, gênero, peso, comorbidades etc.) é interessante para mim.",
    "Ter a opção de cadastrar meu desempenho no esporte e deixá-lo público é algo que me atrai.",
    "Rankings de atletas por WOD e de WODs mais curtidos/concluídos tornam a minha experiência no aplicativo mais interessante.",
    "Um feed com postagens de WODs, conteúdos, espaço para comentar e acompanhar outros atletas é algo que me interessa.",
    "Eu valorizo selos e conquistas virtuais como forma de reconhecimento pelo meu esforço.",
    "Eu considero que meus coaches têm dificuldade em montar WODs equilibrados.",
    "Eu me sinto desmotivado com WODs mal estruturados.",
    "Avaliar minha evolução física e esportiva dentro de um aplicativo é algo que considero importante.",
    "A possibilidade de ter meu desempenho avaliado por profissionais dentro da plataforma é algo positivo para mim",
    "Receber sugestões automáticas de WODs com base no meu perfil/histórico me interessa.",
    "Ter uma análise visual da minha evolução (gráficos, comparações, registros) me motiva a usar o aplicativo com mais frequência.",
    "Eu considero que centralizar a comunicação entre atletas e organizadores de campeonatos no aplicativo é algo importante.",
    "Acompanhar campeonatos externos ao meu box, com transmissões ao vivo e leaderboards, é algo que me interessa.",
    "Ter uma agenda de eventos futuros (com lembretes) é útil para mim.",
    "Permitir envio de vídeos para qualificação em campeonatos (Open, Monstar, TCB e outros) é uma funcionalidade relevante para mim.",
    "Uma loja com produtos relacionados ao esporte (roupas, equipamentos, suplementos etc.) dentro do aplicativo me interessa.",
    "Eu gostaria de ter acesso a condições especiais com marcas parceiras dentro do aplicativo.",
    "Ter acesso a serviços de profissionais como nutricionistas e fisioterapeutas dentro do aplicativo me interessa.",
]

df = df.dropna(subset=[col_tipo, col_tempo, col_idade, col_genero])

def classificar_tipo(valor):
    if valor in ["Sou coach/instrutor de CrossFit", "Ambos"]:
        return "Coach"
    elif valor == "Sou praticante/aluno de CrossFit":
        return "Praticante"
    return None

df["Tipo"] = df[col_tipo].apply(classificar_tipo)
df = df.dropna(subset=["Tipo"])
df["Perfil"] = df["Tipo"] + " | " + df[col_genero] + " | " + df[col_idade] + " | " + df[col_tempo]

for col in colunas_hipoteses:
    df[col] = pd.to_numeric(df[col], errors="coerce")

perfis_coach = [
    "Coach | Homem | Entre 30 e 40 anos | Mais de 5 anos",
    "Coach | Homem | Entre 40 e 50 anos | Mais de 5 anos",
    "Coach | Homem | Entre 20 e 30 anos | Entre 1 e 3 anos",
]

perfis_aluno = [
    "Praticante | Mulher | Entre 20 e 30 anos | Entre 3 e 5 anos",
    "Praticante | Homem | Entre 30 e 40 anos | Entre 1 e 3 anos",
    "Praticante | Mulher | Entre 40 e 50 anos | Mais de 5 anos",
    "Praticante | Homem | Entre 30 e 40 anos | Entre 3 e 5 anos",
]

def gerar_heatmap(df_full, perfis, titulo, nome_arquivo):
    df_sel = df_full[df_full["Perfil"].isin(perfis)].copy()

    if df_sel.empty:
        print(f"Nenhum dado para: {titulo}")
        return

    df_long = df_sel[["Perfil"] + colunas_hipoteses].melt(
        id_vars="Perfil",
        var_name="Hipótese",
        value_name="Nota"
    )
    df_long["Nota"] = pd.to_numeric(df_long["Nota"], errors="coerce")
    df_long = df_long.dropna(subset=["Nota"])

    tabela = df_long.groupby(["Hipótese", "Perfil"])["Nota"].mean().unstack()
    ordem = tabela.mean(axis=1).sort_values(ascending=False).index
    tabela = tabela.reindex(ordem)
    tabela.index = [textwrap.fill(h, width=55) for h in tabela.index]
    tabela.columns = [c.split(" | ", 1)[1] for c in tabela.columns]

    altura = max(12, 0.6 * len(tabela))
    largura = max(10, 2.5 * len(tabela.columns))

    plt.figure(figsize=(largura, altura))
    sns.set(font_scale=0.75)
    sns.heatmap(
        tabela,
        annot=True,
        fmt=".2f",
        cmap="coolwarm",
        linewidths=0.5,
        linecolor="gray",
        vmin=1, vmax=5,
        cbar_kws={"label": "Média da Nota (1–5)"}
    )
    plt.title(titulo, fontsize=14, pad=20)
    plt.xlabel("Perfil")
    plt.ylabel("Hipóteses")
    plt.xticks(rotation=25, ha="right")
    plt.tight_layout()
    os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
    plt.savefig(nome_arquivo, dpi=300, bbox_inches="tight")
    plt.show()
    print(f"Salvo: {nome_arquivo}")

gerar_heatmap(
    df,
    perfis_coach,
    "Média das Hipóteses por Perfil — Coaches",
    "scripts_gerais/ux_tests/heatmap_coaches.png"
)

print("=== Iniciando heatmap de praticantes ===")
gerar_heatmap(
    df,
    perfis_aluno,
    "Média das Hipóteses por Perfil — Praticantes",
    "scripts_gerais/ux_tests/heatmap_praticantes.png"
)
print("=== Finalizado ===")