# Importação das bibliotecas necessárias
import pandas as pd               # Para leitura e manipulação dos dados da planilha
import matplotlib.pyplot as plt   # Para visualização gráfica
import seaborn as sns             # Para gráficos com uma estética mais amigável
import os                         # Para garantir que a pasta onde o gráfico será salvo exista

# Etapa 1: Leitura do arquivo CSV com os dados coletados no Google Forms
# O arquivo deve estar salvo na pasta scripts_gerais
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Etapa 2: Nome das colunas exatas do formulário que serão combinadas
coluna_idade = "Qual sua faixa de idade?"
coluna_tempo = "Há quanto tempo você treina crossfit?"
coluna_genero = "Qual seu gênero"
coluna_categoria = "Com qual dessas opções você se identifica?"

# Etapa 3: Remoção de linhas com qualquer valor ausente (NaN) nessas colunas
# Isso garante que só vamos criar perfis com todas as informações completas
df_filtrado = df[[coluna_idade, coluna_tempo, coluna_genero, coluna_categoria]].dropna()

# Etapa 4: Criação da nova coluna "Perfil Completo"
# Essa coluna junta todas as informações demográficas do usuário em um único identificador
df_filtrado["Perfil Completo"] = (
    df_filtrado[coluna_idade].astype(str) + " | " +
    df_filtrado[coluna_tempo].astype(str) + " | " +
    df_filtrado[coluna_genero].astype(str) + " | " +
    df_filtrado[coluna_categoria].astype(str)
)

# Etapa 5: Contagem de quantas vezes cada perfil apareceu nas respostas
contagem_perfis = df_filtrado["Perfil Completo"].value_counts().reset_index()
contagem_perfis.columns = ["Perfil Completo", "Número de Respondentes"]

# Etapa 6: Criação do gráfico com os 10 perfis mais frequentes
top_10_perfis = contagem_perfis.head(10)

# Define o tamanho da imagem e a paleta de cores
plt.figure(figsize=(12, 8))
sns.barplot(
    y="Perfil Completo",
    x="Número de Respondentes",
    data=top_10_perfis,
    palette="Blues_d"
)

# Título do gráfico e rótulos dos eixos
plt.title("Top 10 Perfis Combinados de Respondentes", fontsize=14)
plt.xlabel("Número de Respondentes")
plt.ylabel("Perfil (Idade | Tempo | Gênero | Categoria)")

# Ajuste visual para que tudo apareça corretamente
plt.tight_layout()

# Etapa 7: Salva o gráfico e a planilha com os dados de perfis
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/perfis_combinados_top10.png", dpi=300, bbox_inches='tight')
contagem_perfis.to_csv("scripts_gerais/ux_tests/perfis_combinados.csv", index=False)

# Etapa 8: Exibe o gráfico na tela
plt.show()
