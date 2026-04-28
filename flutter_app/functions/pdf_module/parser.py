# functions/pdf_module/parser.py

import logging
import re
import unicodedata
import fitz  # PyMuPDF
from datetime import datetime
from typing import Optional

from firebase_admin import firestore
from google.cloud import storage

# ==============================================================================
# CONSTANTES
# ==============================================================================

HEADERS = ["WARM UP", "EXTRA TRAINING", "SKILL", "WOD"]

MAPA_MESES = {
    "JANEIRO": 1, "JAN": 1,
    "FEVEREIRO": 2, "FEV": 2,
    "MARCO": 3, "MAR": 3,
    "ABRIL": 4, "ABR": 4,
    "MAIO": 5, "MAI": 5,
    "JUNHO": 6, "JUN": 6,
    "JULHO": 7, "JUL": 7,
    "AGOSTO": 8, "AGO": 8,
    "SETEMBRO": 9, "SET": 9,
    "OUTUBRO": 10, "OUT": 10,
    "NOVEMBRO": 11, "NOV": 11,
    "DEZEMBRO": 12, "DEZ": 12
}

# ==============================================================================
# SEÇÃO 1: EXTRAÇÃO E NORMALIZAÇÃO DE TEXTO
# ==============================================================================

def extract_text_from_pdf(pdf_bytes: bytes, use_blocks: bool = False) -> str:
    """Lê o PDF direto da memória (bytes) e extrai texto."""
    text = ""
    with fitz.open(stream=pdf_bytes, filetype="pdf") as doc:
        if use_blocks:
            pages_text = []
            for page in doc:
                blocks = page.get_text("blocks")
                blocks_sorted = sorted(blocks, key=lambda b: (b[1], b[0]))
                page_text = "\n".join(b[4].strip() for b in blocks_sorted if b[4].strip())
                pages_text.append(page_text)
            text = "\n\n".join(pages_text)
        else:
            for page in doc:
                text += page.get_text("text") + "\n"
    return text

def normalize_text_for_regex(text: str) -> str:
    """Normaliza unicode, remove caracteres especiais e padroniza espaços."""
    if not text:
        return text
    text = unicodedata.normalize("NFKC", text)
    trans = {
        '\u2013': '-', '\u2014': '-', '\u2012': '-', '\u2010': '-',
        '\u2019': "'", '\u2018': "'", '\u2032': "'", '\u02bc': "'",  # modifier letter apostrophe (PDFs)
        '\u201A': ',', '\u2026': '...'
    }
    for k, v in trans.items():
        text = text.replace(k, v)
    text = re.sub(r'\r\n?', '\n', text)
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{2,}', '\n\n', text)
    return text.strip()

# ==============================================================================
# SEÇÃO 2: DATA E IDENTIFICAÇÃO DO DIA
# ==============================================================================

def parse_data_e_dia(text: str) -> tuple:
    """Extrai a data (ex: '10 MARCO') e o dia da semana (ex: 'TERCA FEIRA')."""
    if not text:
        return None, None
    txt = unicodedata.normalize("NFKD", text).upper()
    txt_ascii = re.sub(r'[^\x00-\x7F]', '', txt)

    m = re.search(r'(\b\d{1,2}\s+[A-Z]+)\s*\|\s*([A-Z\s]+FEIRA)\b', txt_ascii, re.IGNORECASE)
    if m:
        return m.group(1).strip(), m.group(2).strip()

    m2 = re.search(r'\b(SEGUNDA|TERCA|QUARTA|QUINTA|SEXTA|SABADO|DOMINGO)\b', txt_ascii, re.IGNORECASE)
    if m2:
        return None, m2.group(0).strip().upper()
    return None, None

