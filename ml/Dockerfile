# Dockerfile.ml
FROM python:3.9-slim

WORKDIR /app

# copia o script de treinamento
COPY train_model.py /app/train_model.py

# instala dependências
RUN pip install fpgrowth_py pandas

# cria o diretório de volume (para o PVC)
VOLUME ["/data"]

# executa o script
CMD ["python", "train_model.py"]
