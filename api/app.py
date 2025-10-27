import pickle
from flask import Flask, jsonify, request

app = Flask(__name__)

try:
    app.model = pickle.load(open("/data/model.pkl", "rb"))
    print("✅ Modelo carregado com sucesso!")
except Exception as e:
    print(f"⚠️ Erro ao carregar modelo: {e}")
    app.model = None

@app.route("/healthz")
def health():
    return jsonify({"status": "ok"})

@app.route("/api/recommend", methods=["POST"])
def recommend():
    data = request.get_json()
    songs = data.get("songs", [])
    # Exemplo de recomendação simples
    recs = ["Imagine", "Bohemian Rhapsody"]  
    return jsonify({
        "songs": recs,
        "version": "0.2",
        "model_date": "2025-10-26"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=50028)
