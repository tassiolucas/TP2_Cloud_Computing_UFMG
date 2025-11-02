# 🧪 Testando a API de Recomendações

A API está rodando no Kubernetes na porta 50028, mas devido às restrições de segurança do cluster UFMG, há limitações de acesso.

## 📊 Status Atual

✅ **API está rodando**
```bash
$ kubectl -n tassioalmeida logs -l app=tp2-api --tail=5
✅ Modelo carregado com sucesso! (10283 regras)
* Running on all addresses (0.0.0.0)
* Running on http://127.0.0.1:50028
* Running on http://10.42.0.39:50028
```

✅ **Service configurado**
- Tipo: NodePort
- Porta interna: 50028
- NodePort externo: 50028
- ClusterIP: 10.43.91.18

## 🔧 Métodos de Teste

### Opção 1: Via Pod de Teste (Recomendado)

Crie um pod temporário dentro do cluster para testar:

```bash
# 1. Cria pod de teste
kubectl -n tassioalmeida run test-api --rm -i --tty --image=curlimages/curl -- sh

# 2. Dentro do pod, teste a API
curl -X POST http://tp2-api:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}'

# 3. Teste health check
curl http://tp2-api:50028/healthz

# 4. Saia do pod (será removido automaticamente)
exit
```

### Opção 2: Via Port-Forward (Se tiver permissões)

```bash
# 1. Cria port-forward
kubectl -n tassioalmeida port-forward svc/tp2-api 8080:50028

# 2. Em outro terminal, teste
curl -X POST http://localhost:8080/api/recommend \
  -H "Content-Type: application/json" \
  -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}'

# 3. Health check
curl http://localhost:8080/healthz
```

### Opção 3: Via NodePort Externo (Se exposto)

Se o cluster permitir acesso externo via NodePort:

```bash
# Descobrir o IP/hostname do node
kubectl get nodes -o wide

# Testar (substitua <NODE_IP> pelo IP do node)
curl -X POST http://<NODE_IP>:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}'
```

### Opção 4: Via Script Automatizado

```bash
# Use o script de teste
cd tests/
./test_api.sh

# Opções disponíveis:
# - port-forward (pf) : Tenta via port-forward
# - nodeport (np)     : Tenta via NodePort
# - custom (c)        : Teste customizado
# - info (i)          : Info do modelo
```

## 📋 Endpoints Disponíveis

### GET /healthz
Health check da API

**Response:**
```json
{
  "status": "ok"
}
```

### POST /api/recommend
Recomenda músicas baseado em uma lista de entrada

**Request:**
```json
{
  "songs": ["Yesterday", "Bohemian Rhapsody", "Imagine"]
}
```

**Response (sucesso):**
```json
{
  "songs": [
    "spotify:track:...",
    "spotify:track:...",
    "spotify:track:..."
  ],
  "version": "1.0",
  "model_date": "2025-10-28",
  "num_rules": 10283,
  "num_playlists": 2262
}
```

**Response (modelo não carregado):**
```json
{
  "error": "Modelo não carregado ainda",
  "songs": []
}
```
Status: 503

## 🎯 Exemplos de Teste

### Exemplo 1: Músicas dos Beatles
```bash
curl -X POST http://tp2-api:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "songs": [
      "Yesterday",
      "Hey Jude",
      "Let It Be"
    ]
  }'
```

### Exemplo 2: Rock Clássico
```bash
curl -X POST http://tp2-api:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "songs": [
      "Bohemian Rhapsody",
      "Stairway to Heaven",
      "Hotel California"
    ]
  }'
```

### Exemplo 3: Com URIs do Spotify
```bash
curl -X POST http://tp2-api:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "songs": [
      "spotify:track:2Fk0WwAqTBesLtKg97nojy",
      "spotify:track:7KXjTSCq5nL1LoYtL7XAwS"
    ]
  }'
```

## ⚠️ Limitações Atuais

### Permissões Restritas
O usuário `system:serviceaccount:tassioalmeida:tassioalmeida` não tem permissão para:
- ❌ `kubectl exec` (pods/exec)
- ❌ `kubectl get nodes`

### Soluções

1. **Solicitar ao professor/admin:**
   - Liberar acesso externo via Ingress
   - Adicionar permissões de exec
   - Criar um LoadBalancer

2. **Usar pod temporário:** (Opção 1 acima)
   - Funciona sem permissões extras
   - Testa dentro do cluster
   - É removido automaticamente

3. **Pedir ajuda para testar:**
   - Professor pode fazer exec
   - Admin pode expor via Ingress
   - Colega com permissões pode testar

## 📊 Verificar Status

### Ver logs da API
```bash
kubectl -n tassioalmeida logs -l app=tp2-api --tail=50
kubectl -n tassioalmeida logs -l app=tp2-api -f  # Follow
```

### Ver status do pod
```bash
kubectl -n tassioalmeida get pods -l app=tp2-api
kubectl -n tassioalmeida describe pod -l app=tp2-api
```

### Ver service
```bash
kubectl -n tassioalmeida get svc tp2-api
kubectl -n tassioalmeida describe svc tp2-api
```

### Ver endpoints
```bash
kubectl -n tassioalmeida get endpoints tp2-api
```

## 🚀 Teste Rápido (Recomendado)

O método mais fácil e que funciona com as permissões atuais:

```bash
# 1. Criar pod temporário e testar tudo de uma vez
kubectl -n tassioalmeida run test-api --rm -i --tty --image=curlimages/curl -- sh -c "
echo '🔍 Testando health check...'
curl -s http://tp2-api:50028/healthz
echo -e '\n\n🎵 Testando recomendações...'
curl -s -X POST http://tp2-api:50028/api/recommend \
  -H 'Content-Type: application/json' \
  -d '{\"songs\": [\"Yesterday\", \"Bohemian Rhapsody\"]}' | head -20
"
```

## 💡 Dica

Se você conseguir acesso SSH ao node do cluster:

```bash
# SSH no node
ssh tassioalmeida@pugna.snes.2advanced.dev -p 51927

# De dentro do node
curl -X POST http://localhost:50028/api/recommend \
  -H "Content-Type: application/json" \
  -d '{"songs": ["Yesterday", "Bohemian Rhapsody"]}'
```

