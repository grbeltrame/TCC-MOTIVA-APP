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

ESCALA = {
    "Discordo Fortemente": 1,
    "Discordo":            2,
    "Neutro":              3,
    "Concordo":            4,
    "Concordo Fortemente": 5,
}

CORES = {
    "Discordo Fortemente": "#D7191C",
    "Discordo":            "#FDAE61",
    "Neutro":              "#FFFFBF",
    "Concordo":            "#A6D96A",
    "Concordo Fortemente": "#1A9641",
}
ORDEM = ["Discordo Fortemente", "Discordo", "Neutro", "Concordo", "Concordo Fortemente"]

def extrair_label(h):
    m = re.search(r'\[(.+)\]', h)
    return m.group(1).strip() if m else h.strip()

# Mapeamento de colunas por perfil
COLS_ALUNO_A  = list(range(18, 29))
COLS_COACH_B  = list(range(32, 44))
COLS_AMBOS_ALUNO = list(range(61, 72))
COLS_AMBOS_COACH = list(range(49, 61))

LABELS_ALUNO = [extrair_label(headers[c]) for c in COLS_ALUNO_A]
LABELS_COACH = [extrair_label(headers[c]) for c in COLS_COACH_B]

def consolidar_respostas(rows_grupo, cols_primario, cols_ambos):
    """Retorna lista de respostas por pergunta (índice da coluna)."""
    resultado = {i: [] for i in range(len(cols_primario))}
    for r in rows_grupo:
        vals = [r[c].strip() for c in cols_primario]
        vals_ambos = [r[c].strip() for c in cols_ambos]
        # usa primário se preenchido, senão ambos
        for i, (v, va) in enumerate(zip(vals, vals_ambos)):
            val = v if v else va
            if val in ESCALA:
                resultado[i].append(val)
    return resultado

def calcular_pcts(respostas_por_pergunta, n_perguntas):
    """Retorna matriz [n_perguntas x 5] com percentuais."""
    matriz = np.zeros((n_perguntas, 5))
    for i in range(n_perguntas):
        resps = respostas_por_pergunta[i]
        n = len(resps)
        if n == 0:
            continue
        for j, cat in enumerate(ORDEM):
            matriz[i, j] = resps.count(cat) / n * 100
    return matriz

