import pickle
import os
import time
from flask import Flask, jsonify, request

MODEL_PATH = "/data/model.pkl"

app = Flask(__name__)
app.model = None
app.model_metadata = {}
app.model_mtime = None

def load_model():
    """Carrega o modelo treinado do disco."""
    global app
    if not os.path.exists(MODEL_PATH):
        print("⚠️ Modelo ainda não encontrado em /data/model.pkl")
        return

    try:
        model_data = pickle.load(open(MODEL_PATH, "rb"))
        
        # Suporta ambos os formatos (com e sem metadados)
        if isinstance(model_data, dict):
            app.model = model_data.get('rules', [])
            app.model_metadata = model_data.get('metadata', {})
            print(f"✅ Modelo carregado com sucesso! ({len(app.model)} regras)")
            print(f"📊 Metadados: {app.model_metadata}")
        else:
            # Formato antigo (lista de regras diretamente)
            app.model = model_data
            app.model_metadata = {}
            print(f"✅ Modelo carregado (formato antigo) com {len(app.model)} regras")
        
        app.model_mtime = os.path.getmtime(MODEL_PATH)
    except Exception as e:
        print(f"❌ Erro ao carregar modelo: {e}")
        import traceback
        traceback.print_exc()
        app.model = None
        app.model_metadata = {}

def check_model_update():
    """Verifica se o modelo foi atualizado no volume compartilhado."""
    if not os.path.exists(MODEL_PATH):
        return
    mtime = os.path.getmtime(MODEL_PATH)
    if app.model_mtime is None or mtime > app.model_mtime:
        print("🔁 Detected new model version, reloading...")
        load_model()

@app.route("/healthz")
def health():
    check_model_update()
    return jsonify({"status": "ok"})

@app.route("/api/songs", methods=["GET"])
def list_songs():
    """Lista exemplos de músicas no modelo (primeiras 50 únicas)."""
    check_model_update()
    
    if app.model is None:
        return jsonify({
            "error": "Modelo não carregado ainda",
            "songs": []
        }), 503
    
    # Coleta músicas únicas dos antecedentes e consequentes
    songs_set = set()
    for rule in app.model[:200]:  # Limita a 200 regras para não sobrecarregar
        try:
            if len(rule) >= 2:
                antecedent = rule[0] if isinstance(rule[0], (set, list, tuple)) else set()
                consequent = rule[1] if isinstance(rule[1], (set, list, tuple)) else set()
                songs_set.update(antecedent)
                songs_set.update(consequent)
                
                # Para quando tiver 50 exemplos
                if len(songs_set) >= 50:
                    break
        except:
            continue
    
    return jsonify({
        "total_rules": len(app.model),
        "example_songs": sorted(list(songs_set))[:50],
        "note": "Primeiras 50 músicas únicas encontradas no modelo"
    })

def normalize_song(song):
    """Normaliza nome de música para matching case-insensitive."""
    if isinstance(song, str):
        return song.lower().strip()
    return song

@app.route("/api/recommend", methods=["POST"])
def recommend():
    check_model_update()
    data = request.get_json()
    songs = data.get("songs", [])

    if app.model is None:
        return jsonify({
            "error": "Modelo não carregado ainda",
            "songs": []
        }), 503

    # Normaliza as músicas de entrada
    songs_normalized = [normalize_song(s) for s in songs]
    
    # 🔹 Exemplo: usa as regras do modelo (lista de tuplas) para sugerir músicas
    recs = set()
    for rule in app.model:
        try:
            # Tenta desempacotar (formato esperado: tupla de 3 elementos)
            if len(rule) == 3:
                antecedent, consequent, confidence = rule
            elif len(rule) == 4:
                # Formato alternativo com support
                antecedent, consequent, confidence, support = rule
            else:
                # Fallback: assume que os 2 primeiros são antecedente e consequente
                antecedent = rule[0] if len(rule) > 0 else set()
                consequent = rule[1] if len(rule) > 1 else set()
            
            # Normaliza antecedent e consequent para matching
            antecedent_normalized = {normalize_song(s) for s in antecedent}
            
            # Verifica se alguma música da entrada está no antecedente (case-insensitive)
            if any(song_norm in antecedent_normalized for song_norm in songs_normalized):
                recs.update(consequent)
        except Exception as e:
            # Ignora regras mal formatadas
            print(f"⚠️ Regra ignorada (formato inválido): {rule[:100]}... - Erro: {e}")
            continue

    # Extrai data do modelo dos metadados se disponível
    if app.model_metadata and 'created_at' in app.model_metadata:
        model_date = app.model_metadata['created_at'].split('T')[0]
    else:
        model_date = time.strftime("%Y-%m-%d", time.gmtime(app.model_mtime or time.time()))
    
    return jsonify({
        "songs": list(recs) or ["Sem recomendações"],
        "version": "1.1",
        "model_date": model_date,
        "num_rules": len(app.model) if app.model else 0,
        "num_playlists": app.model_metadata.get('num_playlists', 'unknown')
    })

if __name__ == "__main__":
    load_model()
    app.run(host="0.0.0.0", port=50028)