def converter_data_para_iso(data_texto: Optional[str]) -> Optional[str]:
    """Converte '10 MARCO' para '2026-03-10'."""
    if not data_texto:
        return None
    try:
        texto_limpo = (
            unicodedata.normalize("NFKD", data_texto)
            .encode('ASCII', 'ignore')
            .decode('utf-8')
            .upper()
        )
        match = re.search(r'(\d{1,2})\s+([A-Z]+)', texto_limpo)
        if not match:
            return None
        dia = int(match.group(1))
        nome_mes = match.group(2)
        numero_mes = MAPA_MESES.get(nome_mes)
        if not numero_mes:
            logging.warning(f"Mês não reconhecido: {nome_mes}")
            return None
        ano_atual = datetime.now().year
        return datetime(ano_atual, numero_mes, dia).strftime("%Y-%m-%d")
    except Exception as e:
        logging.error(f"Erro ao converter data ISO: {e}")
        return None

def formatar_data_display(data_iso: Optional[str]) -> Optional[str]:
    """Converte '2026-03-10' para '10/03/2026' (exibição na UI)."""
    if not data_iso:
        return None
    try:
        return datetime.strptime(data_iso, "%Y-%m-%d").strftime("%d/%m/%Y")
    except Exception:
        return None

def formatar_data_para_documento(data_iso: Optional[str]) -> Optional[str]:
    """
    Converte '2026-03-10' para '10-03-2026' (ID do documento Firestore).
    IMPORTANTE: usa '-' em vez de '/' — barras no ID do Firestore são
    interpretadas como separadores de coleção e criam subcoleções indesejadas.
    """
    if not data_iso:
        return None
    try:
        return datetime.strptime(data_iso, "%Y-%m-%d").strftime("%d-%m-%Y")
    except Exception:
        return None

# ==============================================================================
# SEÇÃO 3: MATERIAIS
# ==============================================================================

def parse_materiais(text: str) -> list:
    """
    Extrai lista de materiais separando por '|', vírgula e 'e'.
    Ex: "Munhequeira | Gripp | Protetor de canela"
        → ["Munhequeira", "Gripp", "Protetor de canela"]
    """
    if not text:
        return []
    match = re.search(r'\bMATERIAL(?:S)?\s*:\s*([^\n]+)', text, re.IGNORECASE)
    if not match:
        return []
    materiais_str = match.group(1).strip()
    parts = []
    for chunk in re.split(r'[|,]', materiais_str):
        for sub in re.split(r'\s+e\s+', chunk, flags=re.IGNORECASE):
            item = sub.strip()
            if item:
                parts.append(item)
    seen = set()
    out = []
    for it in parts:
        key = it.lower()
        if key not in seen:
            seen.add(key)
            out.append(it)
    return out

# ==============================================================================
# SEÇÃO 4: PARSING DE EXERCÍCIOS
# ==============================================================================