def grafico_divergente(labels, matriz, titulo, ax):
    n = len(labels)
    # Posições das barras: negativas à esquerda do neutro, positivas à direita
    # Discordo Fort | Discordo | [Neutro centralizado] | Concordo | Concordo Fort
    left = np.zeros(n)

    # Lado esquerdo: Discordo Fort + Discordo (negativo)
    for j in [0, 1]:
        vals = -matriz[:, j]
        ax.barh(range(n), vals, left=left + vals * 0,
                color=CORES[ORDEM[j]], edgecolor="white", linewidth=0.3, height=0.7)
        left_neg = -matriz[:, 0] - matriz[:, 1]

    # Resetar para lado direito
    left_pos = np.zeros(n)
    for j in [3, 4]:
        vals = matriz[:, j]
        ax.barh(range(n), vals, left=left_pos,
                color=CORES[ORDEM[j]], edgecolor="white", linewidth=0.3, height=0.7)
        left_pos += vals

    # Neutro centralizado (metade para cada lado)
    neutro = matriz[:, 2]
    ax.barh(range(n), -neutro / 2, color=CORES["Neutro"],
            edgecolor="white", linewidth=0.3, height=0.7)
    ax.barh(range(n), neutro / 2, color=CORES["Neutro"],
            edgecolor="white", linewidth=0.3, height=0.7)

    # Recalcular correto com offset
    left_neg = np.zeros(n)
    ax.cla()
    # Discordo Fortemente (mais à esquerda)
    ax.barh(range(n), -matriz[:, 0], left=-matriz[:, 0] - matriz[:, 1] - matriz[:, 2]/2 + matriz[:, 0],
            color=CORES[ORDEM[0]], edgecolor="white", linewidth=0.3, height=0.7)

    # Desenhar corretamente do centro para fora
    ax.cla()
    for i_row in range(n):
        # Lado negativo: do centro para esquerda
        x = -matriz[i_row, 2] / 2
        for j in [1, 0]:  # Discordo depois Discordo Fort
            w = matriz[i_row, j]
            ax.barh(i_row, -w, left=x, color=CORES[ORDEM[j]],
                    edgecolor="white", linewidth=0.3, height=0.7)
            x -= w
        # Lado positivo: do centro para direita
        x = matriz[i_row, 2] / 2
        for j in [3, 4]:
            w = matriz[i_row, j]
            ax.barh(i_row, w, left=x, color=CORES[ORDEM[j]],
                    edgecolor="white", linewidth=0.3, height=0.7)
            x += w
        # Neutro centralizado
        ax.barh(i_row, matriz[i_row, 2], left=-matriz[i_row, 2]/2,
                color=CORES["Neutro"], edgecolor="white", linewidth=0.3, height=0.7)

    # Percentuais nas barras (só se >= 5%)
    for i_row in range(n):
        x = -matriz[i_row, 2] / 2
        for j in [1, 0]:
            w = matriz[i_row, j]
            cx = x - w/2
            if w >= 5:
                ax.text(cx, i_row, f"{w:.0f}%", ha="center", va="center",
                        fontsize=7, color="white", fontweight="bold")
            x -= w
        x = matriz[i_row, 2] / 2
        for j in [3, 4]:
            w = matriz[i_row, j]
            cx = x + w/2
            if w >= 5:
                ax.text(cx, i_row, f"{w:.0f}%", ha="center", va="center",
                        fontsize=7, color="white" if j == 4 else "#333333",
                        fontweight="bold")
            x += w
        # Neutro
        w = matriz[i_row, 2]
        if w >= 5:
            ax.text(0, i_row, f"{w:.0f}%", ha="center", va="center",
                    fontsize=7, color="#333333", fontweight="bold")

    ax.axvline(0, color="gray", linewidth=0.8, linestyle="-", alpha=0.5)
    ax.set_yticks(range(n))
    ax.set_yticklabels(labels, fontsize=8)
    ax.set_xlabel("Porcentagem (%)", fontsize=9)
    ax.set_title(titulo, fontsize=11, fontweight="bold", pad=8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # Eixo X simétrico
    lim = max(
        abs(np.sum(matriz[:, :2], axis=1) + matriz[:, 2]/2).max(),
        (np.sum(matriz[:, 3:], axis=1) + matriz[:, 2]/2).max()
    ) + 10
    ax.set_xlim(-lim, lim)

    # Labels eixo X em %
    ticks = ax.get_xticks()
    ax.set_xticklabels([f"{abs(int(t))}%" for t in ticks], fontsize=8)

    # Grid
    ax.xaxis.grid(True, linestyle="--", alpha=0.4, color="gray")
    ax.set_axisbelow(True)

# ── Gráfico 1 — Geral alunos ──────────────────────────────────────────────
alunos_rows  = [r for r in rows if r[5].strip() in ("Aluno", "Ambos")]
coaches_rows = [r for r in rows if r[5].strip() in ("Coach", "Ambos")]

resps_aluno = consolidar_respostas(alunos_rows, COLS_ALUNO_A, COLS_AMBOS_ALUNO)
resps_coach = consolidar_respostas(coaches_rows, COLS_COACH_B, COLS_AMBOS_COACH)

matriz_aluno = calcular_pcts(resps_aluno, len(COLS_ALUNO_A))
matriz_coach = calcular_pcts(resps_coach, len(COLS_COACH_B))

# Gráfico alunos geral
fig1, ax1 = plt.subplots(figsize=(14, max(6, len(LABELS_ALUNO) * 0.55 + 2)))
grafico_divergente(LABELS_ALUNO, matriz_aluno,
                   f"Gráfico Divergente de Respostas — Alunos (n={len(alunos_rows)})\n[Neutro centralizado]", ax1)

patches = [mpatches.Patch(color=CORES[c], label=c) for c in ORDEM]
ax1.legend(handles=patches, fontsize=8, loc="lower right",
           ncol=1, framealpha=0.8, bbox_to_anchor=(1.18, 0))

plt.tight_layout(pad=1.5)
plt.subplots_adjust(left=0.38, right=0.80, top=0.90, bottom=0.06)
path1 = os.path.join(BASE_DIR, "script6a_likert_alunos.png")
plt.savefig(path1, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path1}")

# Gráfico coaches geral
fig2, ax2 = plt.subplots(figsize=(14, max(6, len(LABELS_COACH) * 0.55 + 2)))
grafico_divergente(LABELS_COACH, matriz_coach,
                   f"Gráfico Divergente de Respostas — Coaches (n={len(coaches_rows)})\n[Neutro centralizado]", ax2)

ax2.legend(handles=patches, fontsize=8, loc="lower right",
           ncol=1, framealpha=0.8, bbox_to_anchor=(1.18, 0))

plt.tight_layout(pad=1.5)
plt.subplots_adjust(left=0.38, right=0.80, top=0.90, bottom=0.06)
path2 = os.path.join(BASE_DIR, "script6b_likert_coaches.png")
plt.savefig(path2, dpi=150, bbox_inches="tight")
plt.show()
print(f"Salvo: {path2}")

# ── Terminal — verificação manual ─────────────────────────────────────────
print("\n" + "=" * 60)
print("VERIFICAÇÃO MANUAL — ALUNOS")
print("=" * 60)
for i, label in enumerate(LABELS_ALUNO):
    resps = resps_aluno[i]
    n = len(resps)
    print(f"\n  [{i+1}] {label[:60]}")
    for cat in ORDEM:
        c = resps.count(cat)
        pct = c/n*100 if n > 0 else 0
        print(f"    {cat:<25} {c:>2}  ({pct:.0f}%)")

print("\n" + "=" * 60)
print("VERIFICAÇÃO MANUAL — COACHES")
print("=" * 60)
for i, label in enumerate(LABELS_COACH):
    resps = resps_coach[i]
    n = len(resps)
    print(f"\n  [{i+1}] {label[:60]}")
    for cat in ORDEM:
        c = resps.count(cat)
        pct = c/n*100 if n > 0 else 0
        print(f"    {cat:<25} {c:>2}  ({pct:.0f}%)")

# ── Heatmap por persona — Alunos ──────────────────────────────────────────
import matplotlib.colors as mcolors

ESCALA_NUM = {
    "Discordo Fortemente": 1,
    "Discordo":            2,
    "Neutro":              3,
    "Concordo":            4,
    "Concordo Fortemente": 5,
}

def persona_str(r):
    return f"{r[4].strip()} | {r[3].strip()} | {r[2].strip()}"

def get_vals_aluno(r):
    vals = []
    for c, ca in zip(COLS_ALUNO_A, COLS_AMBOS_ALUNO):
        v = r[c].strip() if r[c].strip() else r[ca].strip()
        vals.append(ESCALA_NUM.get(v, None))
    return vals

def get_vals_coach(r):
    vals = []
    for c, ca in zip(COLS_COACH_B, COLS_AMBOS_COACH):
        v = r[c].strip() if r[c].strip() else r[ca].strip()
        vals.append(ESCALA_NUM.get(v, None))
    return vals

def heatmap_personas(rows_grupo, get_vals, labels, titulo, path):
    from collections import defaultdict
    # Agrupar por persona
    persona_vals = defaultdict(lambda: [[] for _ in labels])
    for r in rows_grupo:
        p = persona_str(r)
        vals = get_vals(r)
        for i, v in enumerate(vals):
            if v is not None:
                persona_vals[p][i].append(v)

    personas = list(persona_vals.keys())
    n_p = len(personas)
    n_q = len(labels)

    # Matriz de médias
    matriz = np.full((n_q, n_p), np.nan)
    for j, p in enumerate(personas):
        for i in range(n_q):
            vs = persona_vals[p][i]
            if vs:
                matriz[i, j] = np.mean(vs)

    # Figura
    fig_h, ax_h = plt.subplots(figsize=(max(8, n_p * 2.2 + 3), max(6, n_q * 0.6 + 2)))

    cmap = plt.cm.RdYlGn
    im = ax_h.imshow(matriz, cmap=cmap, vmin=1, vmax=5, aspect="auto")

    # Labels
    ax_h.set_xticks(range(n_p))
    ax_h.set_xticklabels(personas, rotation=30, ha="right", fontsize=9)
    ax_h.set_yticks(range(n_q))
    ax_h.set_yticklabels(labels, fontsize=8)
    ax_h.set_xlabel("Perfil", fontsize=10)
    ax_h.set_ylabel("Perguntas", fontsize=10)
    ax_h.set_title(titulo, fontsize=12, fontweight="bold", pad=12)

    # Grade entre células
    ax_h.set_xticks(np.arange(-0.5, n_p, 1), minor=True)
    ax_h.set_yticks(np.arange(-0.5, n_q, 1), minor=True)
    ax_h.grid(which="minor", color="white", linewidth=1.5)
    ax_h.tick_params(which="minor", bottom=False, left=False)

    # Valores nas células
    for i in range(n_q):
        for j in range(n_p):
            val = matriz[i, j]
            if not np.isnan(val):
                cor_texto = "white" if val <= 2 or val >= 4.5 else "#333333"
                ax_h.text(j, i, f"{val:.2f}", ha="center", va="center",
                          fontsize=9, fontweight="bold", color=cor_texto)

    plt.colorbar(im, ax=ax_h, label="Média da Nota (1–5)", shrink=0.6)
    plt.tight_layout(pad=1.5)
    plt.subplots_adjust(left=0.38, right=0.92, top=0.92, bottom=0.22)
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.show()
    print(f"Salvo: {path}")

heatmap_personas(
    alunos_rows, get_vals_aluno, LABELS_ALUNO,
    f"Média das respostas por persona — Alunos (n={len(alunos_rows)})",
    os.path.join(BASE_DIR, "script6c_heatmap_alunos.png")
)

heatmap_personas(
    coaches_rows, get_vals_coach, LABELS_COACH,
    f"Média das respostas por persona — Coaches (n={len(coaches_rows)})",
    os.path.join(BASE_DIR, "script6d_heatmap_coaches.png")
)