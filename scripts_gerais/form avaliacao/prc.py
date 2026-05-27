import csv
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from collections import Counter
from wordcloud import WordCloud
import os, re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "Avaliação Aplicativo Motiva (respostas) - Respostas ao formulário 1.csv")

with open(CSV_PATH, encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    rows = list(reader)

# Normalização — todas as variações mapeadas para forma canônica
NORMALIZAR = {
    "fácil de usar":  "Fácil de usar",
    "fácil de usar":  "Fácil de usar",
    "fácil de usar":  "Fácil de usar",
    "fácil":          "Fácil de usar",
    "intuitivo":      "Intuitivo",
    "claro":          "Claro",
    "prestativo":     "Prestativo",
    "significativo":  "Significativo",
    "objetivo":       "Objetivo",
    "motivador":      "Motivador",
    "familiar":       "Familiar",
    "atraente":       "Atraente",
    "eficaz":         "Eficaz",
    "acessível":      "Acessível",
    "eficiente":      "Eficiente",
    "inovador":       "Inovador",
    "útil":           "Útil",
    "rápido":         "Rápido",
    "novo":           "Novo",
    "estimulante":    "Estimulante",
    "personalizável": "Personalizável",
    "profissional":   "Profissional",
    "confiável":      "Confiável",
    "criativo":       "Criativo",
}

SENTIMENTO = {
    "Fácil de usar":  "Funcional",
    "Intuitivo":      "Funcional",
    "Claro":          "Funcional",
    "Eficaz":         "Funcional",
    "Eficiente":      "Funcional",
    "Acessível":      "Funcional",
    "Rápido":         "Funcional",
    "Objetivo":       "Funcional",
    "Prestativo":     "Funcional",
    "Profissional":   "Funcional",
    "Confiável":      "Funcional",
    "Personalizável": "Funcional",
    "Motivador":      "Emocional",
    "Estimulante":    "Emocional",
    "Atraente":       "Emocional",
    "Inovador":       "Emocional",
    "Criativo":       "Emocional",
    "Novo":           "Emocional",
    "Significativo":  "Emocional",
    "Útil":           "Neutro",
    "Familiar":       "Neutro",
}

def normalizar_token(t):
    t = t.strip().rstrip(".").lower()
    t = re.sub(r"\s+", " ", t)
    return NORMALIZAR.get(t)

def parse_adjetivos(texto):
    # Divide por vírgula, ponto e vírgula, ponto, ou " e "
    partes = re.split(r"[,;\.]+|\s+e\s+", texto, flags=re.IGNORECASE)
    resultado = []
    for p in partes:
        adj = normalizar_token(p)
        if adj:
            resultado.append(adj)
    return resultado

# Construir dados por perfil
dados_alunos  = []
dados_coaches = []
dados_todos   = []

for r in rows:
    perfil = r[5].strip()
    adjs   = parse_adjetivos(r[16])
    for adj in adjs:
        dados_todos.append(adj)
        if perfil in ("Aluno", "Ambos"):
            dados_alunos.append(adj)
        if perfil in ("Coach", "Ambos"):
            dados_coaches.append(adj)

contagem_geral   = Counter(dados_todos)
contagem_alunos  = Counter(dados_alunos)
contagem_coaches = Counter(dados_coaches)

# Verificação no terminal
print("=" * 50)
print("CONTAGEM GERAL")
print("=" * 50)
for adj, n in contagem_geral.most_common():
    print(f"  {adj:<20} {n}")

print("\n" + "=" * 50)
print("CONTAGEM — ALUNOS (inclui Ambos)")
print("=" * 50)
for adj, n in contagem_alunos.most_common():
    print(f"  {adj:<20} {n}")

print("\n" + "=" * 50)
print("CONTAGEM — COACHES (inclui Ambos)")
print("=" * 50)
for adj, n in contagem_coaches.most_common():
    print(f"  {adj:<20} {n}")

COR_F = "#2C7BB6"
COR_E = "#E07B2F"
COR_N = "#888888"

# ── 4A — Wordcloud ─────────────────────────────────────────────────────────
def cor_preto(word, **kwargs):
    freq = contagem_geral.get(word, 1)
    max_freq = max(contagem_geral.values())
    v = int(80 - (freq / max_freq) * 70)
    return f"#{v:02x}{v:02x}{v:02x}"

wc = WordCloud(
    width=1200, height=600,
    background_color="white",
    color_func=cor_preto,
    prefer_horizontal=0.85,
    min_font_size=10,
    max_font_size=120,
    max_words=50,
    collocations=False,
    relative_scaling=0.8,
    margin=4,
).generate_from_frequencies(contagem_geral)

fig_a, ax_a = plt.subplots(figsize=(13, 6))
ax_a.imshow(wc, interpolation="bilinear")
ax_a.axis("off")
ax_a.set_title("Product Reaction Cards — Nuvem de palavras (n=8)\n",
               fontsize=13, fontweight="bold", pad=12)
plt.tight_layout(pad=2.0)
path_a = os.path.join(BASE_DIR, "script4a_wordcloud.png")
plt.savefig(path_a, dpi=150, bbox_inches="tight")
plt.show()
print(f"\nSalvo: {path_a}")

# ── 4B — Heatmap ───────────────────────────────────────────────────────────
todos_unicos = sorted(contagem_geral.keys())
perfis       = ["Alunos", "Coaches"]
matriz = np.array([
    [contagem_alunos.get(a, 0)  for a in todos_unicos],
    [contagem_coaches.get(a, 0) for a in todos_unicos],
], dtype=float)

fig_b, ax_b = plt.subplots(figsize=(15, 4))
im = ax_b.imshow(matriz, cmap="Blues", aspect="auto", vmin=0)
ax_b.set_xticks(range(len(todos_unicos)))
ax_b.set_xticklabels(todos_unicos, rotation=45, ha="right", fontsize=9)
ax_b.set_yticks(range(len(perfis)))
ax_b.set_yticklabels(perfis, fontsize=10)
ax_b.set_title("Product Reaction Cards — Frequência por perfil",
               fontsize=13, fontweight="bold", pad=10)
for i in range(len(perfis)):
    for j in range(len(todos_unicos)):
        val = int(matriz[i, j])
        if val > 0:
            ax_b.text(j, i, str(val), ha="center", va="center",
                      fontsize=10, fontweight="bold",
                      color="white" if val >= 3 else "#333333")
plt.colorbar(im, ax=ax_b, label="Frequência", shrink=0.6)
plt.tight_layout(pad=2.5)
plt.subplots_adjust(top=0.85, bottom=0.30)
path_b = os.path.join(BASE_DIR, "script4b_heatmap.png")
plt.savefig(path_b, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path_b}")

# ── 4C — Matriz funcional x emocional ─────────────────────────────────────
funcionais = sorted([(a, contagem_geral[a]) for a in contagem_geral if SENTIMENTO.get(a) == "Funcional"], key=lambda x: -x[1])
emocionais = sorted([(a, contagem_geral[a]) for a in contagem_geral if SENTIMENTO.get(a) == "Emocional"], key=lambda x: -x[1])
neutros    = sorted([(a, contagem_geral[a]) for a in contagem_geral if SENTIMENTO.get(a) == "Neutro"],    key=lambda x: -x[1])

def posicoes_grade(n, x_start, x_end, y_start, y_end, cols):
    rows_n = (n + cols - 1) // cols
    xs = [x_start + (x_end - x_start) / (cols + 1) * (c + 1) for c in range(cols)]
    ys = [y_end   - (y_end - y_start)  / (rows_n + 1) * (r + 1) for r in range(rows_n)]
    pos = []
    for r in range(rows_n):
        for c in range(cols):
            if len(pos) < n:
                pos.append((xs[c % len(xs)], ys[r]))
    return pos

fig_c, ax_c = plt.subplots(figsize=(14, 9))
ax_c.set_xlim(0, 14)
ax_c.set_ylim(0, 10)

ax_c.axvspan(0,   6.8, 0, 1, alpha=0.05, color=COR_F, zorder=0)
ax_c.axvspan(7.2, 14,  0, 1, alpha=0.05, color=COR_E, zorder=0)
ax_c.axvline(7, color="gray", linewidth=1, linestyle="--", alpha=0.4, zorder=1)

ax_c.text(3.4,  9.5, "FUNCIONAL", ha="center", fontsize=13, color=COR_F, fontweight="bold", alpha=0.8)
ax_c.text(10.6, 9.5, "EMOCIONAL", ha="center", fontsize=13, color=COR_E, fontweight="bold", alpha=0.8)

def plotar(itens, posicoes, cor):
    for (adj, freq), (x, y) in zip(itens, posicoes):
        raio = 0.30 + freq * 0.20
        circle = plt.Circle((x, y), raio, color=cor, alpha=0.55, linewidth=0, zorder=3)
        ax_c.add_patch(circle)
        ax_c.text(x, y + raio + 0.15, adj,
                  ha="center", va="bottom",
                  fontsize=9, fontweight="bold",
                  color="#111111", zorder=5)

pos_f = posicoes_grade(len(funcionais), 0.3, 6.7, 0.5, 8.8, cols=3)
pos_e = posicoes_grade(len(emocionais), 7.3, 13.7, 0.5, 8.8, cols=3)
pos_n = posicoes_grade(len(neutros),    6.0, 8.0,  2.0, 6.0, cols=1)

plotar(funcionais, pos_f, COR_F)
plotar(emocionais, pos_e, COR_E)
plotar(neutros,    pos_n, COR_N)

ax_c.set_title(
    "Product Reaction Cards — Matriz Funcional × Emocional\n",
    fontsize=12, fontweight="bold", pad=12)
ax_c.axis("off")

patch_f = mpatches.Patch(color=COR_F, alpha=0.6, label="Funcional")
patch_e = mpatches.Patch(color=COR_E, alpha=0.6, label="Emocional")
patch_n = mpatches.Patch(color=COR_N, alpha=0.6, label="Neutro")
ax_c.legend(handles=[patch_f, patch_e, patch_n],
            fontsize=9, loc="lower center", ncol=3, framealpha=0.8)

plt.tight_layout(pad=2.0)
path_c = os.path.join(BASE_DIR, "script4c_matriz_sentimento.png")
plt.savefig(path_c, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path_c}")