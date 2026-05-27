import csv, re
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    headers = next(reader)
    rows = list(reader)

ESCALA_NUM = {
    "Discordo Fortemente": 1,
    "Discordo":            2,
    "Neutro":              3,
    "Concordo":            4,
    "Concordo Fortemente": 5,
}

FAIXA_CENTRO = {
    "1 a 3":      2,
    "4 a 7":      5.5,
    "8 a 14":     11,
    "15 ou mais": 17,
}

COLS_ALUNO_A     = list(range(18, 29))
COLS_AMBOS_ALUNO = list(range(61, 72))
COLS_COACH_B     = list(range(32, 44))
COLS_AMBOS_COACH = list(range(49, 61))

def media_likert(r, cols_primario, cols_ambos):
    vals = []
    for c, ca in zip(cols_primario, cols_ambos):
        v = r[c].strip() if r[c].strip() else r[ca].strip()
        n = ESCALA_NUM.get(v)
        if n is not None:
            vals.append(n)
    return np.mean(vals) if vals else None

def persona_str(r):
    return f"{r[4].strip()} | {r[3].strip()} | {r[2].strip()}"

# Montar dados por perfil
dados_alunos  = []
dados_coaches = []

for r in rows:
    perfil  = r[5].strip()
    persona = persona_str(r)

    if perfil in ("Aluno", "Ambos"):
        eng_raw = r[17].strip() if perfil == "Aluno" else r[47].strip()
        media   = media_likert(r, COLS_ALUNO_A, COLS_AMBOS_ALUNO)
        if eng_raw and media is not None:
            dados_alunos.append({
                "persona": persona,
                "eng_raw": eng_raw,
                "eng_x":  FAIXA_CENTRO.get(eng_raw, None),
                "media":  media,
                "perfil": perfil,
            })

    if perfil in ("Coach", "Ambos"):
        eng_raw = r[31].strip() if perfil == "Coach" else r[48].strip()
        media   = media_likert(r, COLS_COACH_B, COLS_AMBOS_COACH)
        if eng_raw and media is not None:
            dados_coaches.append({
                "persona": persona,
                "eng_raw": eng_raw,
                "eng_x":  FAIXA_CENTRO.get(eng_raw, None),
                "media":  media,
                "perfil": perfil,
            })

# Terminal — verificação
print("=" * 60)
print("CORRELAÇÃO ENGAJAMENTO × LIKERT — ALUNOS")
print("=" * 60)
for d in dados_alunos:
    print(f"  {d['persona'][:45]:<45} | eng: {d['eng_raw']:<10} | média Likert: {d['media']:.2f}")

print("\n" + "=" * 60)
print("CORRELAÇÃO ENGAJAMENTO × LIKERT — COACHES")
print("=" * 60)
for d in dados_coaches:
    print(f"  {d['persona'][:45]:<45} | eng: {d['eng_raw']:<10} | média Likert: {d['media']:.2f}")

COR_ALUNO = "#2C7BB6"
COR_COACH = "#F4A442"

ORDEM_FAIXAS = ["1 a 3", "4 a 7", "8 a 14", "15 ou mais"]
X_TICKS      = [FAIXA_CENTRO[f] for f in ORDEM_FAIXAS]

def plotar_dispersao(ax, dados, cor, titulo, n):
    import random
    random.seed(42)

    # Linha de tendência se houver pontos suficientes
    xs = [d["eng_x"] for d in dados if d["eng_x"]]
    ys = [d["media"]  for d in dados if d["eng_x"]]


    # Separar pontos com mesmo X para evitar sobreposição
    from collections import defaultdict
    grupos = defaultdict(list)
    for d in dados:
        if d["eng_x"] is not None:
            grupos[d["eng_x"]].append(d)

    for eng_x, grupo in grupos.items():
        n_grupo = len(grupo)
        # Distribuir verticalmente dentro do grupo
        y_offsets = np.linspace(-0.4 * (n_grupo - 1), 0.4 * (n_grupo - 1), n_grupo)
        x_offsets = np.linspace(-1.0, 1.0, n_grupo) if n_grupo > 1 else [0]
        for d, y_off, x_off in zip(grupo, y_offsets, x_offsets):
            px = eng_x + x_off
            py = d["media"] + y_off
            ax.scatter(px, py, color=cor, s=100, zorder=4,
                       edgecolors="white", linewidths=1)
            ax.annotate(d["persona"],
                        xy=(px, py),
                        xytext=(8, 0), textcoords="offset points",
                        fontsize=7, color="#333333",
                        va="center")

    ax.set_xticks(X_TICKS)
    ax.set_xticklabels(ORDEM_FAIXAS, fontsize=9)
    ax.set_xlim(0, 20)
    ax.set_ylim(0.5, 6.5)
    ax.set_yticks([1, 2, 3, 4, 5])
    ax.set_yticklabels(["1\nDiscordo\nFortemente", "2", "3\nNeutro", "4", "5\nConcordo\nFortemente"],
                       fontsize=8)
    ax.set_xlabel("Faixa de engajamento (registros / treinos publicados)", fontsize=9)
    ax.set_ylabel("Média das respostas Likert", fontsize=9)
    ax.set_title(titulo, fontsize=11, fontweight="bold", pad=8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.axhline(3, color="gray", linewidth=0.8, linestyle=":", alpha=0.5)
    ax.xaxis.grid(True, linestyle="--", alpha=0.3)

fig, axes = plt.subplots(1, 2, figsize=(18, 9))
fig.suptitle("Correlação Engajamento × Satisfação (Likert) — MOTIVA",
             fontsize=13, fontweight="bold", y=0.98)

plotar_dispersao(axes[0], dados_alunos,  COR_ALUNO,
                 f"Alunos (n={len(dados_alunos)})", len(dados_alunos))
plotar_dispersao(axes[1], dados_coaches, COR_COACH,
                 f"Coaches (n={len(dados_coaches)})", len(dados_coaches))

plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.90, left=0.08, right=0.97, bottom=0.12)
output_path = os.path.join(BASE_DIR, "script7_correlacao.png")
plt.savefig(output_path, dpi=150, bbox_inches="tight")
plt.show()
print(f"\nSalvo: {output_path}")