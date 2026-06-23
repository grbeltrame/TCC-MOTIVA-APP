from __future__ import annotations

from configuracao import DADOS_DIR, PDF_DIR, PNG_DIR
from graficos_ux import gerar_todos


if __name__ == "__main__":
    gerar_todos()
    totais = {
        "PNG": len(list(PNG_DIR.glob("*.png"))),
        "PDF": len(list(PDF_DIR.glob("*.pdf"))),
        "CSV": len(list(DADOS_DIR.glob("*.csv"))),
    }
    print(
        f"Geração concluída: {sum(totais.values())} arquivos produzidos "
        f"({totais['PNG']} PNG, {totais['PDF']} PDF e {totais['CSV']} CSV)."
    )
