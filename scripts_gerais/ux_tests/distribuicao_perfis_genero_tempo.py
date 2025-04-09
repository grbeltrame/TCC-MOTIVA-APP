# Queremos analisar o comportamental de cada perfil levando em conta genero e tempo de prática e como isso 
# influencia na percepção de valor das funcionalidades.

# Importação das bibliotecas necessárias
import pandas as pd               # Para leitura e manipulação dos dados
import seaborn as sns             # Para criação do gráfico de calor (heatmap)
import matplotlib.pyplot as plt   # Para plotar o gráfico
import os                         # Para garantir que a pasta de saída exista

# Etapa 1: Leitura do CSV contendo as respostas do formulário
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Etapa 2: Nome exato das colunas usadas para agrupar os perfis
coluna_genero = "Qual seu gênero"
coluna_tempo = "Há quanto tempo você treina crossfit?"


# Garantindo que não haja valores ausentes (NaN) nas colunas usadas.
df = df.dropna(subset=[coluna_genero, coluna_tempo])


# Etapa 3: Criação da tabela cruzada (crosstab) com a contagem dos perfis
# Cada célula vai mostrar quantas pessoas têm aquela combinação específica
tabela_perfis = pd.crosstab(df[coluna_genero], df[coluna_tempo])

# Etapa 4: Exibição da tabela no terminal para validação (opcional)
print("Distribuição dos perfis por gênero e tempo de prática:")
print(tabela_perfis)

# Etapa 5: Criação do gráfico de calor para facilitar a visualização
plt.figure(figsize=(10, 6))  # Define o tamanho da imagem
sns.heatmap(
    tabela_perfis, 
    annot=True, 
    fmt="d", 
    cmap="Purples",   # Paleta visual consistente com identidade
    linewidths=.5,    # Linhas entre as células para facilitar leitura
    cbar_kws={'label': 'Número de Respondentes'}
)

# Etapa 6: Adição de título e rótulos dos eixos
plt.title("Distribuição de Respondentes por Gênero e Tempo de Prática", fontsize=14)
plt.xlabel("Tempo de Prática no CrossFit")
plt.ylabel("Gênero")

# Etapa 7: Exportação do gráfico como imagem e da tabela como CSV
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/distribuicao_perfis_genero_tempo.png", dpi=300, bbox_inches='tight')
tabela_perfis.to_csv("scripts_gerais/ux_tests/distribuicao_perfis_genero_tempo.csv")

# Etapa 8: Exibição do gráfico
plt.tight_layout()
plt.show()
