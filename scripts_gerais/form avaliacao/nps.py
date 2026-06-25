import csv
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os, random

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    rows = list(reader)

dados = []
for r in rows:
    perfil = r[5].strip()
    nps    = r[76].strip()
    genero = r[4].strip()
    idade  = r[3].strip()
    tempo  = r[2].strip()
    if nps:
        nota = int(nps)
        if nota <= 6:
            classe = "Detrator"
        elif nota <= 8:
            classe = "Neutro"
        else:
            classe = "Promotor"
        persona = f"{genero} | {idade} | {tempo}"
        dados.append({"perfil": perfil, "nota": nota,
                      "classe": classe, "persona": persona})

notas      = [d["nota"] for d in dados]
n_total    = len(notas)
n_promotor = sum(1 for d in dados if d["classe"] == "Promotor")
n_neutro   = sum(1 for d in dados if d["classe"] == "Neutro")
n_detrator = sum(1 for d in dados if d["classe"] == "Detrator")
pct_prom   = n_promotor / n_total * 100
pct_detr   = n_detrator / n_total * 100
score_nps  = pct_prom - pct_detr

print("=" * 50)
print("NPS — VERIFICAÇÃO MANUAL")
print("=" * 50)
for i, d in enumerate(dados):
    print(f"  R{i+1} | {d['perfil']:<8} | nota: {d['nota']:>2} | {d['classe']} | {d['persona']}")
print(f"\n  Promotores:  {n_promotor} ({pct_prom:.1f}%)")
print(f"  Neutros:     {n_neutro}")
print(f"  Detratores:  {n_detrator} ({pct_detr:.1f}%)")
print(f"  NPS = {score_nps:.0f}")
print(f"  Mediana: {np.median(notas):.1f}  Q1: {np.percentile(notas,25):.1f}  Q3: {np.percentile(notas,75):.1f}")

COR_PROM = "#2C7BB6"
COR_NEUT = "#F4A442"
COR_DETR = "#E05C5C"

def cor_classe(nota):
    if nota <= 6: return COR_DETR
    if nota <= 8: return COR_NEUT
    return COR_PROM

# ── Figura 1 — Boxplot + distribuição ────────────────────────────────────
fig1, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6),
                                 gridspec_kw={"width_ratios": [2, 1]})
fig1.suptitle(f"Net Promoter Score (NPS) — MOTIVA (n={n_total})\nScore: {score_nps:.0f}",
              fontsize=16, fontweight="bold", y=0.98)

ax1.boxplot(notas, vert=True, patch_artist=True, widths=0.35,
            boxprops=dict(facecolor="#EEEEEE", color="#555555", linewidth=1.5),
            medianprops=dict(color="#222222", linewidth=2.5),
            whiskerprops=dict(color="#555555", linewidth=1.5),
            capprops=dict(color="#555555", linewidth=1.5),
            flierprops=dict(marker="o", markerfacecolor="#999", markersize=5))

random.seed(42)
for d in dados:
    x = 1 + random.uniform(-0.12, 0.12)
    ax1.scatter(x, d["nota"], color=cor_classe(d["nota"]),
                s=80, zorder=5, edgecolors="white", linewidths=0.8)

ax1.axhspan(0,   6.5, alpha=0.08, color=COR_DETR)
ax1.axhspan(6.5, 8.5, alpha=0.08, color=COR_NEUT)
ax1.axhspan(8.5, 10,  alpha=0.08, color=COR_PROM)
ax1.text(1.28, 3.5,  "Detratores\n(0–6)",  fontsize=12, color=COR_DETR, va="center", ha="left", fontweight="bold")
ax1.text(1.28, 7.5,  "Neutros\n(7–8)",     fontsize=12, color=COR_NEUT, va="center", ha="left", fontweight="bold")
ax1.text(1.28, 9.25, "Promotores\n(9–10)", fontsize=12, color=COR_PROM, va="center", ha="left", fontweight="bold")
ax1.set_xlim(0.5, 1.6)
ax1.set_ylim(0, 10.5)
ax1.set_xticks([])
ax1.set_yticks(range(0, 11))
ax1.set_ylabel("Nota de recomendação (0–10)", fontsize=13)
ax1.set_title("Dispersão das notas", fontsize=13, fontweight="bold", pad=8)
ax1.spines["top"].set_visible(False)
ax1.spines["right"].set_visible(False)
ax1.spines["bottom"].set_visible(False)
med = np.median(notas)
q1  = np.percentile(notas, 25)
q3  = np.percentile(notas, 75)
ax1.text(0.5, -0.06,
         f"Mediana: {med:.1f}   Q1: {q1:.1f}   Q3: {q3:.1f}   Média: {np.mean(notas):.1f}",
         transform=ax1.transAxes, fontsize=10, color="gray", ha="center")

