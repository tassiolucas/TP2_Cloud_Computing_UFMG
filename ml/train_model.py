#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
train_model.py
Gera o modelo de recomendação baseado em regras de associação (FPGrowth)
usando o dataset real do Spotify (/home/datasets/spotify/2023_spotify_ds1.csv)
e salva o resultado em /data/model.pkl (volume compartilhado).
"""

import os
import pandas as pd
import pickle
from ast import literal_eval
from fpgrowth_py import fpgrowth


# Caminhos configuráveis
DATA_PATH = os.getenv("DATA_PATH", "/home/datasets/spotify/2023_spotify_ds1.csv")
OUTPUT_PATH = os.getenv("OUTPUT_PATH", "/data/model.pkl")


def load_playlist_data(data_path: str):
    """Carrega o dataset e transforma cada playlist em lista de músicas"""
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"Dataset não encontrado em {data_path}")

    print(f"✅ Dataset encontrado em {data_path}")
    df = pd.read_csv(data_path)
    print(f"🧾 Colunas disponíveis: {list(df.columns)}")

    # Tenta encontrar automaticamente uma coluna que contenha as músicas
    song_col = None
    for c in df.columns:
        if 'song' in c.lower() or 'track' in c.lower():
            song_col = c
            break

    if not song_col:
        raise ValueError("❌ Nenhuma coluna relacionada a músicas ('song' ou 'track') encontrada no dataset.")

    print(f"🎵 Usando coluna '{song_col}' para extrair playlists...")

    itemSetList = []
    total_rows = len(df)
    for i, entry in enumerate(df[song_col].dropna()):
        try:
            # Converte string JSON-like para lista real
            songs = literal_eval(entry) if isinstance(entry, str) else entry
            if isinstance(songs, (list, tuple)) and songs:
                # Normaliza nomes (remove espaços, converte para str)
                songs = [str(s).strip() for s in songs if s]
                itemSetList.append(songs)
        except Exception:
            continue

        if (i + 1) % 10000 == 0:
            print(f"📦 Processadas {i+1}/{total_rows} playlists...")

    print(f"📚 Total de playlists válidas: {len(itemSetList)}")
    if len(itemSetList) == 0:
        raise ValueError("❌ Nenhuma playlist válida encontrada após processamento!")

    return itemSetList


def main():
    print("🚀 Iniciando geração do modelo de recomendação Spotify...")

    try:
        itemSetList = load_playlist_data(DATA_PATH)
    except Exception as e:
        print(f"⚠️ Erro ao processar dataset real: {e}")
        print("⚠️ Caindo para dados fictícios para garantir execução.\n")
        itemSetList = [
            ['rock', 'pop'],
            ['rock', 'metal'],
            ['pop', 'dance'],
            ['metal', 'rock'],
        ]

    print("📊 Iniciando FPGrowth (minSupRatio=0.5, minConf=0.5)...")
    try:
        freqItemSet, rules = fpgrowth(itemSetList, minSupRatio=0.5, minConf=0.5)
        if not rules:
            print("⚠️ Nenhuma regra gerada, dataset pode estar muito disperso.")
    except Exception as e:
        print(f"❌ Erro durante geração de regras: {e}")
        rules = []

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "wb") as f:
        pickle.dump(rules, f)

    print(f"💾 Modelo salvo com sucesso em {OUTPUT_PATH}")
    print(f"✅ Total de regras geradas: {len(rules)}")
    print("🏁 Treinamento concluído.")


if __name__ == "__main__":
    main()
