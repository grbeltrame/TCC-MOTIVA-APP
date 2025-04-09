# Com essa analise estamos buscando perfis levando em conta idade e tempo de pratica no esporte.
# Queremos entender os perfis que temos para avaliar de forma mais efetiva a percepção de valor
# das funcionlaidades do app considerando maturidade fisica e experiencia, e avaliar se temos muita
# discrepancia ou mais concordancia entre diferentes perfis.

# Importo as bibliotecas necessárias
import pandas as pd               # Para leitura e manipulação dos dados
import seaborn as sns             # Para criar o gráfico de calor (heatmap)
import matplotlib.pyplot as plt   # Para plotar o gráfico
import os                         # Para garantir que a pasta de saída exista

# Defino o caminho para o arquivo CSV com as respostas do formulário
arquivo = "scripts_gerais/respostas_formulario.csv"

# Leio o CSV e converto para um DataFrame para facilitar a análise
df = pd.read_csv(arquivo)

# Nome exato das colunas do formulário relacionadas a faixa etária e tempo de prática
coluna_idade = 'Qual sua faixa de idade?'
coluna_tempo = 'Há quanto tempo você treina crossfit?'


# Garantindo que não haja valores ausentes (NaN) nas colunas usadas.
df = df.dropna(subset=[coluna_idade, coluna_tempo])


# Crio uma tabela de contingência com as combinações entre faixa etária e tempo de prática
# Cada célula da tabela representa o número de pessoas com aquele perfil específico
tabela_perfis = pd.crosstab(df[coluna_idade], df[coluna_tempo])

# Exibo a tabela no terminal apenas para conferência
print("Distribuição dos perfis por idade e tempo de prática:")
print(tabela_perfis)

# Crio o gráfico de calor para facilitar a visualização da densidade de respostas
plt.figure(figsize=(10, 6))  # Define o tamanho da figura
sns.heatmap(tabela_perfis, annot=True, fmt="d", cmap="Blues")  # annot=True mostra os números nas células
plt.title("Distribuição de Respondentes por Faixa Etária e Tempo de Prática")
plt.xlabel("Tempo de Prática")
plt.ylabel("Faixa Etária")

# Garante que a pasta onde o gráfico será salvo exista
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)

# Salva o gráfico com alta resolução
plt.savefig("scripts_gerais/ux_tests/distribuicao_perfis_idade_tempo.png", dpi=300, bbox_inches='tight')

# Mostra o gráfico na tela
plt.show()
