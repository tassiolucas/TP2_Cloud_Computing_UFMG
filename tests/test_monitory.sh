#!/bin/bash
while true; do
    echo "$(date '+%H:%M:%S') - Testando API..."
    kubectl -n tassioalmeida run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -- \
        curl -s -X POST http://tp2-api:50028/api/recommend \
        -H "Content-Type: application/json" \
        -d '{"songs": ["ELEMENT."]}' | grep -o '"version":"[^"]*","model_date":"[^"]*"'
    sleep 5
done