def parse_exercicio(linha: str) -> dict:
    """
    Converte uma linha de exercício em objeto estruturado.

    Padrões suportados:
      "20 Box jump step down"      → {quantidade:20, nome:"Box jump step down", unidade:"reps"}
      "15 KTB swing (24Kg|18Kg)"   → {quantidade:15, nome:"KTB swing", cargaRx:"24Kg", cargaScaled:"18Kg"}
      "500m Run"                   → {quantidade:500, nome:"Run", unidade:"metros"}
      "10:10 KTB side swing"       → {quantidade:"10:10", nome:"KTB side swing", unidade:"reps"}
    """
    linha = linha.strip()

    # Strip prefixo de rounds/EMOM numerados: "1º- " / "1o- " / "2°- "
    # O PDF normaliza 'º' para 'o' após unicode normalize
    linha = re.sub(r'^\d+[°ºo]\s*[-\u2013]\s*', '', linha)

    result = {
        "raw": linha,
        "quantidade": None,
        "nome": None,
        "unidade": "reps",
        "cargaRx": None,
        "cargaScaled": None,
    }

    # 1. Extrai carga entre parênteses: (24Kg|18Kg) ou (24Kg)
    carga_match = re.search(r'\(([^)]+)\)', linha)
    if carga_match:
        carga_str = carga_match.group(1)
        if '|' in carga_str:
            partes_carga = [p.strip() for p in carga_str.split('|')]
            result["cargaRx"] = partes_carga[0]
            result["cargaScaled"] = partes_carga[1] if len(partes_carga) > 1 else None
        else:
            result["cargaRx"] = carga_str.strip()
        linha = (linha[:carga_match.start()] + linha[carga_match.end():]).strip()

    # 2. Distância: "500m Run", "500 m Run", "100m Row", "1km Row", "1 km Row"
    #    k?m = 'k' opcional + 'm' → cobre tanto metros (m) quanto quilômetros (km)
    #    \s* = espaço opcional entre o número e a unidade
    dist_match = re.match(r'^(\d+)\s*(k?m)\s+(.+)$', linha, re.IGNORECASE)
    if dist_match:
        result["quantidade"] = int(dist_match.group(1))
        result["unidade"] = "km" if dist_match.group(2).lower() == "km" else "metros"
        result["nome"] = dist_match.group(3).strip()
        return result

    # 3. Ratio: "10:10 KTB side swing"
    ratio_match = re.match(r'^(\d+:\d+)\s+(.+)$', linha)
    if ratio_match:
        result["quantidade"] = ratio_match.group(1)
        result["nome"] = ratio_match.group(2).strip()
        return result

    # 3b. Segundos: '30" Handstand hold', "30'' Wall sit"
    #     Cobre aspas duplas e dois apóstrofos como notação de segundos
    seg_match = re.match(r'^(\d+)["\u2033\u02ba\'\']{1,2}\s+(.+)$', linha)
    if seg_match:
        result["quantidade"] = int(seg_match.group(1))
        result["unidade"] = "segundos"
        result["nome"] = seg_match.group(2).strip()
        return result

    # 4. Padrão padrão: "20 Box jump", "05 Burpees"
    std_match = re.match(r'^(\d+)\s+(.+)$', linha)
    if std_match:
        result["quantidade"] = int(std_match.group(1))
        result["nome"] = std_match.group(2).strip()
        return result

    # 5. Fallback
    result["nome"] = linha
    return result

def is_linha_exercicio(ln: str) -> bool:
    """
    Retorna True se a linha representa um exercício válido.
    Filtra linhas de observação, material e modalidade de treino.
    """
    if re.match(r'^\s*OBSERVA', ln, re.IGNORECASE):
        return False
    if re.match(r'^\s*MATERIAL', ln, re.IGNORECASE):
        return False
    # Filtra modalidades/rounds (ex: "3 ROUNDS FOR TIME", "AMRAP")
    if re.search(r'\b(ROUNDS?\s+FOR\s+TIME|AMRAP|FOR\s+TIME|EMOM)\b', ln, re.IGNORECASE):
        return False
    if re.match(r'^\d+\s+ROUNDS?\b', ln, re.IGNORECASE):
        return False

    # Critérios positivos
    if re.match(r'^\d+\s+\w', ln):                       # começa com número + espaço: "20 Box..."
        return True
    if re.match(r'^\d+\s*k?m\s+\w', ln, re.IGNORECASE): # distância: "500m Run", "500 m Run", "1km Row"
        return True
    if re.match(r'^\d+:\d+\s+\w', ln):                   # ratio: "10:10 KTB..."
        return True
    if re.search(r'\b[Kk][Gg]\b', ln):                   # tem peso em Kg
        return True
    # Segundos: "30\" Handstand hold", "45'' Wall sit"
    if re.match(r'^\d+["\u2033\u02ba\'\']{{1,2}}\s+\w', ln):
        return True
    # Formato EMOM/rounds numerados: "1º- 04 Power clean", "2o- 30\" Handstand hold"
    # O PDF normaliza 'º' para 'o', então checamos ambos
    if re.match(r'^\d+[°ºo]\s*[-\u2013]\s*\d+', ln, re.IGNORECASE):
        return True
    return False

