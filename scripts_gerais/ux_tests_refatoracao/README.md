# Gráficos de UX — versão refatorada

Esta pasta é uma implementação paralela das análises em `scripts_gerais/ux_tests`.
A pasta original e o arquivo `scripts_gerais/respostas_formulario.csv` nunca são
alterados: o CSV original é usado apenas como fonte de leitura e todas as saídas
são gravadas dentro de `ux_tests_refatoracao`.

## Preparação do ambiente

É recomendado usar Python 3.12. Com `uv`, a partir desta pasta:

```bash
uv venv .venv --python 3.12
uv pip install --python .venv/bin/python -r requirements.txt
```

## Gerar todos os resultados

A partir da raiz do repositório, o comando único solicitado é:

```bash
python scripts_gerais/ux_tests_refatoracao/gerar_todos_graficos.py
```

Com um ambiente Python já ativado, o comando reduzido também funciona de qualquer
diretório:

```bash
python /caminho/do/repositorio/scripts_gerais/ux_tests_refatoracao/gerar_todos_graficos.py
```

Cada um dos 12 scripts replicados também pode ser executado individualmente.

## Organização das saídas

- `graficos/png`: imagens rasterizadas em 300 dpi.
- `graficos/pdf`: as mesmas figuras em formato vetorial, recomendado para LaTeX.
- `dados`: tabelas derivadas, legendas e validações em CSV UTF-8.
- `tests`: testes de integridade e reconciliação dos dados.

Para LaTeX, prefira os PDFs:

```tex
\includegraphics[width=\textwidth]{scripts_gerais/ux_tests_refatoracao/graficos/pdf/resumo_hipoteses_todos_perfis.pdf}
```

## Leitura recomendada no TCC

No corpo principal:

- `resumo_hipoteses_todos_perfis` para a prioridade geral das funcionalidades;
- os três gráficos `distribuicao_perfis_*` para caracterizar a amostra;
- `distribuicao_coach_vs_praticante` para comparar os públicos;
- arquivos terminados em `_resumo` para sínteses de perfis.

Nos resultados completos ou apêndice:

- `heatmap_hipoteses_*` mostra perfis com `n >= 7`;
- `_detalhe_01` e `_detalhe_02` preservam todos os perfis e as 20 hipóteses;
- o consolidado também possui `_resumo` e duas páginas de detalhe para leitura A4;
- `legenda_hipoteses_*` contém o texto integral das hipóteses;
- `legenda_perfis_*` traduz os códigos de perfil e informa o tamanho da amostra.

## Regras estatísticas

- A classificação replica os scripts antigos: quem respondeu `Ambos` entra no
  grupo Coach e não entra no grupo Praticante.
- `perfis_praticante` é mantido como um único gráfico completo e considera
  somente quem respondeu `Sou praticante/atleta de CrossFit`.
- Perfis com menos de 7 respostas continuam nos detalhamentos, destacados com
  asterisco e alerta visual.
- Os resumos de segmentos usam somente perfis com pelo menos 7 respostas.
- A escala de todos os heatmaps Likert é fixa entre 1 e 5, centrada em 3.

## Testes

```bash
python -m pytest -q scripts_gerais/ux_tests_refatoracao/tests
```
