import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

colunas = ["Qual sua faixa de idade?", "Há quanto tempo você treina crossfit?", "Qual seu gênero", "Com qual dessas opções você se identifica?"]
df_filtrado = df[colunas].dropna()

# Considera apenas "Praticante"
df_praticante = df_filtrado[df_filtrado["Com qual dessas opções você se identifica?"] == "Sou praticante/aluno de CrossFit"]

df_praticante["Perfil Praticante"] = (
    df_praticante["Qual sua faixa de idade?"].astype(str) + " | " +
    df_praticante["Há quanto tempo você treina crossfit?"].astype(str) + " | " +
    df_praticante["Qual seu gênero"].astype(str)
)

contagem_praticante = df_praticante["Perfil Praticante"].value_counts().reset_index()
contagem_praticante.columns = ["Perfil Praticante", "Número de Respondentes"]

plt.figure(figsize=(12, len(contagem_praticante) * 0.4))
sns.barplot(y="Perfil Praticante", x="Número de Respondentes", data=contagem_praticante, palette="Greens_d")

# Rótulos dentro das barras
for i, row in contagem_praticante.iterrows():
    plt.text(
        x=row["Número de Respondentes"] - 0.5,
        y=i,
        s=str(row["Número de Respondentes"]),
        va='center',
        ha='right',
        color='white',
        fontsize=9,
        weight='bold'
    )

plt.title("Perfis de Praticantes (Idade | Tempo | Gênero)", fontsize=14)
plt.xlabel("Número de Respondentes")
plt.ylabel("Perfil")
plt.tight_layout()

os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/perfis_praticante.png", dpi=300, bbox_inches='tight')
contagem_praticante.to_csv("scripts_gerais/ux_tests/perfis_praticante.csv", index=False)

plt.show()
