#!/bin/bash
# Small wrapper script to enable auth on a solr instance running with embedded ZooKeeper

# init-var-solr in the event that it's empty
/opt/docker-solr/scripts/init-var-solr

function start_solr {
  solr -p 8984 -a '-DzkRun'
}

function stop_solr {
    solr stop
}

function remove_security_json {
    ./bin/solr zk rm zk:/security.json -z localhost:9984
    stop_solr
    start_solr
}


function enable_auth {
    ./bin/solr auth disable || remove_security_json
    ./bin/solr auth enable -credentials "${SOLR_USERNAME:-solr}":"${SOLR_PASSWORD:-solr}" -blockUnknown true -z localhost:9984
}

if [[ $SOLR_USERNAME ]] && [[ $SOLR_PASSWORD ]]; then
    export SOLR_AUTH_TYPE="basic"
    export SOLR_AUTHENTICATION_OPTS="-Dbasicauth=${SOLR_USERNAME}:${SOLR_PASSWORD}"
    start_solr
    enable_auth
    stop_solr
else
    echo "required varialbes not found. not setting up authentication"
fi

solr-foreground -DzkRun
