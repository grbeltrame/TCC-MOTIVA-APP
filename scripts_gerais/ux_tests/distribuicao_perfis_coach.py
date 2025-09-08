import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Leitura do CSV
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Colunas de interesse
col_idade = "Qual sua faixa de idade?"
col_tempo = "Há quanto tempo você treina crossfit?"
col_genero = "Qual seu gênero"
col_categoria = "Com qual dessas opções você se identifica?"

# Filtro para Coachs (inclui "Ambos")
df_coach = df[df[col_categoria].isin(["Sou coach/instrutor de CrossFit", "Ambos"])]
df_coach = df_coach[[col_idade, col_tempo, col_genero]].dropna()
df_coach["Perfil"] = (
    df_coach[col_idade] + " | " +
    df_coach[col_tempo] + " | " +
    df_coach[col_genero]
)

# Contagem dos perfis
contagem_coach = df_coach["Perfil"].value_counts().reset_index()
contagem_coach.columns = ["Perfil", "Número de Respondentes"]

# Salva CSV
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
contagem_coach.to_csv("scripts_gerais/ux_tests/perfis_completos_coach.csv", index=False)

# Gera gráfico

plt.figure(figsize=(12, max(6, 0.5 * len(contagem_coach))))
sns.barplot(y="Perfil", x="Número de Respondentes", data=contagem_coach, palette="Purples")
for i, row in contagem_coach.iterrows():
    plt.text(
        x=row["Número de Respondentes"] - 0.5,
        y=i,
        s=str(row["Número de Respondentes"]),
        va='center',
        ha='right',
        color='black',
        fontsize=9,
        weight='bold'
    )

plt.title("Perfis de Coachs (Idade | Tempo | Gênero)", fontsize=14)
plt.xlabel("Número de Respondentes")
plt.ylabel("Perfil")
plt.tight_layout()

os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/perfis_coach.png", dpi=300, bbox_inches='tight')
contagem_coach.to_csv("scripts_gerais/ux_tests/perfis_coach.csv", index=False)
plt.show()
