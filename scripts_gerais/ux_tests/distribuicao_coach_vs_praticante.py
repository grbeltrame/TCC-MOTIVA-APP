import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Caminho do arquivo CSV
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Colunas utilizadas
coluna_cargo = "Com qual dessas opções você se identifica?"
coluna_genero = "Qual seu gênero"
coluna_idade = "Qual sua faixa de idade?"
coluna_tempo = "Há quanto tempo você treina crossfit?"

# Define grupo baseado na resposta
def classificar_grupo(cargo):
    if cargo == "Sou coach/instrutor de CrossFit" or cargo == "Ambos":
        return "Coach"
    elif cargo == "Sou praticante/aluno de CrossFit":
        return "Praticante"
    else:
        return None

df["Grupo"] = df[coluna_cargo].apply(classificar_grupo)
df_filtrado = df[df["Grupo"].isin(["Coach", "Praticante"])]

# Garante que a pasta de saída exista
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)

# Função para gerar dataframe de contagem
def gerar_tabela(coluna):
    return df_filtrado.groupby(["Grupo", coluna]).size().unstack().fillna(0)

# Tabelas de contagem para cada dimensão
tabela_genero = gerar_tabela(coluna_genero)
tabela_idade = gerar_tabela(coluna_idade)
tabela_tempo = gerar_tabela(coluna_tempo)

# Define estilo visual
sns.set(style="whitegrid")
fig, axs = plt.subplots(1, 3, figsize=(18, 6))

# Gráfico 1: Gênero
tabela_genero.T.plot(kind="barh", ax=axs[0], color=["#6A1B9A", "#283593"])
axs[0].set_title("Distribuição por Gênero")
axs[0].set_xlabel("Número de Pessoas")
axs[0].set_ylabel("Gênero")

# Gráfico 2: Faixa Etária
tabela_idade.T.plot(kind="barh", ax=axs[1], color=["#6A1B9A", "#283593"])
axs[1].set_title("Distribuição por Faixa Etária")
axs[1].set_xlabel("Número de Pessoas")
axs[1].set_ylabel("Idade")

# Gráfico 3: Tempo de Prática
tabela_tempo.T.plot(kind="barh", ax=axs[2], color=["#6A1B9A", "#283593"])
axs[2].set_title("Distribuição por Tempo de Prática")
axs[2].set_xlabel("Número de Pessoas")
axs[2].set_ylabel("Tempo")

# Layout final
plt.tight_layout()
plt.savefig("scripts_gerais/ux_tests/distribuicao_coach_vs_praticante.png", dpi=300, bbox_inches='tight')
plt.show()