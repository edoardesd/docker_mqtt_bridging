#!/usr/bin/env bash

PWD="/Users/drosdesd/Dropbox/phd_edo/mosquitto/loop_check"


echo "CASE 1"
echo -e " \t DOUBLE BOTH"

NET_IP="172.21"
caseID=1
caseName="case_$caseID"

#PREPARE THE ENVIRONMENT
mkdir -p $PWD/conf/$caseName
mkdir -p $PWD/logs/$caseName

rm -f $PWD/conf/$caseName/*
rm -f $PWD/logs/$caseName/*

docker stop $(docker ps -aq) 
docker network rm $(docker network ls -q) 

docker network create --subnet=$NET_IP.0.0/24 loop_net 

#CONFIG BROKER A
cp $PWD/conf/basic.conf $PWD/conf/$caseName/A.conf
echo "connection A-config" >> $PWD/conf/$caseName/A.conf
echo "address $NET_IP.0.3" >> $PWD/conf/$caseName/A.conf
echo "topic # both 2 \"\" \"A/\" " >> $PWD/conf/$caseName/A.conf

echo -e " \n\n"
echo -e "------------------------"
echo -e "config file A"
cat $PWD/conf/$caseName/A.conf

#CONFIG BROKER B
echo -e " \n\n"
echo -e "------------------------"
echo -e "config file b"
cp $PWD/conf/basic.conf $PWD/conf/$caseName/B.conf
#echo "connection B-config" >> $PWD/conf/$caseName/B.conf
#echo "address $NET_IP.0.2" >> $PWD/conf/$caseName/B.conf
#echo "topic # both 2 \"\" \"B/\" " >> $PWD/conf/$caseName/B.conf

cat $PWD/conf/$caseName/B.conf

echo -e " \n\n"
echo -e "------------------------"
echo -e "DOCKER RUN!"
#RUN THE DOCKER

docker run --rm --init -dit \
			-v $PWD/conf/$caseName/A.conf:/mosquitto/config/mosquitto.conf \
			-v $PWD/logs/$caseName:/mosquitto/log \
			--net loop_net --ip $NET_IP.0.2 \
			--name ${caseName}_A  \
			eclipse-mosquitto

docker run --rm --init -dit \
			-v $PWD/conf/$caseName/B.conf:/mosquitto/config/mosquitto.conf \
			-v $PWD/logs/$caseName:/mosquitto/log \
	    	--net loop_net --ip $NET_IP.0.3 \
			--name ${caseName}_B \
			eclipse-mosquitto

