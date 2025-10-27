#!/bin/bash
# Script para criar ambiente virtual e testar localmente

echo "================================="
echo "🐍 Configurando ambiente Python"
echo "================================="

# Cria ambiente virtual se não existir
if [ ! -d "venv" ]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv venv
fi

# Ativa ambiente virtual
echo "🔌 Ativando ambiente virtual..."
source venv/bin/activate

# Instala dependências
echo "📥 Instalando dependências..."
pip install --upgrade pip
pip install -r ../ml/requirements.txt

echo ""
echo "================================="
echo "🧪 Executando teste local"
echo "================================="

# Executa teste
python3 test_local.py

# Desativa ambiente virtual
deactivate

echo ""
echo "================================="
echo "✅ Teste concluído!"
echo "================================="

