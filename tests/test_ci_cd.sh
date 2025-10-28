#!/bin/bash
# Script para testar o pipeline CI/CD do GitHub Actions

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       🧪 Testando CI/CD - GitHub Actions + ArgoCD               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar se gh CLI está instalado
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) não encontrado${NC}"
        echo -e "${CYAN}   Instale: brew install gh${NC}"
        echo -e "${CYAN}   Depois: gh auth login${NC}"
        return 1
    fi
    return 0
}

# Opção 1: Teste Manual via GitHub UI
test_manual() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OPÇÃO 1: Execução Manual via GitHub Interface${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Passos:${NC}"
    echo -e "  1. Acesse: ${BLUE}https://github.com/tassiolucas/TP2_Cloud_Computing_UFMG/actions${NC}"
    echo -e "  2. Clique em: ${GREEN}Auto Version & Deploy${NC}"
    echo -e "  3. Clique em: ${GREEN}Run workflow${NC}"
    echo -e "  4. Selecione: ${GREEN}main${NC} branch"
    echo -e "  5. Component: ${GREEN}ml${NC} (ou api, ou both)"
    echo -e "  6. Clique em: ${GREEN}Run workflow${NC}"
    echo ""
    echo -e "${YELLOW}✅ O workflow vai:${NC}"
    echo -e "  • Incrementar versão (0.9 → 0.10)"
    echo -e "  • Build da imagem Docker"
    echo -e "  • Push para DockerHub"
    echo -e "  • Atualizar k8s/job-ml.yaml"
    echo -e "  • Commit da mudança"
    echo ""
    
    if check_gh_cli; then
        echo -e "${CYAN}💡 Ou execute via CLI:${NC}"
        echo -e "  ${GREEN}gh workflow run auto-version.yml -f component=ml${NC}"
        echo ""
    fi
}

# Opção 2: Teste Real (commit + push)
test_real() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OPÇÃO 2: Teste Real (Commit + Push Automático)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}🔍 Verificando versão atual...${NC}"
    CURRENT_ML=$(grep "image: tassiolucas/tp2-ml:" "$PROJECT_ROOT/k8s/job-ml.yaml" | awk -F: '{print $NF}' | tr -d ' ')
    CURRENT_API=$(grep "image: tassiolucas/tp2-api:" "$PROJECT_ROOT/k8s/deployment.yaml" | awk -F: '{print $NF}' | tr -d ' ')
    
    echo -e "  ML atual:  ${GREEN}${CURRENT_ML}${NC}"
    echo -e "  API atual: ${GREEN}${CURRENT_API}${NC}"
    echo ""
    
    echo -e "${YELLOW}📝 Uma mudança JÁ FOI FEITA em ml/train_model.py${NC}"
    echo -e "  (Adicionado comentário de teste no cabeçalho)${NC}"
    echo ""
    
    echo -e "${YELLOW}🚀 Para testar, execute:${NC}"
    echo -e "  ${GREEN}cd \"$PROJECT_ROOT\"${NC}"
    echo -e "  ${GREEN}git add ml/train_model.py${NC}"
    echo -e "  ${GREEN}git commit -m \"test: valida CI/CD automático\"${NC}"
    echo -e "  ${GREEN}git push origin main${NC}"
    echo ""
    
    echo -e "${YELLOW}✅ O que vai acontecer:${NC}"
    echo -e "  1. ${CYAN}GitHub detecta mudança em ml/${NC}"
    echo -e "  2. ${CYAN}Workflow 'auto-version' é acionado${NC}"
    echo -e "  3. ${CYAN}Versão ML incrementada (${CURRENT_ML} → próxima)${NC}"
    echo -e "  4. ${CYAN}Build da imagem (linux/amd64)${NC}"
    echo -e "  5. ${CYAN}Push para DockerHub${NC}"
    echo -e "  6. ${CYAN}Update de k8s/job-ml.yaml${NC}"
    echo -e "  7. ${CYAN}Commit automático da mudança de versão${NC}"
    echo -e "  8. ${CYAN}ArgoCD detecta e faz sync (~3 min)${NC}"
    echo -e "  9. ${CYAN}Novo pod é criado no Kubernetes${NC}"
    echo ""
    
    read -p "Deseja fazer o commit e push agora? (s/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cd "$PROJECT_ROOT"
        
        echo -e "${YELLOW}📤 Fazendo commit e push...${NC}"
        git add ml/train_model.py
        git commit -m "test: valida CI/CD automático"
        git push origin main
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Push realizado com sucesso!${NC}"
            echo ""
            monitor_workflow
        else
            echo -e "${RED}❌ Erro no push${NC}"
        fi
    fi
}

