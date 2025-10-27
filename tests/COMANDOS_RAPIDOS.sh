#!/bin/bash
# Comandos rápidos para deploy e monitoramento do TP2

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="tassioalmeida"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detecta Docker
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
    DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"
else
    echo -e "${RED}❌ Docker não encontrado!${NC}"
    echo "Instale Docker Desktop ou adicione ao PATH"
    exit 1
fi

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}🚀 TP2 Cloud Computing - Deploy${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Função para extrair versão atual do YAML
get_version() {
    local file=$1
    local image_name=$2
    
    version=$(grep "image: ${image_name}" "$file" | awk -F: '{print $NF}' | tr -d ' ')
    echo "$version"
}

# Função para build e push ML
build_ml() {
    echo -e "${YELLOW}📦 Building ML Docker image...${NC}"
    
    # Extrai versão do YAML
    ML_VERSION=$(get_version "$PROJECT_ROOT/k8s/job-ml.yaml" "tassiolucas/tp2-ml")
    
    echo -e "${BLUE}Versão: ${ML_VERSION}${NC}"
    echo ""
    
    # Build
    cd "$PROJECT_ROOT/ml/"
    $DOCKER_CMD build -f Dockerfile.improved -t tassiolucas/tp2-ml:${ML_VERSION} .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build ML failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Build ML successful${NC}"
    
    # Push
    echo -e "${YELLOW}🚀 Pushing ML to DockerHub...${NC}"
    $DOCKER_CMD push tassiolucas/tp2-ml:${ML_VERSION}
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Push ML failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Push ML successful (tassiolucas/tp2-ml:${ML_VERSION})${NC}"
}

# Função para build e push API
build_api() {
    echo -e "${YELLOW}📦 Building API Docker image...${NC}"
    
    # Extrai versão do YAML
    API_VERSION=$(get_version "$PROJECT_ROOT/k8s/deployment.yaml" "tassiolucas/tp2-api")
    
    echo -e "${BLUE}Versão: ${API_VERSION}${NC}"
    echo ""
    
    # Build
    cd "$PROJECT_ROOT/api/"
    $DOCKER_CMD build -t tassiolucas/tp2-api:${API_VERSION} .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build API failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Build API successful${NC}"
    
    # Push
    echo -e "${YELLOW}🚀 Pushing API to DockerHub...${NC}"
    $DOCKER_CMD push tassiolucas/tp2-api:${API_VERSION}
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Push API failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Push API successful (tassiolucas/tp2-api:${API_VERSION})${NC}"
}

# Função para commit e push
git_commit_push() {
    echo -e "${YELLOW}📤 Fazendo commit e push...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Verifica se há mudanças
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  Nenhuma mudança para commitar${NC}"
        return
    fi
    
    git add k8s/job-ml.yaml k8s/deployment.yaml
    
    # Pega versões atuais
    ML_VERSION=$(get_version "$PROJECT_ROOT/k8s/job-ml.yaml" "tassiolucas/tp2-ml")
    API_VERSION=$(get_version "$PROJECT_ROOT/k8s/deployment.yaml" "tassiolucas/tp2-api")
    
    git commit -m "chore: update images ML:${ML_VERSION} API:${API_VERSION}"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Commit failed${NC}"
        exit 1
    fi
    
    git push origin main
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Push failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Commit e push realizados${NC}"
    echo -e "${BLUE}ArgoCD vai detectar mudanças e fazer deploy automático${NC}"
}

# Função para deploy local (sem ArgoCD)
deploy() {
    echo -e "${YELLOW}🔄 Deploying to Kubernetes (local)...${NC}"
    
    # Deletar job antigo
    kubectl -n $NAMESPACE delete job tp2-ml-job 2>/dev/null || true
    
    # Aplicar novo job
    kubectl -n $NAMESPACE apply -f "$PROJECT_ROOT/k8s/job-ml.yaml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deployment successful${NC}"
        echo ""
        echo -e "${YELLOW}⏳ Waiting for pod to start...${NC}"
        sleep 5
        kubectl -n $NAMESPACE get pods
    else
        echo -e "${RED}❌ Deployment failed${NC}"
        exit 1
    fi
}

# Função para monitorar
monitor() {
    echo -e "${YELLOW}📊 Monitoring pod...${NC}"
    
    POD_NAME=$(kubectl -n $NAMESPACE get pods -l job-name=tp2-ml-job -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$POD_NAME" ]; then
        echo -e "${RED}❌ Pod not found${NC}"
        echo -e "${YELLOW}Available pods:${NC}"
        kubectl -n $NAMESPACE get pods
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found pod: $POD_NAME${NC}"
    echo -e "${YELLOW}📋 Following logs...${NC}"
    echo ""
    kubectl -n $NAMESPACE logs -f $POD_NAME
}

# Função para verificar status
status() {
    echo -e "${YELLOW}📊 Checking status...${NC}"
    echo ""
    
    echo -e "${BLUE}Jobs:${NC}"
    kubectl -n $NAMESPACE get jobs
    echo ""
    
    echo -e "${BLUE}Pods:${NC}"
    kubectl -n $NAMESPACE get pods
    echo ""
    
    echo -e "${BLUE}PVC:${NC}"
    kubectl -n $NAMESPACE get pvc
    echo ""
}

# Função para verificar modelo
check_model() {
    echo -e "${YELLOW}🔍 Checking model in PVC...${NC}"
    
    API_POD=$(kubectl -n $NAMESPACE get pods -l app=tp2-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$API_POD" ]; then
        echo -e "${RED}❌ API pod not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found API pod: $API_POD${NC}"
    echo ""
    echo -e "${BLUE}Contents of /data/:${NC}"
    kubectl -n $NAMESPACE exec -it $API_POD -- ls -lh /data/
}

# Função para testar API
test_api() {
    echo -e "${YELLOW}🧪 Testing API...${NC}"
    
    API_POD=$(kubectl -n $NAMESPACE get pods -l app=tp2-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$API_POD" ]; then
        echo -e "${RED}❌ API pod not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found API pod: $API_POD${NC}"
    echo -e "${YELLOW}📤 Sending test request...${NC}"
    echo ""
    
    kubectl -n $NAMESPACE exec -it $API_POD -- curl -X POST \
      -H "Content-Type: application/json" \
      -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}' \
      http://localhost:50028/api/recommend
    
    echo ""
}

# Função para cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    kubectl -n $NAMESPACE delete job --all
    echo -e "${GREEN}✅ Cleanup done${NC}"
}

# Menu principal
case "$1" in
    build-ml)
        build_ml
        ;;
    build-api)
        build_api
        ;;
    build-all)
        build_ml
        echo ""
        build_api
        ;;
    deploy)
        deploy
        ;;
    commit)
        git_commit_push
        ;;
    monitor)
        monitor
        ;;
    status)
        status
        ;;
    check-model)
        check_model
        ;;
    test)
        test_api
        ;;
    cleanup)
        cleanup
        ;;
    full)
        build_ml
        echo ""
        build_api
        echo ""
        git_commit_push
        echo ""
        echo -e "${GREEN}✅ Build, push e commit completos!${NC}"
        echo -e "${YELLOW}💡 ArgoCD vai deployar automaticamente${NC}"
        echo -e "${YELLOW}💡 Use 'tests/COMANDOS_RAPIDOS.sh status' para ver o status${NC}"
        ;;
    *)
        echo "Usage: $0 {build-ml|build-api|build-all|deploy|commit|monitor|status|check-model|test|cleanup|full}"
        echo ""
        echo "Commands:"
        echo "  build-ml     - Build e push imagem ML (versão do job-ml.yaml)"
        echo "  build-api    - Build e push imagem API (versão do deployment.yaml)"
        echo "  build-all    - Build e push ML + API"
        echo "  deploy       - Deploy manual no Kubernetes (sem ArgoCD)"
        echo "  commit       - Commit e push das mudanças (ArgoCD deploya)"
        echo "  monitor      - Monitor pod logs"
        echo "  status       - Check status of jobs and pods"
        echo "  check-model  - Check if model exists in PVC"
        echo "  test         - Test API endpoint"
        echo "  cleanup      - Delete all jobs"
        echo "  full         - Build ML+API, push, commit (deploy via ArgoCD)"
        echo ""
        echo "Workflow ArgoCD (recomendado):"
        echo "  1. Edite manualmente as versões em k8s/job-ml.yaml e k8s/deployment.yaml"
        echo "  2. $0 full              # Build tudo e commita"
        echo "  3. ArgoCD deploya automaticamente"
        echo "  4. $0 monitor           # Acompanha logs"
        echo ""
        echo "Workflow manual (sem ArgoCD):"
        echo "  1. $0 build-all         # Build e push imagens"
        echo "  2. $0 deploy            # Deploy direto no K8s"
        echo "  3. $0 monitor           # Acompanha logs"
        exit 1
        ;;
esac