# ==============================================================================
# SEÇÃO 5: PARSING DE MODALIDADE, DURAÇÃO E ROUNDS
# ==============================================================================

def extract_tipo_duracao_rounds(lines: list) -> tuple:
    """
    Varre linhas em busca de modalidade, duração e número de rounds.
    Retorna (modalidade, duracao_minutos, rounds).

    Exemplos de linhas reconhecidas:
      "WARM UP - AMRAP (5')"        → ("AMRAP", 5, None)
      "3 ROUNDS FOR TIME (20')"     → ("3 ROUNDS FOR TIME", 20, 3)
      "WOD - SKY IS THE LIMIT"      → busca nas próximas linhas
    """
    modalidade = None
    duracao = None
    rounds = None

    for ln in lines[:6]:
        # "3 ROUNDS FOR TIME"
        m = re.search(r'(\d+)\s+ROUNDS?\s+FOR\s+TIME', ln, re.IGNORECASE)
        if m and not modalidade:
            rounds = int(m.group(1))
            modalidade = f"{rounds} ROUNDS FOR TIME"

        if re.search(r'\bAMRAP\b', ln, re.IGNORECASE) and not modalidade:
            modalidade = "AMRAP"

        if re.search(r'\bFOR\s+TIME\b', ln, re.IGNORECASE) and not modalidade:
            modalidade = "FOR TIME"

        if re.search(r'\bEMOM\b', ln, re.IGNORECASE) and not modalidade:
            modalidade = "EMOM"

        if not modalidade:
            m2 = re.search(r'(\d+)\s+ROUNDS?\b', ln, re.IGNORECASE)
            if m2:
                rounds = int(m2.group(1))
                modalidade = f"{rounds} ROUNDS"

        # Duração: (20'), (5'), 20 min
        dur = re.search(r"\((\d{1,3})\s*['']\)|\b(\d{1,3})\s*min\b", ln, re.IGNORECASE)
        if dur and not duracao:
            val = dur.group(1) or dur.group(2)
            if val:
                duracao = int(val)

    return modalidade, duracao, rounds

# ==============================================================================
# SEÇÃO 6: OBSERVAÇÕES
# ==============================================================================

def extract_observacoes(bloco_text: str) -> Optional[str]:
    """
    Extrai observações de um bloco de texto.
    Funciona independente da ordem em relação ao campo MATERIAL.
    Ignora observações vazias ou com apenas traços.
    """
    if not bloco_text:
        return None

    # Tenta capturar até MATERIAL (caso OBSERVAÇÃO venha antes)
    obs_match = re.search(
        r'\bOBSERVA(?:C|Ç)(?:A|Ã)O\b\s*:\s*([\s\S]*?)(?=\bMATERIAL\b|\Z)',
        bloco_text, re.IGNORECASE
    )
    # Fallback: OBSERVAÇÃO depois do MATERIAL (WOD)
    if not obs_match:
        obs_match = re.search(
            r'\bOBSERVA(?:C|Ç)(?:A|Ã)O\b\s*:\s*([\s\S]+)',
            bloco_text, re.IGNORECASE
        )

    if not obs_match:
        return None

    obs_text = obs_match.group(1).strip()
    lines = obs_text.splitlines()
    cleaned = []

    for ln in lines:
        stripped = ln.strip()
        if not stripped or re.fullmatch(r'[-\s·•*]+', stripped):
            if not cleaned:
                continue  # pula vazios/traços no início
            else:
                break     # para no primeiro parágrafo vazio
        cleaned.append(stripped)

    result = " ".join(cleaned).strip()
    return result if result else None

# ==============================================================================
# SEÇÃO 7: PARSING COMPLETO DAS PARTES DO TREINO
# ==============================================================================

