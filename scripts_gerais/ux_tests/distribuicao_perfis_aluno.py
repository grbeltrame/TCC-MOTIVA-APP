import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

colunas = ["Qual sua faixa de idade?", "Há quanto tempo você treina crossfit?", "Qual seu gênero", "Com qual dessas opções você se identifica?"]

df_praticante = df[df["Com qual dessas opções você se identifica?"].isin([
    "Sou praticante/aluno de CrossFit", "Ambos"
])]
df_praticante = df_praticante[colunas[:-1]].dropna().copy()

df_praticante["Perfil Praticante"] = (
    df_praticante["Qual sua faixa de idade?"].astype(str) + " | " +
    df_praticante["Há quanto tempo você treina crossfit?"].astype(str) + " | " +
    df_praticante["Qual seu gênero"].astype(str)
)

contagem_praticante = df_praticante["Perfil Praticante"].value_counts().reset_index()
contagem_praticante.columns = ["Perfil Praticante", "Número de Respondentes"]

fig, ax = plt.subplots(figsize=(20, len(contagem_praticante) * 0.9))

sns.barplot(
    y="Perfil Praticante",
    x="Número de Respondentes",
    data=contagem_praticante,
    hue="Perfil Praticante",
    palette="Greens_d",
    legend=False,
    width=0.5,
    ax=ax
)

max_val = contagem_praticante["Número de Respondentes"].max()
ax.set_xlim(0, max_val + 1)

for i, row in contagem_praticante.iterrows():
    ax.text(
        x=row["Número de Respondentes"] + 0.1,
        y=i,
        s=str(row["Número de Respondentes"]),
        va='center',
        ha='left',
        color='black',
        fontsize=14,
        weight='bold'
    )

ax.set_title("Perfis de Praticantes (Idade | Tempo | Gênero)", fontsize=18, pad=15)
ax.set_xlabel("Número de Respondentes", fontsize=16)
ax.set_ylabel("Perfil", fontsize=16)
ax.tick_params(axis='y', labelsize=16)
ax.tick_params(axis='x', labelsize=16)

# left=0.55 reserva 55% da largura para o texto do eixo Y
plt.subplots_adjust(top=0.95, bottom=0.05, left=0.45, right=0.97)

os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/perfis_praticante.png", dpi=300, bbox_inches='tight')
contagem_praticante.to_csv("scripts_gerais/ux_tests/perfis_praticante.csv", index=False)
plt.show()