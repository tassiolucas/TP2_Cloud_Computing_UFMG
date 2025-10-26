import pandas as pd
from fpgrowth_py import fpgrowth
import pickle
import os

DATA_PATH = "/home/datasets/spotify/2023_spotify_ds1.csv"
OUTPUT_PATH = "/data/model.pkl"

def main():
    print("🚀 Iniciando geração do modelo de recomendação Spotify...")

    if not os.path.exists(DATA_PATH):
        print(f"⚠️ Dataset real NÃO encontrado em {DATA_PATH}")
        print("⚠️ Atenção: NÃO estamos treinando com as tabelas reais do Spotify.")
        print("⚠️ Usando dados fictícios apenas para validar execução e geração do modelo.\n")

        # Dados mockados para testes locais
        itemSetList = [
            ['rock', 'pop'],
            ['rock', 'metal'],
            ['pop', 'dance'],
            ['metal', 'rock'],
        ]
    else:
        print(f"✅ Dataset encontrado em {DATA_PATH}")
        print("📦 Carregando playlists e gerando regras de associação...")

        try:
            df = pd.read_csv(DATA_PATH)
            if 'songs' not in df.columns:
                print("⚠️ Coluna 'songs' não encontrada — adaptando dataset.")
                print("⚠️ Este modelo pode não representar corretamente os dados reais.\n")
                df['songs'] = df[df.columns[0]]  # tenta usar a primeira coluna
            itemSetList = df['songs'].astype(str).apply(lambda x: x.split(',')).tolist()
        except Exception as e:
            print(f"❌ Erro ao ler dataset: {e}")
            print("⚠️ Caindo para dados de exemplo.\n")
            itemSetList = [
                ['rock', 'pop'],
                ['rock', 'metal'],
                ['pop', 'dance'],
                ['metal', 'rock'],
            ]

    # Geração das regras de associação
    freqItemSet, rules = fpgrowth(itemSetList, minSupRatio=0.5, minConf=0.5)
    print(f"✅ Regras geradas: {len(rules)}")

    # Salvando o modelo
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "wb") as f:
        pickle.dump(rules, f)
    print(f"💾 Modelo salvo em {OUTPUT_PATH}")

    print("\n🏁 Treinamento concluído.")
    print("ℹ️ Observação: se o dataset original foi encontrado, o modelo é real.")
    print("ℹ️ Caso contrário, os dados utilizados são fictícios apenas para teste.")

if __name__ == "__main__":
    main()
