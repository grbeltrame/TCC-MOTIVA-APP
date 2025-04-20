# Importação das bibliotecas necessárias
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import textwrap
import os

# Dicionário com caminhos e limites mínimos de respondentes por distribuição
arquivos_com_limites = {
    "scripts_gerais/ux_tests/hipoteses_por_genero_tempo.csv": 7,
    "scripts_gerais/ux_tests/hipoteses_por_idade_tempo.csv": 7,
    "scripts_gerais/ux_tests/hipoteses_por_genero_idade.csv": 7
}

# Lista para armazenar os DataFrames filtrados
dfs_filtrados = []

# Processa cada arquivo
for caminho, limite in arquivos_com_limites.items():
    if os.path.exists(caminho):
        df = pd.read_csv(caminho)
        
        # Conta o número de respondentes por perfil
        contagem = df["Perfil"].value_counts()
        
        # Mantém apenas os perfis com número de registros ≥ limite
        perfis_validos = contagem[contagem >= limite].index
        df_filtrado = df[df["Perfil"].isin(perfis_validos)]
        
        dfs_filtrados.append(df_filtrado)
    else:
        print(f"Aviso: Arquivo não encontrado - {caminho}")

# Junta todos os arquivos em um único DataFrame
df_consolidado = pd.concat(dfs_filtrados, ignore_index=True)

# Garante que não há valores nulos
df_consolidado = df_consolidado.dropna()

# Cria a tabela no formato: linhas = hipóteses, colunas = perfis, valores = média da nota
tabela = df_consolidado.pivot(index="Hipótese", columns="Perfil", values="Média da Nota")

# Ordena as hipóteses pela média geral
ordem = tabela.mean(axis=1).sort_values(ascending=False).index
tabela = tabela.reindex(ordem)

# Quebra os textos das hipóteses para melhor visualização
tabela.index = [textwrap.fill(h, width=60) for h in tabela.index]

# Define o tamanho da figura dinamicamente conforme o número de perfis
altura = max(10, 0.5 * len(tabela))
largura = max(14, 0.5 * len(tabela.columns))

# Criação do heatmap
plt.figure(figsize=(largura, altura))
sns.set(font_scale=0.6)
sns.heatmap(
    tabela,
    annot=True,
    fmt=".2f",
    cmap="coolwarm",
    linewidths=0.5,
    linecolor='gray',
    cbar_kws={"label": "Média da Nota"}
)

# Título e labels
plt.title("Média das Hipóteses por Perfil Prioritário", fontsize=14, pad=20)
plt.xlabel("Perfil")
plt.ylabel("Hipóteses")

# Ajustes finais
plt.tight_layout()
plt.savefig("scripts_gerais/ux_tests/heatmap_todos_os_perfis.png", dpi=300, bbox_inches='tight')
plt.show()
