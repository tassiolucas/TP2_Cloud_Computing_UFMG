#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_with_sample_data.py - Teste com dados de exemplo (sem precisar do dataset real)
"""

import os
import sys
import tempfile
import pandas as pd

print("=" * 80)
print("🧪 TESTE COM DADOS DE EXEMPLO (SEM DATASET REAL)")
print("=" * 80)

# Cria um dataset de exemplo no formato correto
sample_data = {
    'pid': [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5] * 100,  # 1500 linhas
    'track_uri': [
        'spotify:track:rock1', 'spotify:track:pop1', 'spotify:track:jazz1',
        'spotify:track:rock1', 'spotify:track:metal1', 'spotify:track:blues1',
        'spotify:track:pop1', 'spotify:track:dance1', 'spotify:track:electronic1',
        'spotify:track:metal1', 'spotify:track:rock1', 'spotify:track:punk1',
        'spotify:track:jazz1', 'spotify:track:blues1', 'spotify:track:soul1',
    ] * 100,
    'track_name': [
        'Rock Song 1', 'Pop Song 1', 'Jazz Song 1',
        'Rock Song 1', 'Metal Song 1', 'Blues Song 1',
        'Pop Song 1', 'Dance Song 1', 'Electronic Song 1',
        'Metal Song 1', 'Rock Song 1', 'Punk Song 1',
        'Jazz Song 1', 'Blues Song 1', 'Soul Song 1',
    ] * 100
}

# Cria diretório temporário
temp_dir = tempfile.mkdtemp()
dataset_path = os.path.join(temp_dir, "sample_dataset.csv")
output_path = os.path.join(temp_dir, "model.pkl")

print(f"📂 Diretório temporário: {temp_dir}")
print(f"📊 Criando dataset de exemplo: {dataset_path}")

# Salva dataset de exemplo
df = pd.DataFrame(sample_data)
df.to_csv(dataset_path, index=False)

print(f"✅ Dataset criado com {len(df)} linhas e {df['pid'].nunique()} playlists")
print("=" * 80)

# Configura variáveis de ambiente
os.environ["DATA_PATH"] = dataset_path
os.environ["OUTPUT_PATH"] = output_path
os.environ["MAX_PLAYLISTS"] = "500"
os.environ["MIN_SUP_RATIO"] = "0.1"
os.environ["MIN_CONF"] = "0.5"

# Importa e executa o treinamento
# Adiciona o diretório ml/ ao path (um nível acima do diretório tests/)
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(project_root, 'ml'))

try:
    from train_model_improved import main
    main()
    
    # Verifica se o modelo foi criado
    if os.path.exists(output_path):
        print("\n" + "=" * 80)
        print("✅ TESTE CONCLUÍDO COM SUCESSO!")
        print(f"📊 Tamanho do arquivo: {os.path.getsize(output_path) / 1024:.2f} KB")
        
        # Tenta carregar o modelo
        import pickle
        with open(output_path, 'rb') as f:
            model_data = pickle.load(f)
        
        if isinstance(model_data, dict):
            print("\n📋 Metadados do modelo:")
            for key, value in model_data.get('metadata', {}).items():
                print(f"  • {key}: {value}")
            
            rules = model_data.get('rules', [])
            print(f"\n📊 Número de regras: {len(rules)}")
            
            if rules:
                print("\n🔍 Exemplos de regras (primeiras 3):")
                for i, rule in enumerate(rules[:3]):
                    antecedent, consequent, confidence = rule
                    print(f"  {i+1}. {list(antecedent)[:2]}... → {list(consequent)[:2]}... (conf: {confidence:.3f})")
        else:
            print(f"\n📊 Número de regras: {len(model_data)}")
        
        print("=" * 80)
        print("\n✨ O código está funcionando corretamente!")
        print("💡 Agora você pode testar com o dataset real do cluster.")
        print("=" * 80)
    else:
        print("\n❌ ERRO: Modelo não foi criado!")
        sys.exit(1)
        
except Exception as e:
    print(f"\n❌ ERRO NO TESTE: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
finally:
    # Limpeza
    import shutil
    if os.path.exists(temp_dir):
        print(f"\n🧹 Limpando diretório temporário...")
        shutil.rmtree(temp_dir)

