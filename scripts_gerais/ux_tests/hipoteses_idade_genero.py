# Importação das bibliotecas
import pandas as pd
import os
import matplotlib.pyplot as plt
import seaborn as sns
import textwrap

# Caminho para o arquivo com os dados
arquivo = "scripts_gerais/respostas_formulario.csv"

# Lê o CSV com as respostas do Google Forms
df = pd.read_csv(arquivo)

# Lista com as 20 hipóteses avaliadas pelos usuários (escala de Likert de 1 a 5)
colunas_likert = [
    "Eu desejo uma forma prática e rápida de interagir com pessoas fora do meu box.",
    "Os aplicativos atualmente usados não atendem à minha necessidade de sociabilidade.",
    "Comparar meu desempenho com pessoas de perfil físico semelhante (idade, gênero, peso, comorbidades etc.) é interessante para mim.",
    "Ter a opção de cadastrar meu desempenho no esporte e deixá-lo público é algo que me atrai.",
    "Rankings de atletas por WOD e de WODs mais curtidos/concluídos tornam a minha experiência no aplicativo mais interessante.",
    "Um feed com postagens de WODs, conteúdos, espaço para comentar e acompanhar outros atletas é algo que me interessa.",
    "Eu valorizo selos e conquistas virtuais como forma de reconhecimento pelo meu esforço.",
    "Eu considero que meus coaches têm dificuldade em montar WODs equilibrados.",
    "Eu me sinto desmotivado com WODs mal estruturados.",
    "Avaliar minha evolução física e esportiva dentro de um aplicativo é algo que considero importante.",
    "A possibilidade de ter meu desempenho avaliado por profissionais dentro da plataforma é algo positivo para mim",
    "Receber sugestões automáticas de WODs com base no meu perfil/histórico me interessa.",
    "Ter uma análise visual da minha evolução (gráficos, comparações, registros) me motiva a usar o aplicativo com mais frequência.",
    "Eu considero que centralizar a comunicação entre atletas e organizadores de campeonatos no aplicativo é algo importante.",
    "Acompanhar campeonatos externos ao meu box, com transmissões ao vivo e leaderboards, é algo que me interessa.",
    "Ter uma agenda de eventos futuros (com lembretes) é útil para mim.",
    "Permitir envio de vídeos para qualificação em campeonatos (Open, Monstar, TCB e outros) é uma funcionalidade relevante para mim.",
    "Uma loja com produtos relacionados ao esporte (roupas, equipamentos, suplementos etc.) dentro do aplicativo me interessa.",
    "Eu gostaria de ter acesso a condições especiais com marcas parceiras dentro do aplicativo.",
    "Ter acesso a serviços de profissionais como nutricionistas e fisioterapeutas dentro do aplicativo me interessa."
]

# Remove linhas incompletas com valores nulos nas colunas que usaremos
df = df.dropna(subset=["Qual seu gênero", "Há quanto tempo você treina crossfit?"] + colunas_likert)

# Cria uma nova coluna combinando Gênero + Tempo de prática
df["Perfil Genero x Idade"] = (
    df["Qual seu gênero"].astype(str) + " | " +
    df["Qual sua faixa de idade?"].astype(str)
)

# Conta o número de respondentes por perfil
contagem_perfis = df["Perfil Genero x Idade"].value_counts()

# Filtra apenas os perfis com 11 ou mais respondentes
perfis_filtrados = contagem_perfis[contagem_perfis >= 7].index.tolist()

# Filtra o DataFrame com apenas os perfis de interesse
df_filtrado = df[df["Perfil Genero x Idade"].isin(perfis_filtrados)]

# Agrupa os dados e calcula a média das hipóteses
medias_por_perfil = df_filtrado.groupby("Perfil Genero x Idade")[colunas_likert].mean()

# Cria uma estrutura para guardar os resultados em formato plano
dados_filtrados = []

# Para cada perfil, verifica a media das hipoteses
for perfil, linha in medias_por_perfil.iterrows():
    for hipotese, media in linha.items():
        dados_filtrados.append({
            "Perfil": perfil,
            "Hipótese": hipotese,
            "Média da Nota": round(media, 2)
        })

# Converte para DataFrame
resultado = pd.DataFrame(dados_filtrados)

# Garante que a pasta de saída exista
os.makedirs("scripts_gerais/ux_tests", exist_ok=True)

# Salva o resultado em um CSV para análise posterior ou uso no TCC
resultado.to_csv("scripts_gerais/ux_tests/hipoteses_por_genero_idade.csv", index=False)

# Exibe um preview no terminal
print("Análise concluída. Hipóteses mais bem avaliadas por perfil:")
print(resultado.head(10))


# ---------------------- GERAÇÃO DO GRÁFICO (HEATMAP) ----------------------

# Transforma o DataFrame no formato adequado: linhas = hipóteses, colunas = perfis
tabela = resultado.pivot(index="Hipótese", columns="Perfil", values="Média da Nota")

# Ordena as hipóteses da mais valorizada para a menos valorizada (média geral)
ordem_hipoteses = tabela.mean(axis=1).sort_values(ascending=False).index
tabela = tabela.reindex(ordem_hipoteses)

# Quebra o texto das hipóteses para melhorar a leitura
tabela.index = [textwrap.fill(h, width=60) for h in tabela.index]

# Define o tamanho da imagem baseado no número de perfis
altura = max(10, 0.5 * len(tabela))
largura = max(12, 0.5 * len(tabela.columns))

# Cria o heatmap
plt.figure(figsize=(largura, altura))
sns.set(font_scale=0.6)
sns.heatmap(
    tabela,
    annot=True,
    fmt=".2f",
    cmap="BuPu",
    linewidths=0.5,
    linecolor='gray',
    cbar_kws={"label": "Média da Nota"}
)

# Título e eixos
plt.title("Média das Respostas por Hipótese\n(Perfis com ≥ 11 respondentes | Gênero + Idade)", fontsize=13, pad=20)
plt.xlabel("Perfil (Gênero + Idade)")
plt.ylabel("Hipóteses (Escala de Likert)")

# Ajustes finais
plt.tight_layout()

# Salva o gráfico
plt.savefig("scripts_gerais/ux_tests/heatmap_hipoteses_genero_idade.png", dpi=300, bbox_inches='tight')

# Exibe o gráfico na tela
plt.show()