def _empty_parte(header: str) -> dict:
    return {
        "secao": header.upper(),
        "modalidade": None,
        "rounds": None,
        "duracaoMinutos": None,
        "nomeWod": None,
        "exercicios": [],
        "observacoes": None
    }

def _parse_exercicios_com_reps_pendentes(lines: list) -> list:
    """
    Processa uma lista de linhas extraindo exercícios, com suporte a:
    - Exercícios normais: "20 Box jump", "500m Run"
    - Reps decrescentes isoladas: "15|12|9|6|3" numa linha,
      seguido do exercício na linha de baixo sem quantidade própria.
      Ex:  "15|12|9|6|3"  +  "HSPU strict"
           → {quantidade: "15|12|9|6|3", nome: "HSPU strict", unidade: "reps"}
    """
    exercicios = []
    pending_reps = None  # quantidade em espera de um exercício sem número

    for ln in lines:
        # Linha é um esquema de reps decrescentes puro: "15|12|9|6|3"
        if re.match(r'^\d+(\|\d+)+$', ln.strip()):
            pending_reps = ln.strip()
            continue

        if is_linha_exercicio(ln):
            # Exercício com quantidade própria — descarta reps pendentes
            pending_reps = None
            exercicios.append(parse_exercicio(ln))
            continue

        # Linha é nome de exercício sem quantidade própria?
        # Critério: começa com letra, não é OBSERVAÇÃO/MATERIAL/modalidade
        if (pending_reps
                and re.match(r'^[A-Za-z]', ln)
                and not re.match(r'^\s*OBSERVA', ln, re.IGNORECASE)
                and not re.match(r'^\s*MATERIAL', ln, re.IGNORECASE)
                and not re.search(r'\b(AMRAP|FOR\s+TIME|EMOM|ROUNDS?)\b', ln, re.IGNORECASE)):
            exercicios.append({
                "raw": f"{pending_reps} {ln}",
                "quantidade": pending_reps,
                "nome": ln.strip(),
                "unidade": "reps",
                "cargaRx": None,
                "cargaScaled": None,
            })
            pending_reps = None

    return exercicios


def parse_partes_do_treino(text: str) -> dict:
    """
    Extrai cada seção do treino (WARM UP, EXTRA TRAINING, SKILL, WOD)
    como um objeto estruturado com exercícios, modalidade, rounds, etc.
    """
    partes = {}
    if not text:
        for h in HEADERS:
            partes[h] = _empty_parte(h)
        return partes

    headers_pattern = "|".join([re.escape(h) for h in HEADERS])

    for header in HEADERS:
        # Captura a linha do header + todo o conteúdo até o próximo header
        pattern = rf"(?im)^({re.escape(header)}[^\n]*)\n([\s\S]*?)(?=^(?:{headers_pattern})\b|\Z)"
        m = re.search(pattern, text, re.MULTILINE)

        if not m:
            partes[header.upper()] = _empty_parte(header)
            continue

        header_line = m.group(1).strip()    # ex: "WOD - SKY IS THE LIMIT"
        bloco_conteudo = m.group(2).strip() # conteúdo após a linha do header
        lines = [ln.strip() for ln in bloco_conteudo.splitlines() if ln.strip()]

        # --- Nome do WOD/Skill ---
        # Extraído do separador na linha do header: "SKILL - BOX JUMP"
        nome = None
        sep_match = re.search(r'[-–]\s*(.+)$', header_line)
        if sep_match:
            candidate = sep_match.group(1).strip()
            # Só é nome se NÃO for uma modalidade de treino
            if not re.search(r'\b(AMRAP|FOR\s+TIME|EMOM|ROUNDS?)\b', candidate, re.IGNORECASE):
                nome = candidate

        # --- Modalidade, duração e rounds ---
        # Varre a linha do header e as primeiras linhas do conteúdo
        modalidade, duracao, rounds = extract_tipo_duracao_rounds([header_line] + lines)

        # --- Exercícios ---
        # Suporte a reps decrescentes: "15|12|9|6|3" em linha isolada,
        # seguido do nome do exercício na linha seguinte sem quantidade própria.
        exercicios = _parse_exercicios_com_reps_pendentes(lines)

        # --- Observações ---
        observacoes = extract_observacoes(bloco_conteudo)

        partes[header.upper()] = {
            "secao": header.upper(),
            "modalidade": modalidade,
            "rounds": rounds,
            "duracaoMinutos": duracao,
            "nomeWod": nome,
            "exercicios": exercicios,
            "observacoes": observacoes
        }

    return partes

