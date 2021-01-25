#!/bin/bash -u

NO_LOCK_REQUIRED=false

. ./.env
. ./.common.sh


echo "${bold}*************************************"
echo "Overlay Network  ${version}"
echo "*************************************${normal}"
echo "Resuming network..."
echo "----------------------------------"

docker-compose ${composeFile} start
