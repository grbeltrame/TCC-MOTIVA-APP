# Análise visual da média das respostas de um questionário com escala de Likert
# Esse gráfico vai ser usado no TCC para entender o que os usuários mais valorizam no app

import pandas as pd
import matplotlib.pyplot as plt
import textwrap  # Biblioteca que me ajuda a quebrar texto em várias linhas

# Aqui eu defino o caminho do arquivo CSV com as respostas coletadas no formulário
# Eu exportei do Google Forms e salvei dentro da pasta scripts_gerais
arquivo = "scripts_gerais/respostas_formulario.csv"

# Leio o arquivo com pandas e transformo em um DataFrame para facilitar a manipulação
df = pd.read_csv(arquivo)

# Lista com todas as 20 afirmações do questionário.
# As colunas do CSV têm exatamente esses nomes, por isso eu uso os textos completos.
# Isso também garante que no gráfico apareça a frase que o usuário realmente leu.
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

# Garantindo que não haja valores ausentes (NaN) nas colunas usadas.
df = df.dropna(subset=colunas_likert)


# Aqui eu calculo a média de todas as respostas para cada afirmação
# O resultado será um ranking com valores entre 1 (discordo fortemente) e 5 (concordo fortemente)
medias = df[colunas_likert].mean()

# Eu ordeno da menor média para a maior para facilitar a visualização no gráfico
# Assim vejo facilmente o que foi menos e mais valorizado
medias_ordenadas = medias.sort_values(ascending=True)

# Como as frases são grandes, uso o textwrap para quebrar cada frase em até 45 caracteres por linha
# Isso melhora muito a legibilidade no gráfico
rotulos_quebrados = [
    textwrap.fill(texto, width=65, break_long_words=False) for texto in medias_ordenadas.index
]

# Começo a configurar o gráfico com matplotlib
plt.figure(figsize=(11, 10))  # Define o tamanho da imagem

# Crio um gráfico de barras horizontais com a cor azul da identidade visual do app
# Define altura menor para cada barra pra dar mais respiro (padrão é 0.8)
barras = plt.barh(rotulos_quebrados, medias_ordenadas, color="#0E3ACC", height=0.5)

# Coloco o valor da média ao lado de cada barra para o leitor não precisar adivinhar
for barra, media in zip(barras, medias_ordenadas):
    plt.text(media + 0.03,  # Deslocamento horizontal do texto
             barra.get_y() + barra.get_height() / 2,  # Centraliza verticalmente
             f"{media:.2f}",  # Mostra a média com 2 casas decimais
             va='center', fontsize=9)

# Adiciono título e legendas com fontes maiores
plt.title("Média de Concordância das Hipóteses (Escala de Likert)", fontsize=14)
plt.xlabel("Média das Respostas (1 = Discordo Fortemente | 5 = Concordo Fortemente)", fontsize=11)
plt.ylabel("Afirmações", fontsize=11)

# Mostro os valores de 1 a 5 no eixo X, pois é o intervalo da Escala de Likert
plt.xticks([1, 2, 3, 4, 5])

# Coloco uma grade sutil no fundo pra facilitar leitura visual
plt.grid(axis='x', linestyle='--', alpha=0.3)

# Organiza para não cortar nenhum elemento do gráfico
plt.tight_layout()

# Salvo a imagem em alta qualidade para colocar na monografia
plt.savefig("scripts_gerais/grafico_likert.png", dpi=300)

# Mostra o gráfico na tela
plt.show()

# ---------------------- GRÁFICO DE BARRAS EMPILHADAS COM TODAS AS PORCENTAGENS ----------------------

# Crio um DataFrame apenas com as colunas de Likert
df_likert = df[colunas_likert]

# Removo respostas incompletas
df_likert = df_likert.dropna(how='any')

# Calcula a distribuição percentual de cada nota (1 a 5) por hipótese
frequencias = df_likert.apply(lambda col: col.value_counts(normalize=True).reindex([1,2,3,4,5], fill_value=0) * 100)

# Transponho para que cada linha seja uma hipótese, e colunas sejam as notas 1-5
frequencias = frequencias.T

# Preparo rótulos quebrados para melhorar legibilidade
rotulos_quebrados = [
    textwrap.fill(texto, width=65, break_long_words=False) for texto in frequencias.index
]

# Configurações do gráfico
plt.figure(figsize=(11, 12))
cores = ['#E74C3C', '#F39C12', '#F1C40F', '#2ECC71', '#27AE60']  # Vermelho → Verde
valores_acumulados = [0] * len(frequencias)

# Criação das barras empilhadas
for i, nota in enumerate([1, 2, 3, 4, 5]):
    barras = plt.barh(
        y=range(len(frequencias)),
        width=frequencias[nota],
        left=valores_acumulados,
        label=f"{nota} - {['Discordo Fortemente','Discordo','Neutro','Concordo','Concordo Fortemente'][i]}",
        color=cores[i]
    )
    
    # Mostra a % dentro de todas as barras (independente do tamanho)
    for j, bar in enumerate(barras):
        valor = frequencias.iloc[j, i]
        if valor > 0:
            plt.text(
                x=valores_acumulados[j] + valor / 2,
                y=j,
                s=f"{valor:.0f}%",
                va='center',
                ha='center',
                fontsize=8,
                color='white'
            )
    
    # Atualiza os valores acumulados para empilhar corretamente
    valores_acumulados = [a + b for a, b in zip(valores_acumulados, frequencias[nota])]

# Eixos e título
plt.yticks(range(len(rotulos_quebrados)), rotulos_quebrados, fontsize=8)
plt.xlabel("Porcentagem das Respostas")
plt.title("Distribuição Percentual das Respostas (Escala de Likert)", fontsize=14)
plt.legend(title="Nota", loc='lower right')
plt.xlim(0, 100)
plt.tight_layout(rect=[0, 0, 1, 0.98])

# Salva o gráfico novo
plt.savefig("scripts_gerais/grafico_likert_percentual.png", dpi=300, bbox_inches='tight')
plt.show()
