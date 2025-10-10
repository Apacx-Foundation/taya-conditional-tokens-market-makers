#!/usr/bin/env bash

source .env

echo "Deploying FPMMDeterministicFactory..."

echo "Deploy args:
RPC URL: $RPC_URL
"

forge create FPMMDeterministicFactory \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --chain 11155111 \
    --broadcast \
    --verify 

