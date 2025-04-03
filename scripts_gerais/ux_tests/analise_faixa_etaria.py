# Importação das bibliotecas
import pandas as pd               # Usado para carregar e manipular os dados da planilha
import matplotlib.pyplot as plt   # Usado para gerar o gráfico
import os                         # Usado para verificar/criar a pasta onde o gráfico será salvo

# Etapa 1: Leitura do arquivo
arquivo = "scripts_gerais/respostas_formulario.csv"
df = pd.read_csv(arquivo)

# Etapa 2: Coluna de faixa etária usada no formulário
coluna_idade = "Qual sua faixa de idade?"

# Etapa 3: Hipóteses prioritárias com média geral ≥ 3.67
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

# Etapa 4: Ordem personalizada das faixas etárias
ordem_idades = [
    "Menos de 20 anos",
    "Entre 20 e 30 anos",
    "Entre 30 e 40 anos",
    "Entre 40 e 50 anos",
    "Mais de 50 anos"
]

# Etapa 5: Agrupamento por faixa etária e cálculo da média das respostas
medias_por_idade = df.groupby(coluna_idade)[hipoteses_prioritarias].mean()
medias_por_idade = medias_por_idade.reindex(ordem_idades)

# Etapa 6: Transposição da tabela para facilitar o gráfico
medias_transposta = medias_por_idade.T

# Etapa 7: Criação do gráfico
plt.figure(figsize=(14, 10))  # Tamanho da figura
cores = ['#0E3ACC', '#CC0E43', '#7E57C2', '#1ABC9C', '#F39C12']  # Azul, magenta, roxo, verde e laranja
largura = 0.13
indices = range(len(medias_transposta.index))

# Geração das barras para cada faixa etária
for i, col in enumerate(medias_transposta.columns):
    plt.barh(
        [idx + (i - 2) * largura for idx in indices],
        medias_transposta[col],
        height=largura,
        label=col,
        color=cores[i]
    )
    for j, valor in enumerate(medias_transposta[col]):
        plt.text(
            valor + 0.05,
            j + (i - 2) * largura,
            f"{valor:.2f}",
            va='center',
            fontsize=9
        )

# Etapa 8: Configurações visuais
plt.yticks(indices, medias_transposta.index, fontsize=9)
plt.xlabel("Média das Respostas (1 a 5)")
plt.title("Comparação entre Faixas Etárias\nnas Hipóteses com Média ≥ 3.67", fontsize=14)
plt.legend()
plt.xlim(1, 5)
plt.tight_layout(rect=[0, 0, 1, 0.97])  # Espaço extra para o título

# Etapa 9: Exportação
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)
plt.savefig("scripts_gerais/ux_tests/hipoteses_por_faixa_etaria.png", dpi=300, bbox_inches='tight')
plt.show()