# ==============================================================================
# SEÇÃO 8: NOME DO DOCUMENTO FIRESTORE
# ==============================================================================

def gerar_nome_documento(partes: dict, data_iso: Optional[str]) -> str:
    """
    Gera ID legível para o documento no Firestore.
    Prioridade: nomeWod do WOD → nomeWod do SKILL → data apenas.
    Formato: "SKY IS THE LIMIT (10-03-2026)"
    NOTA: usa '-' na data para evitar subcoleções no Firestore.
    """
    # ID do documento usa '-' (nunca '/')
    data_doc = formatar_data_para_documento(data_iso) or data_iso or "sem-data"
    nome_wod = None

    for secao in ["WOD", "SKILL", "EXTRA TRAINING", "WARM UP"]:
        parte = partes.get(secao, {})
        if parte.get("nomeWod"):
            nome_wod = parte["nomeWod"]
            break

    if nome_wod:
        # Remove caracteres inválidos para IDs do Firestore
        nome_sanitizado = re.sub(r'[\/\.\[\]#]', '-', nome_wod)
        return f"{nome_sanitizado} ({data_doc})"

    return f"Treino ({data_doc})"

# ==============================================================================
# SEÇÃO 9: LÓGICA PRINCIPAL (INTEGRAÇÃO COM FIREBASE)
# ==============================================================================

def run_pdf_parser_logic(event):
    """
    Ponto de entrada chamado pelo main.py quando um PDF é enviado ao Storage.
    Processa o PDF e salva o treino estruturado no Firestore.
    """
    if event.data.content_type != "application/pdf":
        logging.info(f"Arquivo ignorado (não é PDF): {event.data.name}")
        return

    firestore_client = firestore.client()
    storage_client = storage.Client()

    bucket_name = event.data.bucket
    file_path = event.data.name
    logging.info(f"Processando PDF: {file_path}")

    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_path)
        pdf_bytes = blob.download_as_bytes()

        metadata = event.data.metadata or {}
        box_id = metadata.get('boxId', 'BOX_PRINCIPAL')
        user_id = metadata.get('userId', 'ADMIN')

        raw_text = extract_text_from_pdf(pdf_bytes)
        normalized_text = normalize_text_for_regex(raw_text)

        data_str, dia_semana = parse_data_e_dia(normalized_text)
        data_iso = converter_data_para_iso(data_str)

        partes_treino = parse_partes_do_treino(normalized_text)
        materiais = parse_materiais(normalized_text)

        nome_documento = gerar_nome_documento(partes_treino, data_iso)

        treino_json = {
            "arquivoFonte": file_path,
            "uploadedBy": user_id,
            "createdByUid": user_id,
            "boxId": box_id,
            "criadoEm": firestore.SERVER_TIMESTAMP,
            "dataDoTreinoTexto": data_str,
            "dataTreinoIso": data_iso,
            "diaDaSemana": dia_semana,
            "materiais": materiais,
            "partes": partes_treino,
            "status": "processado",
            "statusAnalise": "pendente"
        }

        doc_ref = firestore_client.collection("exercises").document(nome_documento)
        doc_ref.set(treino_json)

        logging.info(f"Treino salvo: '{nome_documento}' | Data ISO: {data_iso}")

    except Exception as e:
        logging.error(f"Erro fatal ao processar {file_path}: {e}")
        raise
