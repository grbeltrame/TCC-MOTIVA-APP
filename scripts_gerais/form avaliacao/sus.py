import csv
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    rows = list(reader)

ESCALA = {
    "Discordo Fortemente": 1,
    "Discordo": 2,
    "Neutro": 3,
    "Concordo": 4,
    "Concordo Fortemente": 5,
}

def calcular_sus(respostas):
    vals = [ESCALA.get(r, None) for r in respostas]
    if any(v is None for v in vals):
        return None
    score = 0
    for i, v in enumerate(vals):
        if (i + 1) % 2 == 1:  # ímpares: positivas
            score += v - 1
        else:                  # pares: negativas
            score += 5 - v
    return score * 2.5

def classificar(score):
    if score is None:
        return "—"
    if score >= 90:
        return "Excepcional"
    if score >= 81:
        return "Excelente"
    if score >= 68:
        return "Bom"
    if score >= 50:
        return "Ruim"
    return "Inaceitável"

resultados = []
for r in rows:
    perfil     = r[5].strip()
    genero     = r[4].strip()
    idade      = r[3].strip()
    tempo      = r[2].strip()
    respostas  = [r[j].strip() for j in range(6, 16)]
    score      = calcular_sus(respostas)
    persona    = f"{genero} | {idade} | {tempo}"
    resultados.append({
        "perfil":   perfil,
        "persona":  persona,
        "score":    score,
        "classe":   classificar(score),
    })

alunos  = [x for x in resultados if x["perfil"] in ("Aluno", "Ambos")]
coaches = [x for x in resultados if x["perfil"] in ("Coach", "Ambos")]

def media(grupo):
    scores = [x["score"] for x in grupo if x["score"] is not None]
    return sum(scores) / len(scores) if scores else None

media_alunos  = media(alunos)
media_coaches = media(coaches)
media_geral   = media(resultados)

# Faixas de classificação
faixas = [
    (0,  50,  "#FFCCCC", "Inaceitável (<50)"),
    (50, 68,  "#FFE8CC", "Ruim (50–67)"),
    (68, 81,  "#FFFACC", "Bom (68–80)"),
    (81, 90,  "#CCEECC", "Excelente (81–90)"),
    (90, 100, "#CCE5FF", "Excepcional (>90)"),
]

COR_ALUNO  = "#2C7BB6"
COR_COACH  = "#F4A442"

fig, ax = plt.subplots(figsize=(11, 7))

# Faixas de fundo
for y0, y1, cor, _ in faixas:
    ax.axhspan(y0, y1, alpha=0.3, color=cor, zorder=0)

# Linhas de fronteira
for limite in [50, 68, 81, 90]:
    ax.axhline(limite, color="gray", linewidth=0.7,
               linestyle="--", alpha=0.6, zorder=1)

# Pontos individuais — alunos com jitter leve
import random
random.seed(42)
x_alunos  = [1 + random.uniform(-0.08, 0.08) for _ in alunos]
x_coaches = [2 + random.uniform(-0.08, 0.08) for _ in coaches]

for x, item in zip(x_alunos, alunos):
    ax.scatter(x, item["score"], color=COR_ALUNO, s=80, zorder=3,
               edgecolors="white", linewidths=0.8)

for x, item in zip(x_coaches, coaches):
    ax.scatter(x, item["score"], color=COR_COACH, s=80, zorder=3,
               edgecolors="white", linewidths=0.8)

# Médias
if media_alunos is not None:
    ax.hlines(media_alunos, 0.7, 1.3, colors=COR_ALUNO,
              linewidths=2.5, zorder=4)
    ax.text(1.35, media_alunos, f"{media_alunos:.1f}",
            va="center", fontsize=9, color=COR_ALUNO, fontweight="bold")

if media_coaches is not None:
    ax.hlines(media_coaches, 1.7, 2.3, colors=COR_COACH,
              linewidths=2.5, zorder=4)
    ax.text(2.35, media_coaches, f"{media_coaches:.1f}",
            va="center", fontsize=9, color=COR_COACH, fontweight="bold")

# Labels faixas no lado direito
for y0, y1, _, label in faixas:
    ax.text(2.65, (y0 + y1) / 2, label,
            va="center", fontsize=8, color="gray")

ax.set_xticks([1, 2])
ax.set_xticklabels([f"Alunos\n(n={len(alunos)})",
                    f"Coaches\n(n={len(coaches)})"], fontsize=11)
ax.set_xlim(0.4, 3.1)
ax.set_ylim(0, 105)
ax.set_ylabel("Score SUS", fontsize=10)
ax.set_title(f"System Usability Scale (SUS) — MOTIVA\nMédia geral: {media_geral:.1f} — {classificar(media_geral)}",
             fontsize=13, fontweight="bold", pad=10)
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

patch_aluno  = mpatches.Patch(color=COR_ALUNO,  label=f"Aluno — média {media_alunos:.1f} ({classificar(media_alunos)})")
patch_coach  = mpatches.Patch(color=COR_COACH,  label=f"Coach — média {media_coaches:.1f} ({classificar(media_coaches)})")
ax.legend(handles=[patch_aluno, patch_coach], fontsize=9,
          loc="lower left", framealpha=0.8)

plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.90)
output_path = os.path.join(BASE_DIR, "script3_sus.png")
plt.savefig(output_path, dpi=150, bbox_inches="tight")
plt.show()

# Print tabela para verificação manual
print(f"\n{'Respondente':<5} {'Perfil':<8} {'Score':>7} {'Classificação'}")
print("-" * 45)
for i, x in enumerate(resultados):
    print(f"R{i+1:<4} {x['perfil']:<8} {x['score']:>7.1f}   {x['classe']}")
print(f"\nMédia alunos:  {media_alunos:.1f} — {classificar(media_alunos)}")
print(f"Média coaches: {media_coaches:.1f} — {classificar(media_coaches)}")
print(f"Média geral:   {media_geral:.1f} — {classificar(media_geral)}")
print(f"\nSalvo: {output_path}")