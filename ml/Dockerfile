# Dockerfile - ML Training (Production Version)
FROM python:3.9-slim

WORKDIR /app

# Copia arquivos necessários
COPY train_model_improved.py /app/train_model.py
COPY requirements.txt /app/requirements.txt

# Instala dependências
RUN pip install --no-cache-dir -r requirements.txt

# Cria o diretório de volume (para o PVC)
VOLUME ["/data"]

# Define variáveis de ambiente padrão (podem ser sobrescritas no Kubernetes)
ENV MAX_PLAYLISTS=999999999 \
    MIN_SUP_RATIO=0.05 \
    MIN_CONF=0.6 \
    DATA_PATH=/home/datasets/spotify/2023_spotify_ds1.csv \
    OUTPUT_PATH=/data/model.pkl

# Executa o script
CMD ["python", "-u", "train_model.py"]

