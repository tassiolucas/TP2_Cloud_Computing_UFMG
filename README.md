# 🧪 Scripts de Teste - TP2 Cloud Computing

## 📁 Estrutura de Diretórios

```
TP2_Cloud_Computing_UFMG/
├── tests/                          ← VOCÊ ESTÁ AQUI
│   ├── README.md                   ← Este arquivo
│   ├── COMANDOS_RAPIDOS.sh         ← Script principal de deploy
│   ├── quick_test.sh               ← Teste rápido com dados de exemplo
│   ├── test_local_simple.sh        ← Teste com dataset real
│   ├── test_local.py               ← Teste Python (dataset real)
│   ├── test_with_sample_data.py    ← Teste Python (dados exemplo)
│   └── venv/                       ← Ambiente virtual (ignorado)
│
├── ml/                             ← Código de treinamento
│   ├── train_model.py
│   ├── train_model_improved.py
│   ├── Dockerfile.improved
│   └── requirements.txt
│
├── api/                            ← API Flask
│   ├── app.py
│   └── requirements.txt
│
├── k8s/                            ← Manifests Kubernetes
│   ├── job-ml-improved.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
└── .cursor/                        ← Documentação (ignorada)
    ├── LEIA-ME-PRIMEIRO.md
    ├── GUIA_DEPLOY.md
    └── ...
```

---

## 🚀 Scripts Disponíveis

### 1. `COMANDOS_RAPIDOS.sh` - Deploy Completo ⭐

Script principal para build, deploy e monitoramento no Kubernetes.

**Como usar:**
```bash
# Execute de QUALQUER lugar no projeto
./tests/COMANDOS_RAPIDOS.sh <comando>

# Ou entre no diretório tests/
cd tests/
./COMANDOS_RAPIDOS.sh <comando>
```

**Comandos disponíveis:**
```bash
# Deploy completo (build + push + deploy)
./COMANDOS_RAPIDOS.sh full

# Apenas build e push da imagem
./COMANDOS_RAPIDOS.sh build

# Apenas deploy no Kubernetes
./COMANDOS_RAPIDOS.sh deploy

# Monitorar logs em tempo real
./COMANDOS_RAPIDOS.sh monitor

# Verificar status de jobs e pods
./COMANDOS_RAPIDOS.sh status

# Verificar se modelo foi criado no PVC
./COMANDOS_RAPIDOS.sh check-model

# Testar endpoint da API
./COMANDOS_RAPIDOS.sh test

# Limpar todos os jobs
./COMANDOS_RAPIDOS.sh cleanup
```

**Exemplo de uso:**
```bash
cd tests/

# 1. Deploy completo
./COMANDOS_RAPIDOS.sh full

# 2. Monitorar execução
./COMANDOS_RAPIDOS.sh monitor

# 3. Verificar se modelo foi criado
./COMANDOS_RAPIDOS.sh check-model

# 4. Testar API
./COMANDOS_RAPIDOS.sh test
```

---

### 2. `quick_test.sh` - Teste Rápido com Dados de Exemplo

Testa o código de treinamento com dados fictícios (não precisa do dataset real).

**Como usar:**
```bash
cd tests/
./quick_test.sh
```

**O que faz:**
- Cria ambiente virtual automaticamente
- Instala dependências
- Executa teste com dados de exemplo
- Valida que o código funciona

**Tempo:** ~2-3 minutos

---

### 3. `test_local_simple.sh` - Teste com Dataset Real

Testa o código de treinamento com o dataset real (precisa ter acesso).

**Como usar:**
```bash
cd tests/
./test_local_simple.sh
```

**Requisitos:**
- Dataset em `/home/datasets/spotify/2023_spotify_ds1.csv`

---

### 4. `test_local.py` - Teste Python (Dataset Real)

Script Python para testar treinamento com dataset real.

**Como usar:**
```bash
cd tests/
source venv/bin/activate
python3 test_local.py
```

---

### 5. `test_with_sample_data.py` - Teste Python (Dados Exemplo)

Script Python para testar com dados fictícios.

**Como usar:**
```bash
cd tests/
source venv/bin/activate
python3 test_with_sample_data.py
```

---

## 📊 Fluxo de Trabalho Recomendado

### Para Desenvolvimento Local:

```bash
# 1. Entre no diretório tests
cd tests/

# 2. Teste rápido para validar código
./quick_test.sh

# 3. Se passou, faça o deploy
./COMANDOS_RAPIDOS.sh full

# 4. Monitore a execução
./COMANDOS_RAPIDOS.sh monitor
```

### Para Deploy no Cluster:

