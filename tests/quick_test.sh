#!/bin/bash
# Script rápido para testar com dados de exemplo (não precisa do dataset real)

echo "================================="
echo "🚀 TESTE RÁPIDO (dados de exemplo)"
echo "================================="

# Verifica se o ambiente virtual existe
if [ ! -d "venv" ]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv venv
fi

# Ativa ambiente virtual
echo "🔌 Ativando ambiente virtual..."
source venv/bin/activate

# Instala dependências
echo "📥 Instalando dependências..."
pip install --quiet fpgrowth_py pandas

echo ""
echo "================================="
echo "🧪 Executando teste com dados de exemplo"
echo "================================="

# Executa teste
python3 test_with_sample_data.py

EXIT_CODE=$?

# Desativa ambiente virtual
deactivate

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "================================="
    echo "✅ TESTE PASSOU!"
    echo "================================="
    echo ""
    echo "📝 Próximos passos:"
    echo "  1. Build da imagem Docker: cd ../ml && docker build -f Dockerfile.improved -t tassiolucas/tp2-ml:0.7 ."
    echo "  2. Push para DockerHub: docker push tassiolucas/tp2-ml:0.7"
    echo "  3. Deploy no Kubernetes: kubectl apply -f ../k8s/job-ml-improved.yaml"
    echo ""
else
    echo ""
    echo "================================="
    echo "❌ TESTE FALHOU!"
    echo "================================="
    exit 1
fi

