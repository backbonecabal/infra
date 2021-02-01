#!/bin/bash -eu

NO_LOCK_REQUIRED=false

. ./.env
. ./.common.sh

HOST=${DOCKER_PORT_2375_TCP_ADDR:-"localhost"}

# Displays links to exposed services
echo "${bold}*************************************"
echo "Client ${version}"
echo "*************************************${normal}"
echo "List endpoints and services"
echo "----------------------------------"

# Displays services list with port mapping
docker-compose ps
dots=""
maxRetryCount=50

# Determine if ELK is setup
elk_setup=true
if [ -z $(docker-compose -f docker-compose_elk.yml ps -q kibana) ] || [ -z $(docker ps -q --no-trunc | grep $(docker-compose -f docker-compose_elk.yml ps -q kibana)) ] ||
    [ -z $(docker-compose -f docker-compose_elk_poa.yml ps -q kibana) ] || [ -z $(docker ps -q --no-trunc | grep $(docker-compose -f docker-compose_elk_poa.yml ps -q kibana)) ]; then
  elk_setup=false
fi

if [ $elk_setup == true ]; then
    while [ "$(curl -m 10 -s -o /dev/null -w ''%{http_code}'' http://"${HOST}":5601/api/status)" != "200" ] && [ ${#dots} -le ${maxRetryCount} ]
    do
      dots=$dots"."
      printf "Kibana is starting, please wait $dots\\r"
      sleep 10
    done

    echo "Setting up the metricbeat index pattern in kibana"
    curl -X POST "http://${HOST}:5601/api/saved_objects/index-pattern/metricbeat" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{"attributes": {"title": "metricbeat-*","timeFieldName": "@timestamp"}}'
    curl -X POST "http://${HOST}:5601/api/saved_objects/_import" -H 'kbn-xsrf: true' --form file=@./monitoring/kibana/besu_overview_dashboard.ndjson

    echo "Setting up the besu index pattern in kibana"
    curl -X POST "http://${HOST}:5601/api/saved_objects/index-pattern/besu" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{"attributes": {"title": "besu-*","timeFieldName": "@timestamp"}}'

fi

echo "****************************************************************"
if [ ${#dots} -gt ${maxRetryCount} ]; then
  echo "ERROR: Web block explorer is not started at http://${HOST}:${explorerPort} !"
  echo "****************************************************************"
else
  echo "JSON-RPC HTTP service endpoint      : http://${HOST}:8545"
  echo "JSON-RPC WebSocket service endpoint : ws://${HOST}:8546"
  echo "GraphQL HTTP service endpoint       : http://${HOST}:8547"
  echo "Web block explorer address          : http://${HOST}:25000/"
  echo "Prometheus address                  : http://${HOST}:9090/graph"
  echo "Grafana address                     : http://${HOST}:3000/d/XE4V0WGZz/besu-overview?orgId=1&refresh=10s&from=now-30m&to=now&var-system=All"
  if [ $elk_setup == true ]; then
    echo "Kibana logs address                 : http://${HOST}:5601/app/kibana#/discover"
  fi
  echo "****************************************************************"
fi


# Copyright 2018 ConsenSys AG.
# http://www.apache.org/licenses/LICENSE-2.0

