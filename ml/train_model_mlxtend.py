#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
train_model_mlxtend.py - Versão usando mlxtend (mais eficiente)
"""

import os
import pandas as pd
import pickle
from datetime import datetime
from mlxtend.frequent_patterns import fpgrowth, association_rules
from mlxtend.preprocessing import TransactionEncoder

# Configurações
DATA_PATH = os.getenv("DATA_PATH", "/home/datasets/spotify/2023_spotify_ds1.csv")
OUTPUT_PATH = os.getenv("OUTPUT_PATH", "/data/model.pkl")
MAX_PLAYLISTS = int(os.getenv("MAX_PLAYLISTS", "50000"))
MIN_SUP = float(os.getenv("MIN_SUP_RATIO", "0.02"))
MIN_CONF = float(os.getenv("MIN_CONF", "0.5"))

def load_playlist_data(data_path: str, max_playlists=None):
    """Carrega dataset e prepara para mlxtend."""
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"Dataset não encontrado em {data_path}")

    print(f"✅ Dataset: {data_path}")
    df = pd.read_csv(data_path, usecols=['pid', 'track_uri'], 
                     nrows=max_playlists * 20 if max_playlists else None)
    
    print(f"📊 Linhas carregadas: {len(df)}")
    
    # Agrupa por playlist
    grouped = df.groupby("pid")["track_uri"].apply(list)
    
    if max_playlists and len(grouped) > max_playlists:
        grouped = grouped.head(max_playlists)
    
    itemSetList = grouped.tolist()
    print(f"📚 Playlists: {len(itemSetList)}")
    
    return itemSetList

def main():
    start_time = datetime.now()
    print("=" * 80)
    print("🚀 Treinamento com mlxtend (mais eficiente)")
    print(f"🕐 Início: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    # Carrega dados
    itemSetList = load_playlist_data(DATA_PATH, max_playlists=MAX_PLAYLISTS)
    
    # Transforma para formato mlxtend
    print("\n📊 Transformando dados...")
    te = TransactionEncoder()
    te_ary = te.fit(itemSetList).transform(itemSetList)
    df = pd.DataFrame(te_ary, columns=te.columns_)
    
    print(f"📊 Matriz: {df.shape[0]} playlists x {df.shape[1]} músicas únicas")
    
    # FPGrowth
    print(f"\n⏳ Executando FPGrowth (min_support={MIN_SUP})...")
    frequent_itemsets = fpgrowth(df, min_support=MIN_SUP, use_colnames=True)
    print(f"✅ Itemsets frequentes: {len(frequent_itemsets)}")
    
    # Gera regras
    print(f"\n⏳ Gerando regras (min_confidence={MIN_CONF})...")
    rules = association_rules(frequent_itemsets, metric="confidence", 
                              min_threshold=MIN_CONF, num_itemsets=len(frequent_itemsets))
    print(f"✅ Regras geradas: {len(rules)}")
    
    # Converte para formato compatível
    rules_list = []
    for _, row in rules.iterrows():
        rules_list.append([
            row['antecedents'],
            row['consequents'], 
            row['confidence']
        ])
    
    # Salva
    print(f"\n💾 Salvando em {OUTPUT_PATH}...")
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    
    model_data = {
        'rules': rules_list,
        'metadata': {
            'created_at': datetime.now().isoformat(),
            'num_playlists': len(itemSetList),
            'num_rules': len(rules_list),
            'min_sup': MIN_SUP,
            'min_conf': MIN_CONF,
        }
    }
    
    with open(OUTPUT_PATH, "wb") as f:
        pickle.dump(model_data, f)
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    print("\n" + "=" * 80)
    print("🏁 CONCLUÍDO!")
    print(f"⏱️  Duração: {duration:.2f}s ({duration/60:.2f} min)")
    print(f"📊 Regras: {len(rules_list)}")
    print("=" * 80)

if __name__ == "__main__":
    main()

