# Importação das bibliotecas
import pandas as pd               # Usado para carregar e manipular os dados da planilha
import matplotlib.pyplot as plt   # Usado para gerar o gráfico
import os                         # Usado para verificar/criar a pasta onde o gráfico será salvo


# Etapa 1: Aqui eu defino o caminho do arquivo CSV com as respostas coletadas no formulário
# Eu exportei do Google Forms e salvei dentro da pasta scripts_gerais
arquivo = "scripts_gerais/respostas_formulario.csv"

# Leio o arquivo com pandas e transformo em um DataFrame para facilitar a manipulação
df = pd.read_csv(arquivo)

# Etapa 2: Defino o nome da coluna que armazena o tipo de usuário (Aluno, Coach ou Ambos)
coluna_cargo = "Com qual dessas opções você se identifica?"

# Etapa 3: Defino as hipóteses prioritárias (com média ≥ 3.67 na análise geral)
hipoteses_prioritarias = [
    "Comparar meu desempenho com pessoas de perfil físico semelhante (idade, gênero, peso, comorbidades etc.) é interessante para mim.",
    "Um feed com postagens de WODs, conteúdos, espaço para comentar e acompanhar outros atletas é algo que me interessa.",
    "Eu me sinto desmotivado com WODs mal estruturados.",
    "Avaliar minha evolução física e esportiva dentro de um aplicativo é algo que considero importante.",
    "A possibilidade de ter meu desempenho avaliado por profissionais dentro da plataforma é algo positivo para mim",
    "Receber sugestões automáticas de WODs com base no meu perfil/histórico me interessa.",
    "Ter uma análise visual da minha evolução (gráficos, comparações, registros) me motiva a usar o aplicativo com mais frequência.",
    "Eu considero que centralizar a comunicação entre atletas e organizadores de campeonatos no aplicativo é algo importante.",
    "Acompanhar campeonatos externos ao meu box, com transmissões ao vivo e leaderboards, é algo que me interessa.",
    "Ter uma agenda de eventos futuros (com lembretes) é útil para mim.",
    "Uma loja com produtos relacionados ao esporte (roupas, equipamentos, suplementos etc.) dentro do aplicativo me interessa.",
    "Eu gostaria de ter acesso a condições especiais com marcas parceiras dentro do aplicativo.",
    "Ter acesso a serviços de profissionais como nutricionistas e fisioterapeutas dentro do aplicativo me interessa."
]

# Garantindo que não haja valores ausentes (NaN) nas colunas usadas.
df = df.dropna(subset=[coluna_cargo] + hipoteses_prioritarias)

# Etapa 4: Crio um novo DataFrame contendo apenas a coluna de cargo e as hipóteses
df_filtrado = df[[coluna_cargo] + hipoteses_prioritarias]

# Etapa 5: Agrupo os dados por cargo (Aluno, Coach, Ambos) e calculo a média de cada hipótese
medias_por_grupo = df_filtrado.groupby(coluna_cargo).mean()

# Etapa 6: Transpõe o DataFrame para facilitar a visualização (cada linha é uma hipótese)
medias_transposta = medias_por_grupo.T

# Etapa 7: Criação do gráfico
plt.figure(figsize=(14, 10))  # Define o tamanho do gráfico

# Cores baseadas na identidade visual do projeto
cores = ['#0E3ACC', '#CC0E43', '#7E57C2']  # Azul, Magenta, Roxo
largura = 0.2                              # Largura das barras
indices = range(len(medias_transposta.index))  # Posições no eixo Y

# Crio as barras horizontais para cada grupo (Aluno, Coach, Ambos)
for i, col in enumerate(medias_transposta.columns):
    plt.barh(
        [idx + (i - 1) * largura for idx in indices],  # Posição ajustada no eixo Y
        medias_transposta[col],                        # Valores de média
        height=largura,
        label=col,
        color=cores[i]
    )
    # Adiciona os valores das médias ao lado das barras
    for j, valor in enumerate(medias_transposta[col]):
        plt.text(valor + 0.05, j + (i - 1) * largura, f"{valor:.2f}", va='center', fontsize=9)

# Etapa 8: Configurações finais do gráfico
plt.yticks(indices, medias_transposta.index, fontsize=9)
plt.xlabel("Média das Respostas (1 a 5)")
# Título dividido em duas linhas para melhor legibilidade
plt.title("Comparação entre Alunos, Coaches e Ambos\nnas Hipóteses com Média ≥ 3.67", fontsize=14)
plt.legend()
plt.xlim(1, 5)
# Ajuste do layout para que o título e elementos não sejam cortados
plt.tight_layout(rect=[0, 0, 1, 0.97])  # Reserva 3% da altura superior para o título

# Etapa 9: Salva o gráfico na pasta scripts_gerais
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
# Salva a imagem com bordas ajustadas para não cortar a legenda nem os textos da direita
plt.savefig("scripts_gerais/ux_tests/hipoteses_aluno_vs_coach_3grupos.png", dpi=300, bbox_inches='tight')
plt.show()