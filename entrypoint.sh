#!/bin/bash
set -e 

# Vault init container will drop the token in /vault/token; alternatively we can set the VAULT_TOKEN env variable 
if [ -f /vault/token ]; then
    export VAULT_TOKEN=$(cat /vault/token)
fi

function start_envconsul() {
    set -u 
    envconsul \
        -vault-addr=${VAULT_ADDR} \
        -secret=${VAULT_PATH} \
        -vault-token=${VAULT_TOKEN} \
        -no-prefix=true \
        -vault-renew-token=false \
        -once \
        -exec='bash start.sh'
}


if [ -n "${VAULT_TOKEN}" ]; then
    echo "have token. starting envconsul"
    start_envconsul
else
    echo "starting the app"
    bash start.sh
fi
