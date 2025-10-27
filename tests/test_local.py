#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_local.py - Script para testar o treinamento localmente
"""

import os
import sys
import tempfile

# Configura variáveis de ambiente para teste local
os.environ["DATA_PATH"] = "/home/datasets/spotify/2023_spotify_ds1.csv"
os.environ["MAX_PLAYLISTS"] = "1000"  # Limita para teste rápido
os.environ["MIN_SUP_RATIO"] = "0.02"  # Mais restritivo para gerar menos regras
os.environ["MIN_CONF"] = "0.5"

# Cria diretório temporário para output
temp_dir = tempfile.mkdtemp()
output_path = os.path.join(temp_dir, "model.pkl")
os.environ["OUTPUT_PATH"] = output_path

print("=" * 80)
print("🧪 TESTE LOCAL DO MODELO DE TREINAMENTO")
print("=" * 80)
print(f"📂 Diretório temporário: {temp_dir}")
print(f"💾 Modelo será salvo em: {output_path}")
print("=" * 80)

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