# Opção 3: Verificar workflow sem executar
test_verify() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OPÇÃO 3: Verificação Local (Simulação)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    echo -e "${YELLOW}🔍 Verificando arquivos do workflow...${NC}"
    
    if [ -f ".github/workflows/auto-version.yml" ]; then
        echo -e "  ${GREEN}✅ auto-version.yml${NC} encontrado"
    else
        echo -e "  ${RED}❌ auto-version.yml${NC} NÃO encontrado"
    fi
    
    if [ -f ".github/workflows/ci-cd.yml" ]; then
        echo -e "  ${GREEN}✅ ci-cd.yml${NC} encontrado"
    else
        echo -e "  ${RED}❌ ci-cd.yml${NC} NÃO encontrado"
    fi
    echo ""
    
    echo -e "${YELLOW}📊 Versões atuais:${NC}"
    ML_VERSION=$(grep "image: tassiolucas/tp2-ml:" k8s/job-ml.yaml | awk -F: '{print $NF}' | tr -d ' ')
    API_VERSION=$(grep "image: tassiolucas/tp2-api:" k8s/deployment.yaml | awk -F: '{print $NF}' | tr -d ' ')
    
    echo -e "  ML:  ${GREEN}tassiolucas/tp2-ml:${ML_VERSION}${NC}"
    echo -e "  API: ${GREEN}tassiolucas/tp2-api:${API_VERSION}${NC}"
    echo ""
    
    echo -e "${YELLOW}🔄 Simulando incremento de versão:${NC}"
    MAJOR=$(echo $ML_VERSION | cut -d. -f1)
    MINOR=$(echo $ML_VERSION | cut -d. -f2)
    NEW_MINOR=$((MINOR + 1))
    NEW_VERSION="${MAJOR}.${NEW_MINOR}"
    echo -e "  Próxima versão ML: ${CYAN}${NEW_VERSION}${NC}"
    echo ""
    
    echo -e "${YELLOW}📝 Mudanças detectadas:${NC}"
    git diff --name-only HEAD | while read file; do
        if [[ $file == ml/* ]]; then
            echo -e "  ${GREEN}✅ ML:${NC} $file (acionará workflow)"
        elif [[ $file == api/* ]]; then
            echo -e "  ${GREEN}✅ API:${NC} $file (acionará workflow)"
        else
            echo -e "  ${BLUE}ℹ️  Outros:${NC} $file (não aciona workflow)"
        fi
    done
    echo ""
}

# Monitorar workflow em execução
monitor_workflow() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Monitorando Workflow${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if check_gh_cli; then
        echo -e "${YELLOW}🔍 Verificando workflows em execução...${NC}"
        gh run list --limit 5
        echo ""
        
        echo -e "${YELLOW}💡 Comandos úteis:${NC}"
        echo -e "  Ver logs em tempo real:  ${GREEN}gh run watch${NC}"
        echo -e "  Ver último run:          ${GREEN}gh run view --log${NC}"
        echo -e "  Lista todos os runs:     ${GREEN}gh run list${NC}"
        echo ""
        
        echo -e "${YELLOW}🌐 Ou acesse no navegador:${NC}"
        echo -e "  ${BLUE}https://github.com/tassiolucas/TP2_Cloud_Computing_UFMG/actions${NC}"
        echo ""
    else
        echo -e "${YELLOW}🌐 Acesse no navegador:${NC}"
        echo -e "  ${BLUE}https://github.com/tassiolucas/TP2_Cloud_Computing_UFMG/actions${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}📊 Monitorar pods no Kubernetes:${NC}"
    echo -e "  ${GREEN}kubectl -n tassioalmeida get pods -w${NC}"
    echo -e "  ${GREEN}./tests/COMANDOS_RAPIDOS.sh monitor${NC}"
    echo ""
}

# Menu principal
case "$1" in
    manual)
        test_manual
        ;;
    real)
        test_real
        ;;
    verify)
        test_verify
        ;;
    monitor)
        monitor_workflow
        ;;
    *)
        echo -e "${YELLOW}Escolha uma opção de teste:${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} ${CYAN}./tests/test_ci_cd.sh manual${NC}   → Executar manualmente via GitHub UI"
        echo -e "  ${GREEN}2.${NC} ${CYAN}./tests/test_ci_cd.sh real${NC}     → Fazer commit e testar automação completa"
        echo -e "  ${GREEN}3.${NC} ${CYAN}./tests/test_ci_cd.sh verify${NC}   → Verificar configuração sem executar"
        echo -e "  ${GREEN}4.${NC} ${CYAN}./tests/test_ci_cd.sh monitor${NC}  → Monitorar workflows em execução"
        echo ""
        echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}💡 Recomendado para primeira vez: ${GREEN}./tests/test_ci_cd.sh verify${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
        exit 1
        ;;
esac

