import pickle
import os
import time
from flask import Flask, jsonify, request

MODEL_PATH = "/data/model.pkl"

app = Flask(__name__)
app.model = None
app.model_mtime = None

def load_model():
    """Carrega o modelo treinado do disco."""
    global app
    if not os.path.exists(MODEL_PATH):
        print("⚠️ Modelo ainda não encontrado em /data/model.pkl")
        return

    try:
        app.model = pickle.load(open(MODEL_PATH, "rb"))
        app.model_mtime = os.path.getmtime(MODEL_PATH)
        print("✅ Modelo carregado com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao carregar modelo: {e}")
        app.model = None

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

    # 🔹 Exemplo: usa as regras do modelo (lista de tuplas) para sugerir músicas
    recs = set()
    for rule in app.model:
        antecedent, consequent, confidence = rule
        if any(song in antecedent for song in songs):
            recs.update(consequent)

    return jsonify({
        "songs": list(recs) or ["Sem recomendações"],
        "version": "0.9",
        "model_date": time.strftime("%Y-%m-%d", time.gmtime(app.model_mtime or time.time()))
    })

if __name__ == "__main__":
    load_model()
    app.run(host="0.0.0.0", port=50028)
