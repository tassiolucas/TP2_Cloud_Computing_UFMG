#!/bin/bash
# Script para medir tempo de CI/CD completo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="tassioalmeida"
EXPECTED_VERSION="1.5"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ⏱️  Monitor de Tempo CI/CD - TP2 Cloud Computing        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Timestamp de início
START_TIME=$(date +%s%3N)
START_TIME_HUMAN=$(date '+%Y-%m-%d %H:%M:%S.%3N')

echo -e "${CYAN}📅 Início: ${START_TIME_HUMAN}${NC}"
echo -e "${CYAN}🎯 Versão esperada: ${EXPECTED_VERSION}${NC}"
echo ""

# Função para calcular tempo decorrido
elapsed_time() {
    local current_time=$(date +%s%3N)
    local elapsed=$((current_time - START_TIME))
    local seconds=$((elapsed / 1000))
    local milliseconds=$((elapsed % 1000))
    echo "${seconds}.${milliseconds}s"
}

# Função para verificar versão da API
check_api_version() {
    local response=$(kubectl -n $NAMESPACE run curl-test-monitor --image=curlimages/curl:latest --rm -i --restart=Never --quiet -- \
        curl -s -X POST http://tp2-api:50028/api/recommend \
        -H "Content-Type: application/json" \
        -d '{"songs": ["ELEMENT."]}' 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo "$response"
}

echo -e "${YELLOW}⏳ Aguardando GitHub Actions buildar a imagem...${NC}"
echo ""

# Etapa 1: Aguardar build no GitHub Actions (aproximadamente 2-3 minutos)
GITHUB_WAIT=0
while [ $GITHUB_WAIT -lt 180 ]; do
    ELAPSED=$(elapsed_time)
    echo -ne "\r${CYAN}[${ELAPSED}]${NC} Aguardando GitHub Actions... "
    sleep 5
    GITHUB_WAIT=$((GITHUB_WAIT + 5))
    
    # Verificar se imagem já está disponível via ArgoCD
    if [ $GITHUB_WAIT -ge 60 ]; then
        POD_STATUS=$(kubectl -n $NAMESPACE get pods -l app=tp2-api -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        if [ "$POD_STATUS" == "Running" ]; then
            CURRENT_VERSION=$(check_api_version)
            if [ "$CURRENT_VERSION" == "$EXPECTED_VERSION" ]; then
                break
            fi
        fi
    fi
done

echo ""
echo ""
echo -e "${YELLOW}⏳ Monitorando ArgoCD e deploy do pod...${NC}"
echo ""

# Etapa 2: Monitorar pods e versão
CHECKS=0
MAX_CHECKS=120  # 10 minutos máximo

while [ $CHECKS -lt $MAX_CHECKS ]; do
    ELAPSED=$(elapsed_time)
    
    # Verificar status do pod
    POD_INFO=$(kubectl -n $NAMESPACE get pods -l app=tp2-api -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.status.phase}{"|"}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | head -1)
    
    if [ -n "$POD_INFO" ]; then
        POD_NAME=$(echo "$POD_INFO" | cut -d'|' -f1)
        POD_STATUS=$(echo "$POD_INFO" | cut -d'|' -f2)
        POD_IMAGE=$(echo "$POD_INFO" | cut -d'|' -f3)
        
        echo -e "\r${CYAN}[${ELAPSED}]${NC} Pod: ${POD_NAME:0:30}... | Status: ${POD_STATUS} | Image: ${POD_IMAGE}    "
        
        if [ "$POD_STATUS" == "Running" ]; then
            # Verificar versão da API
            CURRENT_VERSION=$(check_api_version)
            
            if [ -n "$CURRENT_VERSION" ]; then
                echo -e "${CYAN}[${ELAPSED}]${NC} ${YELLOW}Versão respondendo: ${CURRENT_VERSION}${NC}"
                
                if [ "$CURRENT_VERSION" == "$EXPECTED_VERSION" ]; then
                    echo ""
                    echo -e "${GREEN}✅ SUCESSO! Nova versão ${EXPECTED_VERSION} está respondendo!${NC}"
                    break
                fi
            fi
        fi
    else
        echo -e "\r${CYAN}[${ELAPSED}]${NC} ${YELLOW}Aguardando pod ser criado...${NC}    "
    fi
    
    sleep 5
    CHECKS=$((CHECKS + 1))
done

echo ""
echo ""

# Tempo final
END_TIME=$(date +%s%3N)
END_TIME_HUMAN=$(date '+%Y-%m-%d %H:%M:%S.%3N')
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_SECONDS=$((TOTAL_TIME / 1000))
TOTAL_MILLISECONDS=$((TOTAL_TIME % 1000))
TOTAL_MINUTES=$((TOTAL_SECONDS / 60))
REMAINING_SECONDS=$((TOTAL_SECONDS % 60))

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     📊 RESULTADO DO TESTE CI/CD                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📅 Início:  ${START_TIME_HUMAN}${NC}"
echo -e "${CYAN}📅 Fim:     ${END_TIME_HUMAN}${NC}"
echo ""
echo -e "${GREEN}⏱️  TEMPO TOTAL: ${TOTAL_MINUTES}m ${REMAINING_SECONDS}s ${TOTAL_MILLISECONDS}ms${NC}"
echo -e "${GREEN}⏱️  TEMPO TOTAL: ${TOTAL_SECONDS}.${TOTAL_MILLISECONDS} segundos${NC}"
echo -e "${GREEN}⏱️  TEMPO TOTAL: ${TOTAL_TIME} milissegundos${NC}"
echo ""

if [ "$CURRENT_VERSION" == "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✅ Status: Deploy completado com sucesso${NC}"
    echo -e "${GREEN}✅ Versão final: ${CURRENT_VERSION}${NC}"
else
    echo -e "${RED}❌ Status: Timeout ou falha no deploy${NC}"
    echo -e "${RED}❌ Versão atual: ${CURRENT_VERSION:-"não disponível"}${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"

