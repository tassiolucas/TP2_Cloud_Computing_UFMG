#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_full_fast.py - Teste rápido com dataset completo mas parâmetros mais restritivos
"""

import os
import sys
import tempfile

# Dataset local no diretório tests/
script_dir = os.path.dirname(os.path.abspath(__file__))
dataset_local = os.path.join(script_dir, "2023_spotify_ds1.csv")

# Parâmetros mais restritivos para execução rápida
os.environ["DATA_PATH"] = dataset_local
os.environ["MAX_PLAYLISTS"] = "999999999"  # Sem limite de playlists
os.environ["MIN_SUP_RATIO"] = "0.05"  # Mais restritivo = mais rápido
os.environ["MIN_CONF"] = "0.6"

# Cria diretório temporário para output
temp_dir = tempfile.mkdtemp()
output_path = os.path.join(temp_dir, "model.pkl")
os.environ["OUTPUT_PATH"] = output_path

print("=" * 80)
print("🧪 TESTE RÁPIDO COM DATASET COMPLETO")
print("=" * 80)
print(f"📂 Dataset: {dataset_local}")

if not os.path.exists(dataset_local):
    print(f"\n❌ Dataset não encontrado em: {dataset_local}")
    sys.exit(1)

print(f"📂 Diretório temporário: {temp_dir}")
print(f"💾 Modelo será salvo em: {output_path}")
print("⚡ Usando parâmetros mais restritivos para execução rápida")
print("=" * 80)

# Importa e executa o treinamento
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
            print(f"\n📊 Número de regras: {len(model_data.get('rules', []))}")
        else:
            print(f"\n📊 Número de regras: {len(model_data)}")
        
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
        print(f"\n🧹 Limpando diretório temporário: {temp_dir}")
        shutil.rmtree(temp_dir)