categorias = ["Detratores", "Neutros", "Promotores"]
valores    = [n_detrator, n_neutro, n_promotor]
cores      = [COR_DETR, COR_NEUT, COR_PROM]
pcts       = [pct_detr, 0, pct_prom]
bars = ax2.bar(categorias, valores, color=cores, edgecolor="white", width=0.5)
for bar, val, pct in zip(bars, valores, pcts):
    ax2.text(bar.get_x() + bar.get_width() / 2,
             bar.get_height() + 0.05,
             f"{val}\n({pct:.0f}%)" if pct > 0 else str(val),
             ha="center", va="bottom", fontsize=10, fontweight="bold")
ax2.set_ylim(0, max(valores) + 2)
ax2.set_ylabel("Número de respondentes", fontsize=12)
ax2.set_title("Distribuição por categoria", fontsize=12, fontweight="bold", pad=8)
ax2.spines["top"].set_visible(False)
ax2.spines["right"].set_visible(False)
ax2.tick_params(axis="x", labelsize=9)


plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.88)
path1 = os.path.join(BASE_DIR, "script5_nps.png")
plt.savefig(path1, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path1}")

# ── Figura 2 — Dot plot por persona ──────────────────────────────────────
# Agrupar personas — mesma persona pode ter múltiplas notas
from collections import defaultdict
persona_notas = defaultdict(list)
for d in dados:
    persona_notas[d["persona"]].append((d["nota"], d["classe"]))

personas_unicas = list(persona_notas.keys())
n_personas = len(personas_unicas)

fig2, ax = plt.subplots(figsize=(10, max(4, n_personas * 0.9 + 2)))
fig2.suptitle("NPS por persona — MOTIVA\n(Gênero | Faixa etária | Tempo de prática)",
              fontsize=13, fontweight="bold", y=0.98)

ax.axvspan(0,   6.5, alpha=0.07, color=COR_DETR)
ax.axvspan(6.5, 8.5, alpha=0.07, color=COR_NEUT)
ax.axvspan(8.5, 10,  alpha=0.07, color=COR_PROM)

for limite in [6.5, 8.5]:
    ax.axvline(limite, color="gray", linewidth=0.8, linestyle="--", alpha=0.5)

random.seed(7)
for yi, persona in enumerate(personas_unicas):
    for nota, classe in persona_notas[persona]:
        jitter = random.uniform(-0.12, 0.12)
        ax.scatter(nota, yi + jitter,
                   color=cor_classe(nota), s=120,
                   edgecolors="white", linewidths=1, zorder=4)
        ax.text(nota + 0.15, yi + jitter, str(nota),
                va="center", ha="left", fontsize=10,
                color=cor_classe(nota), fontweight="bold")

ax.set_yticks(range(n_personas))
ax.set_yticklabels(personas_unicas, fontsize=12)
ax.set_xlim(5.5, 11)
ax.set_xticks(range(6, 11))
ax.set_xlabel("Nota de recomendação", fontsize=12)
ax.set_title("Nota por persona", fontsize=13, fontweight="bold", pad=8)
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

patch_p = mpatches.Patch(color=COR_PROM, label="Promotor (9–10)")
patch_n = mpatches.Patch(color=COR_NEUT, label="Neutro (7–8)")
patch_d = mpatches.Patch(color=COR_DETR, label="Detrator (0–6)")
ax.legend(handles=[patch_p, patch_n, patch_d],
          fontsize=10, loc="upper left", bbox_to_anchor=(1.02, 1),
          framealpha=0.8, borderaxespad=0)

plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.88, bottom=0.10, left=0.38, right=0.82)
path2 = os.path.join(BASE_DIR, "script5b_nps_personas.png")
plt.savefig(path2, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path2}")