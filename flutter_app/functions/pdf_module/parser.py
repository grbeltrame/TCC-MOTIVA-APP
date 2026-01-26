# functions/pdf_module/parser.py

import logging
import re
import unicodedata
import fitz  # PyMuPDF
from datetime import datetime

# Bibliotecas do Google Cloud e Firebase
from firebase_admin import firestore
from google.cloud import storage

# Constantes globais
HEADERS = ["WARM UP", "EXTRA TRAINING", "SKILL", "WOD"]

# --- NOVO: Mapa de meses para conversão ---
MAPA_MESES = {
    "JANEIRO": 1, "JAN": 1,
    "FEVEREIRO": 2, "FEV": 2,
    "MARCO": 3, "MARÇO": 3, "MAR": 3,
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
# SEÇÃO 1: FUNÇÕES AUXILIARES
# ==============================================================================

def extract_text_from_pdf(pdf_bytes, use_blocks=False):
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
    if not text:
        return text
    text = unicodedata.normalize("NFKC", text)
    trans = {
        '\u2013': '-', '\u2014': '-', '\u2012': '-', '\u2010': '-',
        '\u2019': "'", '\u2018': "'", '\u2032': "'", '\u201A': ',', '\u2026': '...'
    }
    for k, v in trans.items():
        text = text.replace(k, v)
    text = re.sub(r'\r\n?', '\n', text)
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{2,}', '\n\n', text)
    return text.strip()

def parse_data_e_dia(text):
    if not text:
        return None, None
    txt = unicodedata.normalize("NFKD", text).upper()
    txt_ascii = re.sub(r'[^\x00-\x7F]', '', txt)
    
    # Tenta achar dia mês e feira (Ex: 02 DEZEMBRO | SEGUNDA FEIRA)
    m = re.search(r'(\b\d{1,2}\s+[A-ZÇÀ-Ý]+)\s*\|\s*([A-ZÇÀ-Ý\s-]*FEIRA)\b', txt_ascii, re.IGNORECASE)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    
    # Fallback só para o dia da semana
    m2 = re.search(r'\b(S[ÈE]GUNDA|TERCA|TERÇA|QUARTA|QUINTA|SEXTA|SABADO|DOMINGO)\b', txt_ascii, re.IGNORECASE)
    if m2:
        return None, m2.group(0).strip().upper()
    return None, None

# --- NOVA FUNÇÃO: Converte "02 DEZEMBRO" para "2026-12-02" ---
def converter_data_para_iso(data_texto):
    """
    Recebe algo como '02 DEZEMBRO' ou '2 DEZEMBRO' e retorna 'YYYY-MM-DD'.
    Usa o ano atual do servidor.
    """
    if not data_texto:
        return None
    
    try:
        # Normaliza para garantir que não tenha caracteres estranhos e coloca em Maiúsculo
        texto_limpo = unicodedata.normalize("NFKD", data_texto).encode('ASCII', 'ignore').decode('utf-8').upper()
        
        # Regex para separar dia e mês
        # Pega 1 ou 2 digitos (dia) e o resto como texto (mês)
        match = re.search(r'(\d{1,2})\s+([A-Z]+)', texto_limpo)
        if not match:
            return None

        dia = int(match.group(1))
        nome_mes = match.group(2) # ex: DEZEMBRO

        # Busca o número do mês no mapa
        numero_mes = MAPA_MESES.get(nome_mes)
        
        if not numero_mes:
            logging.warning(f"Mês não reconhecido na conversão: {nome_mes}")
            return None

        # Pega o ano atual
        ano_atual = datetime.now().year

        # Cria o objeto date e formata para string ISO
        data_obj = datetime(ano_atual, numero_mes, dia)
        return data_obj.strftime("%Y-%m-%d") # Retorna ex: "2026-12-02"

    except Exception as e:
        logging.error(f"Erro ao converter data ISO: {e}")
        return None

def parse_materiais(text):
    if not text:
        return []
    match = re.search(r'\bMATERIAL(?:S)?\s*:\s*([^\n]+)', text, re.IGNORECASE)
    if not match:
        return []
    materiais_str = match.group(1).strip()
    parts = []
    for chunk in re.split(r',', materiais_str):
        for sub in re.split(r'\s+e\s+', chunk, flags=re.IGNORECASE):
            item = sub.strip()
            if item:
                parts.append(item)
    seen = set(); out = []
    for it in parts:
        key = it.lower()
        if key not in seen:
            seen.add(key); out.append(it)
    return out

def extract_observacoes_from_block(block_text):
    if not block_text: return None
    obs_marker = re.search(r'\bOBSERVA(?:C|Ç)AO\b\s*:', block_text, re.IGNORECASE)
    if not obs_marker: return None
    tail = block_text[obs_marker.end():]
    
    lines = [ln.rstrip() for ln in tail.splitlines()]
    collected = []
    max_lines = 40; i = 0
    while i < len(lines) and i < max_lines and (not lines[i].strip() or re.fullmatch(r'[-\s·•\*]+', lines[i].strip())): i += 1
    
    while i < len(lines) and len(collected) < max_lines:
        ln = lines[i].strip()
        if not ln: break 
        if re.match(r'^\s*(?:MATERIAL(?:S)?\s*:|\b(?:' + "|".join([re.escape(h) for h in HEADERS]) + r')\b)', ln, re.IGNORECASE): break
        if re.fullmatch(r'[-\s·•\*]+', ln): 
            i += 1; continue
        collected.append(ln); i += 1
    
    return "\n".join(collected).strip() or None if collected else None

def detect_tipo_duracao_from_line(line):
    dur = None; t = None
    dur_match = re.search(r"\(\d{1,3}\s*['’]?\)|\b\d{1,3}\s*(?:min|m)\b", line, re.IGNORECASE)
    if dur_match: 
        nums = re.findall(r'\d+', dur_match.group(0))
        if nums: dur = int(nums[0])
        
    tipo_match = re.search(r"(\d+\s+ROUNDS?\s+FOR\s+TIME|\d+\s+ROUNDS?|\bAMRAP\b|\bFOR TIME\b|\bEMOM\b|\bROUNDS\b)", line, re.IGNORECASE)
    if tipo_match: t = tipo_match.group(0).strip().upper()
    return t, dur

def parse_partes_do_treino(text, full_text_for_fallback=None):
    partes = {}
    if not text:
        for h in HEADERS: partes[h] = {"nomeWod": None, "tipo": h, "duracaoMinutos": None, "exercicios": [], "observacoes": None}
        return partes

    headers_pattern = "|".join([re.escape(h) for h in HEADERS])
    
    for header in HEADERS:
        pattern = rf"(?i){re.escape(header)}(.*?)(?=(?:{headers_pattern})|$)"
        m = re.search(pattern, text, re.DOTALL)
        
        if not m:
            partes[header.upper()] = {"nomeWod": None, "tipo": header.upper(), "duracaoMinutos": None, "exercicios": [], "observacoes": None}
            continue

        bloco = m.group(1).strip()
        lines = [ln.strip() for ln in bloco.splitlines() if ln.strip()]
        
        nome = None; tipo = None; duracao = None
        if lines:
            header_line = lines[0]
            tipo, duracao = detect_tipo_duracao_from_line(header_line)
            
            if '-' in header_line:
                left, right = [p.strip() for p in header_line.split('-', 1)]
                if any(k in right.upper() for k in ("AMRAP", "FOR TIME", "EMOM", "ROUNDS")): nome = left or None
                else: nome = right or (left or None)
            elif not tipo:
                nome = header_line

        exercicios = []
        start_idx = 1 if len(lines) > 0 else 0
        for ln in lines[start_idx:]:
            if re.match(r'\bOBSERVA(?:C|Ç)AO\b\s*:', ln, re.IGNORECASE) or re.match(r'\bMATERIAL(?:S)?\b\s*:', ln, re.IGNORECASE): continue
            if re.match(r'^\s*(?:\d+\s+ROUNDS?\b|AMRAP\b|FOR TIME\b|EMOM\b|ROUNDS\b)', ln, re.IGNORECASE): continue
            
            if (re.match(r'^\d{1,3}\b.*', ln) or 
                re.search(r'[A-Za-z]+\s*\(.*\d', ln) or 
                re.search(r'\b(KG|Kg|kg|REPS|reps|REP|m\b|metros)\b', ln, re.IGNORECASE)):
                exercicios.append(ln)

        observacoes = extract_observacoes_from_block(bloco)
        
        partes[header.upper()] = {
            "nomeWod": nome.strip() if nome else None, 
            "tipo": tipo or header.upper(), 
            "duracaoMinutos": duracao, 
            "exercicios": exercicios, 
            "observacoes": observacoes
        }

    return partes

# ==============================================================================
# SEÇÃO 2: LÓGICA PRINCIPAL (CONEXÃO COM FIREBASE)
# ==============================================================================

def run_pdf_parser_logic(event):
    """
    Função chamada pelo main.py quando um arquivo sobe no Storage.
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
        
        # 1. Extrai a data string (ex: "02 DEZEMBRO")
        data_str, dia_semana = parse_data_e_dia(normalized_text)
        
        # 2. NOVA LINHA: Converte para ISO (ex: "2026-12-02")
        data_iso = converter_data_para_iso(data_str)

        partes_treino = parse_partes_do_treino(normalized_text, full_text_for_fallback=normalized_text)
        materiais = parse_materiais(normalized_text)

        treino_json = {
            "arquivoFonte": file_path,
            "uploadedBy": user_id,
            "boxId": box_id,
            "criadoEm": firestore.SERVER_TIMESTAMP,
            "dataDoTreinoTexto": data_str,          
            "dataTreinoIso": data_iso, # <--- NOVO CAMPO IMPORTANTE
            "diaDaSemana": dia_semana,
            "materiais": materiais,
            "partes": partes_treino,
            "status": "processado"
        }

        doc_ref = firestore_client.collection("exercises").add(treino_json)
        
        logging.info(f"Treino salvo com sucesso no Firestore. ID: {doc_ref[1].id} | Data ISO: {data_iso}")

    except Exception as e:
        logging.error(f"Erro fatal ao processar {file_path}: {e}")