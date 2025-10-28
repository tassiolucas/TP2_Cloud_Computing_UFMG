#!/bin/bash
# Script para testar a API de recomendações

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="tassioalmeida"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            🧪 Testando API de Recomendações Spotify              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verifica se o pod da API está rodando
check_api_pod() {
    echo -e "${YELLOW}🔍 Verificando pod da API...${NC}"
    POD=$(kubectl -n $NAMESPACE get pods -l app=tp2-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$POD" ]; then
        echo -e "${RED}❌ Nenhum pod da API encontrado${NC}"
        return 1
    fi
    
    STATUS=$(kubectl -n $NAMESPACE get pod $POD -o jsonpath='{.status.phase}')
    if [ "$STATUS" != "Running" ]; then
        echo -e "${RED}❌ Pod da API não está rodando (Status: $STATUS)${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Pod encontrado: ${POD}${NC}"
    echo -e "${GREEN}✅ Status: ${STATUS}${NC}"
    echo ""
    return 0
}

# Testa via port-forward (mais confiável)
test_via_port_forward() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Método 1: Port-Forward (Recomendado)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! check_api_pod; then
        return 1
    fi
    
    echo -e "${YELLOW}🔄 Configurando port-forward...${NC}"
    kubectl -n $NAMESPACE port-forward svc/tp2-api 8080:50028 > /dev/null 2>&1 &
    PF_PID=$!
    
    sleep 2
    
    if ! kill -0 $PF_PID 2>/dev/null; then
        echo -e "${RED}❌ Erro ao criar port-forward${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Port-forward ativo (PID: $PF_PID)${NC}"
    echo -e "${BLUE}   Porta local: 8080 → Porta API: 50028${NC}"
    echo ""
    
    echo -e "${YELLOW}📊 Testando endpoint /healthz...${NC}"
    HEALTH=$(curl -s http://localhost:8080/healthz 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Health check: OK${NC}"
        echo -e "${CYAN}   $HEALTH${NC}"
    else
        echo -e "${RED}❌ Health check falhou${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}🎵 Testando recomendações...${NC}"
    echo -e "${BLUE}   Músicas de entrada: Yesterday, Bohemian Rhapsody${NC}"
    echo ""
    
    RESPONSE=$(curl -s -X POST http://localhost:8080/api/recommend \
        -H "Content-Type: application/json" \
        -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}' 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Requisição bem-sucedida!${NC}"
        echo ""
        echo -e "${YELLOW}📋 Resposta:${NC}"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        echo ""
    else
        echo -e "${RED}❌ Erro na requisição${NC}"
    fi
    
    echo -e "${YELLOW}🧹 Encerrando port-forward...${NC}"
    kill $PF_PID 2>/dev/null
    echo -e "${GREEN}✅ Port-forward encerrado${NC}"
    echo ""
}

# Testa via NodePort
test_via_nodeport() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Método 2: NodePort (Direto)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! check_api_pod; then
        return 1
    fi
    
    echo -e "${YELLOW}🔍 Verificando service...${NC}"
    SVC_INFO=$(kubectl -n $NAMESPACE get svc tp2-api)
    echo "$SVC_INFO"
    echo ""
    
    # Tenta descobrir o hostname do cluster
    echo -e "${YELLOW}💡 Para acessar via NodePort, use:${NC}"
    echo ""
    echo -e "${BLUE}   # Se estiver no cluster:${NC}"
    echo -e "${GREEN}   curl -X POST http://<NODE_IP>:50028/api/recommend \\${NC}"
    echo -e "${GREEN}     -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}     -d '{\"songs\": [\"Yesterday\", \"Bohemian Rhapsody\"]}'${NC}"
    echo ""
    echo -e "${BLUE}   # Para clusters UFMG/externos:${NC}"
    echo -e "${GREEN}   curl -X POST http://pugna.snes.2advanced.dev:50028/api/recommend \\${NC}"
    echo -e "${GREEN}     -H \"Content-Type: application/json\" \\${NC}"
    echo -e "${GREEN}     -d '{\"songs\": [\"Yesterday\", \"Bohemian Rhapsody\"]}'${NC}"
    echo ""
    
    # Tenta alguns hosts conhecidos
    HOSTS=("localhost" "127.0.0.1" "pugna.snes.2advanced.dev")
    
    for HOST in "${HOSTS[@]}"; do
        echo -e "${YELLOW}🔄 Tentando: ${HOST}:50028...${NC}"
        RESPONSE=$(curl -s -X POST http://${HOST}:50028/api/recommend \
            --max-time 3 \
            -H "Content-Type: application/json" \
            -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}' 2>/dev/null)
        
        if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
            echo -e "${GREEN}✅ Conectado em ${HOST}:50028${NC}"
            echo ""
            echo -e "${YELLOW}📋 Resposta:${NC}"
            echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
            echo ""
            return 0
        else
            echo -e "${RED}❌ Não conectou em ${HOST}:50028${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}💡 Nenhum host respondeu. Use port-forward (Método 1)${NC}"
    echo ""
}

