#!/bin/bash
# Configura ambiente Python isolado usando PyPI padrão

echo "================================="
echo "🔧 Configurando ambiente isolado"
echo "================================="

# Remove venv antigo se existir
if [ -d "venv" ]; then
    echo "🗑️  Removendo ambiente virtual antigo..."
    rm -rf venv
fi

# Cria novo ambiente virtual
echo "📦 Criando novo ambiente virtual..."
python3 -m venv venv

# Ativa ambiente virtual
echo "🔌 Ativando ambiente virtual..."
source venv/bin/activate

# Configura pip para usar PyPI padrão (não Fury)
echo "⚙️  Configurando pip para usar PyPI padrão..."
pip config --site set global.index-url https://pypi.org/simple
pip config --site set global.trusted-host pypi.org
pip config --site set global.extra-index-url ""

# Instala dependências
echo "📥 Instalando dependências do PyPI..."
pip install fpgrowth_py pandas

echo ""
echo "================================="
echo "✅ Ambiente configurado!"
echo "================================="
echo ""
echo "Para usar:"
echo "  source venv/bin/activate"
echo "  python3 test_local.py"
echo ""
echo "Para desativar:"
echo "  deactivate"