```bash
# Do diretório raiz do projeto
./tests/COMANDOS_RAPIDOS.sh full

# Ou
cd tests/
./COMANDOS_RAPIDOS.sh full
```

---

## ⚙️ Configuração

### Variáveis de Ambiente (scripts Python)

Os scripts Python aceitam estas variáveis:

```bash
export DATA_PATH="/caminho/para/dataset.csv"
export OUTPUT_PATH="./modelo.pkl"
export MAX_PLAYLISTS="5000"
export MIN_SUP_RATIO="0.1"
export MIN_CONF="0.5"

python3 test_local.py
```

### Configuração do Kubernetes

Para alterar configurações do Job:
1. Edite `../k8s/job-ml-improved.yaml`
2. Rode `./COMANDOS_RAPIDOS.sh deploy`

---

## 🐛 Troubleshooting

### Erro: "No such file or directory"
- **Causa**: Script executado de lugar errado
- **Solução**: Entre no diretório `tests/` antes de executar

### Erro: "Module not found"
- **Causa**: Ambiente virtual não ativado ou dependências não instaladas
- **Solução**: 
  ```bash
  cd tests/
  source venv/bin/activate
  pip install -r ../ml/requirements.txt
  ```

### Erro: "Permission denied"
- **Causa**: Script não tem permissão de execução
- **Solução**: 
  ```bash
  chmod +x tests/*.sh
  ```

### Pod não inicia no Kubernetes
- **Solução**: Veja logs detalhados
  ```bash
  ./COMANDOS_RAPIDOS.sh status
  kubectl -n tassioalmeida describe pod <pod-name>
  ```

---

## 📝 Notas Importantes

1. **Ambiente Virtual**: Criado automaticamente em `tests/venv/` (ignorado pelo git)

2. **Paths Relativos**: Todos os scripts funcionam de dentro do diretório `tests/`

3. **Documentação**: Documentação completa está em `.cursor/` (ignorada pelo git)
   - `.cursor/LEIA-ME-PRIMEIRO.md` - Guia principal
   - `.cursor/GUIA_DEPLOY.md` - Deploy detalhado
   - `.cursor/RESUMO_ALTERACOES.md` - Changelog

4. **Scripts Auto-Navegáveis**: 
   - `COMANDOS_RAPIDOS.sh` detecta automaticamente o diretório raiz
   - Pode ser executado de qualquer lugar

---

## 🎯 Exemplos de Uso Completo

### Exemplo 1: Primeiro Deploy
```bash
# 1. Teste local primeiro
cd tests/
./quick_test.sh

# 2. Se passou, deploy completo
./COMANDOS_RAPIDOS.sh full

# 3. Aguarde e monitore
./COMANDOS_RAPIDOS.sh monitor
```

### Exemplo 2: Atualizar Código
```bash
cd tests/

# 1. Build nova versão
./COMANDOS_RAPIDOS.sh build

# 2. Deploy
./COMANDOS_RAPIDOS.sh deploy

# 3. Monitore
./COMANDOS_RAPIDOS.sh monitor
```

### Exemplo 3: Debug
```bash
cd tests/

# Ver status geral
./COMANDOS_RAPIDOS.sh status

# Ver logs
./COMANDOS_RAPIDOS.sh monitor

# Verificar modelo
./COMANDOS_RAPIDOS.sh check-model

# Testar API
./COMANDOS_RAPIDOS.sh test
```

---

## ✅ Checklist de Deploy

- [ ] Teste local passou: `./quick_test.sh`
- [ ] Build da imagem: `./COMANDOS_RAPIDOS.sh build`
- [ ] Deploy no K8s: `./COMANDOS_RAPIDOS.sh deploy`
- [ ] Logs verificados: `./COMANDOS_RAPIDOS.sh monitor`
- [ ] Modelo criado: `./COMANDOS_RAPIDOS.sh check-model`
- [ ] API funcionando: `./COMANDOS_RAPIDOS.sh test`

---

## 💡 Dicas

1. **Use `full` para primeira vez**: Faz build + deploy + mostra status
2. **Sempre teste localmente primeiro**: `quick_test.sh` é rápido
3. **Monitore os logs**: Mostra exatamente o que está acontecendo
4. **Consulte a documentação em `.cursor/`**: Troubleshooting completo

---

## 📞 Mais Informações

- **Documentação Completa**: `.cursor/LEIA-ME-PRIMEIRO.md`
- **Guia de Deploy**: `.cursor/GUIA_DEPLOY.md`
- **Troubleshooting**: `.cursor/README_TESTE.md`

**Boa sorte com o TP2! 🚀**

