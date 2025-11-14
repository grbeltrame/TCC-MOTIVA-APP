import functions_framework
import re
import fitz  # PyMuPDF
import unicodedata
from google.cloud import firestore, storage

# --- Configuração ---
# O Firestore salvará os dados nesta coleção.
# O ID do documento será a data (ex: '2025-11-03')
TRAINING_COLLECTION = "treinos" 
db = firestore.Client()

# --- Helpers de Parsing (A Lógica Principal) ---

def extract_text_from_pdf(pdf_bytes):
    """Extrai texto limpo de um PDF usando PyMuPDF (fitz)."""
    text = ""
    with fitz.open(stream=pdf_bytes, filetype="pdf") as doc:
        for page in doc:
            text += page.get_text("text") + "\n"
            
    # Normaliza o texto para remover ligaduras estranhas (ex: 'ﬁ' -> 'fi')
    # e limpa espaços extras
    text = unicodedata.normalize("NFKD", text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def parse_data_e_dia(text):
    """Encontra a data e o dia da semana."""
    # Ex: "03 NOVEMBRO | SEGUNDA FEIRA" 
    match = re.search(r"(\d{2}\s+[A-ZÇ]+)\s*\|\s*([A-ZÇ -]+FEIRA)", text)
    if match:
        data_str = match.group(1) # "03 NOVEMBRO"
        dia_str = match.group(2) # "SEGUNDA FEIRA"
        
        # TODO: Você precisará de uma lógica mais robusta para converter
        # "03 NOVEMBRO" em um Timestamp real (usando o ano do upload)
        # Por enquanto, retornamos as strings brutas.
        return data_str, dia_str
    return None, None

def parse_materiais(text):
    """Encontra a lista de materiais."""
    # Ex: "MATERIAL: Munhequeira" 
    match = re.search(r"MATERIAL:\s*(.*)", text)
    if match:
        materiais_str = match.group(1).strip()
        # Assume que materiais são separados por vírgula ou "e"
        return re.split(r',|\s+e\s+', materiais_str)
    return []

def parse_partes_do_treino(text):
    """
    O coração do parser.
    Encontra todos os blocos (WARM UP, WOD, etc.) e os analisa.
    """
    partes = {}
    
    # Define os cabeçalhos que queremos procurar
    # O 'WOD' vem por último, pois sua observação é longa [cite: 20-23]
    headers = ["WARM UP", "EXTRA TRAINING", "SKILL", "WOD"]
    
    # Regex para encontrar os blocos
    # Um bloco começa com um header e termina no próximo header
    # (?!...) é um "negative lookahead" para garantir que não peguemos o próximo header
    for i, header in enumerate(headers):
        # Tenta encontrar o bloco de texto para este header
        # Ex: WARM UP-AMRAP (5') [cite: 3]
        # Ex: SKILL-POWER CLEAN [cite: 13]
        # Ex: WOD-IN NAME OF GODS AMRAP (12') 
        pattern = rf"{header}(.*?)(?=" + "|".join(headers[i+1:]) + r"|$)"
        match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
        
        if not match:
            continue
            
        bloco_texto = match.group(1).strip()
        parte_json = {}

        # 1. Encontra Nome, Tipo e Duração
        # Ex: "-AMRAP (5')" [cite: 3]
        # Ex: "-IN NAME OF GODS AMRAP (12')" 
        header_match = re.search(r"-(.*?)(AMRAP|FOR TIME|EMOM|ROUNDS.*?)\s*\((\d+)'\)", bloco_texto)
        if header_match:
            parte_json["nomeWod"] = header_match.group(1).strip("- ") or None
            parte_json["tipo"] = header_match.group(2).strip()
            parte_json["duracaoMinutos"] = int(header_match.group(3))
        else:
            # Fallback para blocos sem tipo/duração (ex: SKILL)
            # Ex: "-POWER CLEAN" [cite: 13]
            header_match_simple = re.search(r"-(.*)", bloco_texto)
            if header_match_simple:
                parte_json["nomeWod"] = header_match_simple.group(1).strip()
            parte_json["tipo"] = header.upper() # Usa o próprio header como tipo (ex: "SKILL")
            parte_json["duracaoMinutos"] = None
        
        # Limpa o nome do WOD se for vazio
        if parte_json.get("nomeWod") == "":
            parte_json["nomeWod"] = None

        # 2. Encontra Exercícios
        # Ex: "05 Muscle clean" [cite: 4]
        # Ex: "09 Power clean (80Kg|55Kg)" [cite: 16]
        exercicios = re.findall(r"(\d{2,}\s?m?\s+[^\d\n]+(?:\(.*\))?)", bloco_texto)
        # Limpa os exercícios encontrados
        parte_json["exercicios"] = [ex.strip() for ex in exercicios if "OBSERVAÇÃO" not in ex and "MATERIAL" not in ex]

        # 3. Encontra Observações
        # Ex: "OBSERVAÇÃO: WOD extremamente pesado..." [cite: 20-21]
        obs_match = re.search(r"OBSERVAÇÃO:\s*(.*)", bloco_texto, re.IGNORECASE | re.DOTALL)
        if obs_match:
            # Pega tudo até o fim do bloco
            parte_json["observacoes"] = obs_match.group(1).strip()
        else:
            parte_json["observacoes"] = None
            
        # Adiciona a parte ao JSON final
        # O nome da chave é o header (ex: "WARM UP")
        partes[header.upper()] = parte_json
        
    return partes

# --- A Cloud Function ---

@functions_framework.cloud_event
def parse_training_pdf(cloud_event):
    """
    Função acionada pelo Cloud Storage.
    Lê o PDF, o transforma em JSON e o salva no Firestore.
    """
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    # 1. Baixar o PDF do Storage
    blob = bucket.blob(file_name)
    pdf_bytes = blob.download_as_bytes()
    
    # 2. Extrair o texto
    print(f"Iniciando parsing do arquivo: {file_name}")
    raw_text = extract_text_from_pdf(pdf_bytes)

    # --- 3. Obter dados dinâmicos (Box ID e Data) ---
    #
    # IMPORTANTE: Você DEVE passar o ID do Box e a Data do Treino.
    # O PDF não tem o ano. O Box ID "box_olympus_crossfit" é um exemplo.
    #
    # A melhor forma é passar via METADADOS do Storage no upload do Flutter.
    # Por enquanto, vamos usar valores fixos do seu JSON de exemplo
    # e do PDF.
    
    # Tenta ler os metadados do arquivo (MÉTODO RECOMENDADO)
    blob.reload() # Recarrega para obter metadados
    metadata = blob.metadata or {}
    
    # O 'boxId' DEVE ser enviado do Flutter como metadado
    box_id = metadata.get("boxId", "box_olympus_crossfit") # Fallback para o seu exemplo
    
    # A 'data' (com ano) DEVE ser enviada do Flutter
    # Vamos usar um fallback, mas ISSO PRECISA SER AJUSTADO
    data_upload_str = metadata.get("data", "2025-11-03") # Fallback
    
    try:
        # Converte a data para um Timestamp
        # (O Firestore precisa de um objeto datetime)
        from datetime import datetime
        data_timestamp = firestore.Timestamp.from_datetime(
            datetime.strptime(data_upload_str, "%Y-%m-%d")
        )
        # O ID do documento será a data no formato YYYY-MM-DD
        doc_id = data_upload_str
    except Exception as e:
        print(f"Erro ao converter data, usando data de hoje: {e}")
        data_timestamp = firestore.Timestamp.now()
        doc_id = data_timestamp.strftime("%Y-%m-%d")


    # 4. Montar o JSON final
    print("Montando o JSON...")
    data_pdf, dia_semana_pdf = parse_data_e_dia(raw_text)
    
    json_output = {
        "boxId": box_id,
        "data": data_timestamp, # Usando a data dos metadados (com ano)
        "diaDaSemana": dia_semana_pdf or "Dia não encontrado", # "SEGUNDA FEIRA" 
        "materiais": parse_materiais(raw_text), # ["Munhequeira"] 
        "partesDoTreino": parse_partes_do_treino(raw_text) # Mapa com WARM UP, WOD, etc.
    }

    # 5. Salvar no Firestore
    try:
        doc_ref = db.collection(TRAINING_COLLECTION).document(doc_id)
        doc_ref.set(json_output)
        print(f"Sucesso! Treino salvo no Firestore com ID: {doc_id}")
    except Exception as e:
        print(f"Erro ao salvar no Firestore: {e}")
        raise