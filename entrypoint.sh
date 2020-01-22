#!/bin/bash
set -e 

# Vault init container will drop the token in /vault/token; alternatively we can set the VAULT_TOKEN env variable 
if [ -f /vault/token ]; then
    export VAULT_TOKEN=$(cat /vault/token)
fi

# New versions of vault-init calls the file something slightly different. export vault token if that file is found
if [ -f /vault/.vault-token ]; then 
    export VAULT_TOKEN=$(cat /vault/.vault-token)

fi

function start_envconsul() {
    set -u 
    envconsul \
        -vault-addr=${VAULT_ADDR} \
        -secret=${VAULT_PATH} \
        -no-prefix=true \
        -vault-renew-token=true \
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
