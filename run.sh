#!/bin/bash -u

NO_LOCK_REQUIRED=true

. ./.env
. ./.common.sh


PARAMS=""

displayUsage()
{
  echo "This script creates and start a local private Backbone network using Docker."
  echo "You can select the client mechanism to use.\n"
  echo "Usage: ${me} [OPTIONS]"
  echo "    -c <miner|relay|monitor> : the client mechanism that you want to run
                                       monitor provides stats"
  echo "    -e                       : setup ELK with the network."
  echo "    -s                       : test ethsigner with the rpcnode Note the -s option must be preceeded by the -c option"
  exit 0
}

# options values and api values are not necessarily identical.
# value to use for miner option as required for Besu --rpc-http-api and --rpc-ws-api
miner='miner'
relay='relay' # value to use for relay option

composeFile="docker-compose"

while getopts "hesc:" o; do
  case "${o}" in
    h)
      displayUsage
      ;;
    c)
      algo=${OPTARG}
      case "${algo}" in
        miner|relay)
          export SAMPLE_POA_NAME="${algo}"
          export SAMPLE_POA_API="${!algo}"
          export SNAPSHOT_VERSION="${BESU_VERSION}"
          composeFile="${composeFile}_poa"
          ;;
        ethash)
          ;;
        *)
          echo "Error: Unsupported client value." >&2
          displayUsage
      esac
      ;;
    e)
      elk_compose="${composeFile/docker-compose/docker-compose_elk}"
      composeFile="$elk_compose"
      ;;
    s)
      if [[ $composeFile == *"poa"* ]]; then
        signer_compose="${composeFile/poa/poa_signer}"
        composeFile="$signer_compose"
      else
        echo "Error: Unsupported client value." >&2
        displayUsage
      fi
      ;;
    *)
      displayUsage
    ;;
  esac
done

composeFile="-f ${composeFile}.yml"

# Build and run containers and network
echo "${composeFile}" > ${LOCK_FILE}
echo "${SNAPSHOT_VERSION}" >> ${LOCK_FILE}

echo "${bold}*************************************"
echo "Client  ${SNAPSHOT_VERSION}"
echo "*************************************${normal}"
echo "Start network"
echo "--------------------"

echo "Starting network..."
docker-compose ${composeFile} build --pull
docker-compose ${composeFile} up --detach

#list services and endpoints
./list.sh

# Copyright 2018 ConsenSys AG.
# http://www.apache.org/licenses/LICENSE-2.0
# Backbone Cabal 
