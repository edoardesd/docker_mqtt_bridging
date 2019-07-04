#!/usr/bin/env bash

PWD="~/Dropbox/phd_edo/mosquitto"


echo "CASE 1"
echo "\tDouble both"

NET_IP="172.21"
caseID=1
caseName="case$caseID"


mkdir -p $PWD/conf/$caseName
mkdir -p $PWD/logs/$caseName

docker stop $(docker ps -aq)
docker network rm $(docker network ls -q)

docker network create --subnet=$NET_IP.0.0/24 loop_net

docker run --rm --init -dit \
	-v $PWD/conf/$caseName/A.conf:/mosquitto/config/mosquitto.conf \
	-v $PWD/mosquitto/logs/$caseName:/mosquitto/log \
	--net loop_net --ip $NET_IP.0.2 \
	--name $caseName_A \
	eclipse-mosquitto

docker run --rm --init -dit \
	-v $PWD/conf/$caseName/B.conf:/mosquitto/config/mosquitto.conf \
	-v $PWD/mosquitto/logs/$caseName:/mosquitto/log \
	--net loop_net --ip $NET_IP.0.3 \
	--name $caseName_B \
	eclipse-mosquitto
