# Esta analise busca entender a influencia de questoes fisiologicas, hormonais e comportamentais 
# na jornada do usuario no app. Devido a cada item citado, a preferencia por uma funcionalidade pode variar


# Importação das bibliotecas necessárias
import pandas as pd               # Para leitura e manipulação dos dados
import seaborn as sns             # Para criar o gráfico de calor (heatmap)
import matplotlib.pyplot as plt   # Para exibir o gráfico
import os                         # Para garantir que a pasta de saída exista

# Etapa 1: Leitura do CSV com as respostas do formulário
# O arquivo deve estar salvo no repositório, na pasta scripts_gerais
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Etapa 2: Colunas que serão cruzadas para gerar os perfis
coluna_idade = "Qual sua faixa de idade?"
coluna_genero = "Qual seu gênero"

# Garantindo que não haja valores ausentes (NaN) nas colunas usadas.
df = df.dropna(subset=[coluna_genero, coluna_genero])

# Etapa 3: Criação de uma tabela de contingência (crosstab)
# Ela mostra a quantidade de respondentes por combinação de faixa etária e gênero
tabela_perfis = pd.crosstab(df[coluna_idade], df[coluna_genero])

# Etapa 4: Exibe a tabela no terminal para verificação rápida (opcional)
print("Distribuição dos perfis por faixa etária e gênero:")
print(tabela_perfis)

# Etapa 5: Criação do gráfico de calor (heatmap)
plt.figure(figsize=(10, 6))  # Define o tamanho da imagem
sns.heatmap(
    tabela_perfis, 
    annot=True,              # Mostra os números dentro de cada célula
    fmt="d",                 # Formato inteiro
    cmap="BuPu",             # Paleta de cor azul-púrpura
    linewidths=.5,           # Linhas entre células
    cbar_kws={'label': 'Número de Respondentes'}  # Legenda da escala de cores
)

# Etapa 6: Título e rótulos dos eixos
plt.title("Distribuição de Respondentes por Faixa Etária e Gênero", fontsize=14)
plt.xlabel("Gênero")
plt.ylabel("Faixa Etária")

# Etapa 7: Exportação dos arquivos
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/distribuicao_perfis_idade_genero.png", dpi=300, bbox_inches='tight')
tabela_perfis.to_csv("scripts_gerais/ux_tests/distribuicao_perfis_idade_genero.csv")

# Etapa 8: Exibição do gráfico
plt.tight_layout()
plt.show()