# Testa com dados customizados
test_custom() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Teste Customizado${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! check_api_pod; then
        return 1
    fi
    
    echo -e "${YELLOW}🎵 Digite as músicas (separadas por vírgula):${NC}"
    read -p "Músicas: " SONGS_INPUT
    
    # Converte para array JSON
    IFS=',' read -ra SONGS_ARRAY <<< "$SONGS_INPUT"
    JSON_SONGS="["
    for i in "${!SONGS_ARRAY[@]}"; do
        SONG=$(echo "${SONGS_ARRAY[$i]}" | xargs) # trim
        if [ $i -gt 0 ]; then
            JSON_SONGS+=", "
        fi
        JSON_SONGS+="\"$SONG\""
    done
    JSON_SONGS+="]"
    
    echo ""
    echo -e "${YELLOW}🔄 Configurando port-forward...${NC}"
    kubectl -n $NAMESPACE port-forward svc/tp2-api 8080:50028 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 2
    
    echo -e "${YELLOW}📤 Enviando requisição...${NC}"
    PAYLOAD="{\"songs\": $JSON_SONGS}"
    echo -e "${BLUE}   Payload: $PAYLOAD${NC}"
    echo ""
    
    RESPONSE=$(curl -s -X POST http://localhost:8080/api/recommend \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Resposta recebida!${NC}"
        echo ""
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        echo -e "${RED}❌ Erro na requisição${NC}"
    fi
    echo ""
    
    kill $PF_PID 2>/dev/null
}

# Exibe informações do modelo
show_model_info() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Informações do Modelo${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! check_api_pod; then
        return 1
    fi
    
    echo -e "${YELLOW}🔄 Configurando port-forward...${NC}"
    kubectl -n $NAMESPACE port-forward svc/tp2-api 8080:50028 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 2
    
    echo -e "${YELLOW}📊 Consultando /healthz...${NC}"
    RESPONSE=$(curl -s http://localhost:8080/healthz 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Informações do modelo:${NC}"
        echo ""
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        echo -e "${RED}❌ Não foi possível obter informações${NC}"
    fi
    echo ""
    
    kill $PF_PID 2>/dev/null
}

# Menu principal
case "$1" in
    port-forward|pf)
        test_via_port_forward
        ;;
    nodeport|np)
        test_via_nodeport
        ;;
    custom|c)
        test_custom
        ;;
    info|i)
        show_model_info
        ;;
    *)
        echo -e "${YELLOW}Escolha um método de teste:${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} ${CYAN}./tests/test_api.sh port-forward${NC}  → Teste via port-forward (recomendado)"
        echo -e "  ${GREEN}2.${NC} ${CYAN}./tests/test_api.sh nodeport${NC}       → Teste via NodePort direto"
        echo -e "  ${GREEN}3.${NC} ${CYAN}./tests/test_api.sh custom${NC}         → Teste com suas próprias músicas"
        echo -e "  ${GREEN}4.${NC} ${CYAN}./tests/test_api.sh info${NC}           → Ver informações do modelo"
        echo ""
        echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}💡 Recomendado: ${GREEN}./tests/test_api.sh port-forward${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Atalhos:${NC}"
        echo -e "  ${CYAN}pf${NC} = port-forward"
        echo -e "  ${CYAN}np${NC} = nodeport"
        echo -e "  ${CYAN}c${NC}  = custom"
        echo -e "  ${CYAN}i${NC}  = info"
        exit 1
        ;;
esac

