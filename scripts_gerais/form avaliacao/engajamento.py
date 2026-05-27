import csv
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from collections import Counter, defaultdict
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    rows = list(reader)

def extrair(rows, col_eng_individual, col_eng_ambos, perfis_validos):
    dados = []
    for r in rows:
        perfil = r[5].strip()
        if perfil not in perfis_validos:
            continue
        idade  = r[3].strip()
        tempo  = r[2].strip()
        genero = r[4].strip()
        eng    = r[col_eng_individual].strip() if perfil != "Ambos" else r[col_eng_ambos].strip()
        if idade and tempo and genero and eng:
            dados.append((f"{genero} | {idade} | {tempo}", eng))
    return dados

dados_alunos  = extrair(rows, 17, 47, {"Aluno", "Ambos"})
dados_coaches = extrair(rows, 31, 48, {"Coach", "Ambos"})

ordem_faixas = ["1 a 3", "4 a 7", "8 a 14", "15 ou mais"]

CORES_ALUNO  = {"1 a 3": "#ABD9E9", "4 a 7": "#2C7BB6", "8 a 14": "#1A5A8A", "15 ou mais": "#0D3050"}
CORES_COACH  = {"1 a 3": "#FDDAA0", "4 a 7": "#F4A442", "8 a 14": "#C97A1A", "15 ou mais": "#7A4A00"}

def plotar_engajamento(ax, dados, titulo, cores, label_x):
    # Agrupar: persona -> {faixa: contagem}
    agrup = defaultdict(Counter)
    for persona, eng in dados:
        agrup[persona][eng] += 1

    personas = list(dict.fromkeys([p for p, _ in dados]))
    faixas_presentes = [f for f in ordem_faixas
                        if any(agrup[p][f] > 0 for p in personas)]

    n_faixas  = len(faixas_presentes)
    bar_h     = 0.6 / max(n_faixas, 1)
    y_pos     = range(len(personas))

    for i, faixa in enumerate(faixas_presentes):
        valores = [agrup[p][faixa] for p in personas]
        offset  = (i - n_faixas / 2 + 0.5) * bar_h
        bars = ax.barh([y + offset for y in y_pos], valores,
                       height=bar_h * 0.85,
                       color=cores.get(faixa, "#999"),
                       edgecolor="white", label=faixa)
        for bar, val in zip(bars, valores):
            if val > 0:
                ax.text(bar.get_width() + 0.05,
                        bar.get_y() + bar.get_height() / 2,
                        str(val), va="center", ha="left", fontsize=9)

    max_val = max(agrup[p][f] for p in personas for f in faixas_presentes) if personas else 1
    ax.set_xlim(0, max_val + 1)
    ax.set_yticks(list(y_pos))
    ax.set_yticklabels(personas, fontsize=9)
    ax.set_xlabel(label_x, fontsize=9)
    ax.set_title(titulo, fontsize=11, fontweight="bold", pad=8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.legend(title="Faixa de registros", fontsize=8,
              title_fontsize=8, loc="lower right")
    ax.xaxis.set_major_locator(plt.MaxNLocator(integer=True))

fig, axes = plt.subplots(2, 1, figsize=(13, 7))
fig.suptitle("Engajamento por persona — MOTIVA\n(Gênero | Faixa etária | Tempo de prática)",
             fontsize=13, fontweight="bold", y=0.98)

plotar_engajamento(axes[0], dados_alunos,
                   f"Registros de resultado — Alunos (n={len(dados_alunos)})",
                   CORES_ALUNO, "Número de respondentes")
plotar_engajamento(axes[1], dados_coaches,
                   f"Treinos publicados — Coaches (n={len(dados_coaches)})",
                   CORES_COACH, "Número de respondentes")

plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.88, hspace=0.5, left=0.25, right=0.92, bottom=0.08)
output_path = os.path.join(BASE_DIR, "script2_engajamento.png")
plt.savefig(output_path, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {output_path}")