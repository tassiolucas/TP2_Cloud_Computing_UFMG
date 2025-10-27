#!/bin/bash
# Comandos rápidos para deploy e monitoramento do TP2

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="tassioalmeida"
ML_IMAGE="tassiolucas/tp2-ml:0.7"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}🚀 TP2 Cloud Computing - Deploy${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Função para build e push
build_and_push() {
    echo -e "${YELLOW}📦 Building Docker image...${NC}"
    
    # Vai para o diretório raiz do projeto
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "$PROJECT_ROOT/ml/"
    
    docker build -f Dockerfile.improved -t $ML_IMAGE .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful${NC}"
        echo -e "${YELLOW}🚀 Pushing to DockerHub...${NC}"
        docker push $ML_IMAGE
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Push successful${NC}"
        else
            echo -e "${RED}❌ Push failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
    
    # Volta para o diretório raiz
    cd "$PROJECT_ROOT"
}

# Função para deploy
deploy() {
    echo -e "${YELLOW}🔄 Deploying to Kubernetes...${NC}"
    
    # Vai para o diretório raiz do projeto
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Deletar job antigo
    kubectl -n $NAMESPACE delete job tp2-ml-job 2>/dev/null || true
    kubectl -n $NAMESPACE delete job tp2-ml-job-v1 2>/dev/null || true
    
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
    
    POD_NAME=$(kubectl -n $NAMESPACE get pods -l job-name=tp2-ml-job-v1 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
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
    build)
        build_and_push
        ;;
    deploy)
        deploy
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
        build_and_push
        echo ""
        deploy
        echo ""
        echo -e "${GREEN}✅ Build and deploy complete!${NC}"
        echo -e "${YELLOW}💡 Run 'tests/COMANDOS_RAPIDOS.sh monitor' to see logs${NC}"
        ;;
    *)
        echo "Usage: $0 {build|deploy|monitor|status|check-model|test|cleanup|full}"
        echo ""
        echo "Commands:"
        echo "  build        - Build and push Docker image"
        echo "  deploy       - Deploy job to Kubernetes"
        echo "  monitor      - Monitor pod logs"
        echo "  status       - Check status of jobs and pods"
        echo "  check-model  - Check if model exists in PVC"
        echo "  test         - Test API endpoint"
        echo "  cleanup      - Delete all jobs"
        echo "  full         - Build, push, and deploy (one command)"
        echo ""
        echo "Examples:"
        echo "  $0 full              # Complete deployment"
        echo "  $0 monitor           # Watch logs"
        echo "  $0 test              # Test API"
        exit 1
        ;;
esac

