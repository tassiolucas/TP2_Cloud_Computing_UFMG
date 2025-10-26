import pandas as pd
from fpgrowth_py import fpgrowth
import pickle
import os

DATA_PATH = "/app/2023_spotify_ds1.csv"  # dataset (você pode ajustar o path depois)
OUTPUT_PATH = "/data/model.pkl"

def main():
    if not os.path.exists(DATA_PATH):
        print(f"⚠️ Dataset não encontrado em {DATA_PATH}")
        # usa dataset de exemplo
        itemSetList = [
            ['rock', 'pop'],
            ['rock', 'metal'],
            ['pop', 'dance'],
            ['metal', 'rock'],
        ]
    else:
        df = pd.read_csv(DATA_PATH)
        # aqui você adaptaria o dataset real -> lista de playlists
        itemSetList = df['songs'].apply(lambda x: x.split(','))  # exemplo

    freqItemSet, rules = fpgrowth(itemSetList, minSupRatio=0.5, minConf=0.5)
    print(f"✅ Regras geradas: {len(rules)}")

    os.makedirs("/data", exist_ok=True)
    with open(OUTPUT_PATH, "wb") as f:
        pickle.dump(rules, f)
    print(f"✅ Modelo salvo em {OUTPUT_PATH}")

if __name__ == "__main__":
    main()
