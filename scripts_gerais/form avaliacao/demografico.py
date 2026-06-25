import csv
import matplotlib.pyplot as plt
from collections import Counter
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    rows = list(reader)

alunos  = [r for r in rows if r[5].strip() in ("Aluno", "Ambos")]
coaches = [r for r in rows if r[5].strip() in ("Coach", "Ambos")]

def montar_perfis(grupo):
    perfis = []
    for r in grupo:
        idade  = r[3].strip()
        tempo  = r[2].strip()
        genero = r[4].strip()
        if idade and tempo and genero:
            perfis.append(f"{genero} | {idade} | {tempo}")
    return perfis

perfis_aluno  = montar_perfis(alunos)
perfis_coach  = montar_perfis(coaches)

def plotar_perfis(ax, perfis, titulo, cor):
    contagem = Counter(perfis)
    labels   = list(contagem.keys())
    valores  = list(contagem.values())
    # ordenar por frequência decrescente
    pares    = sorted(zip(valores, labels), reverse=True)
    valores  = [v for v, _ in pares]
    labels   = [l for _, l in pares]

    bars = ax.barh(labels, valores, color=cor, edgecolor="white", height=0.5)
    ax.set_title(titulo, fontsize=18, fontweight="bold", pad=8)
    ax.set_xlabel("Número de respondentes", fontsize=12)
    ax.set_xlim(0, max(valores) + 1.5)
    ax.tick_params(axis="y", labelsize=15)
    ax.tick_params(axis="x", labelsize=15)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    for bar, val in zip(bars, valores):
        ax.text(bar.get_width() + 0.05,
                bar.get_y() + bar.get_height() / 2,
                str(val), va="center", ha="left",
                fontsize=10, fontweight="bold")

n_alunos  = len(alunos)
n_coaches = len(coaches)

fig, axes = plt.subplots(2, 1, figsize=(13, 8))
fig.suptitle("Perfis demográficos dos respondentes — MOTIVA\n(Gênero | Faixa etária | Tempo de prática)",
             fontsize=13, fontweight="bold", y=0.98)

plotar_perfis(axes[0], perfis_aluno,
              f"Alunos (n={n_alunos})", "#2C7BB6")
plotar_perfis(axes[1], perfis_coach,
              f"Coaches (n={n_coaches})", "#F4A442")

plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.90)
output_path = os.path.join(BASE_DIR, "script1_demografico.png")
plt.savefig(output_path, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {output_path}")