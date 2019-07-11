#!/usr/bin/env bash

GLOBAL_BRK_NUM=3
PWD="~/Dropbox/phd_edo/mosquitto"

declare -A map=(["sub0"]="globalA" \
                ["sub1"]="globalA" \
                ["sub2"]="globalA" \
                ["sub3"]="globalB" \
                ["sub4"]="globalC" \
                ["sub5"]="globalC" \
                ["sub6"]="globalC")


GLOBAL_NET="mysubnet"
SUB_LIST=("sub0" "sub1" "sub2" "sub3" "sub4" "sub5" "sub6")
NET_START=20
#net_start=20

#map=((1 2 3) (4) (5 6 7))
#toB=(4)
#toC=(5 6 7)

docker stop $(docker ps -aq)
docker network rm $(docker network ls -q) 


docker network create --subnet=172.18.0.0/24 $GLOBAL_NET


net_host=$NET_START
for net_name in "${SUB_LIST[@]}"
do 
   echo creating subnetwork $net_name with $net_host
   docker network create --subnet=172.$net_host.0.0/24 $net_name
   ((++net_host))
done



docker run --rm --init -dit \
    -v $PWD/conf/plain.conf:/mosquitto/config/mosquitto.conf \
    -v $PWD/mosquitto/logs:/mosquitto/log \
    --net mysubnet --ip 172.18.0.254 \
    --name brokerINIT \
    eclipse-mosquitto


for broker in $(seq 1 $GLOBAL_BRK_NUM)
do 
  host_net=$((broker+1))
  brokerID=$(printf \\$(printf '%03o' $((broker+64))))
  container_name="global$brokerID"
  echo $brokerID
  docker run --rm --init -dit \
                -v $PWD/conf/$brokerID.conf:/mosquitto/config/mosquitto.conf \
                -v $PWD/logs:/mosquitto/log \
                --net mysubnet --ip 172.18.0.$host_net \
                --name $container_name \
                eclipse-mosquitto

done

docker network connect sub0 globalA --ip 172.20.0.254
docker network connect sub1 globalA --ip 172.21.0.254
docker network connect sub2 globalA --ip 172.22.0.254
docker network connect sub3 globalB --ip 172.23.0.254
docker network connect sub4 globalC --ip 172.24.0.254
docker network connect sub5 globalC --ip 172.25.0.254
docker network connect sub6 globalC --ip 172.26.0.254

for broker in $(seq 0 $((${#SUB_LIST[@]}-1)))
do
  host_net=$((NET_START+$broker))
  echo $host_net

  connection_name="from-$broker-to-${map[$broker]}"
  #create new config file
  cp $PWD/conf/local/basic.conf $PWD/conf/local/$broker.conf
  echo "connection $connection_name" >> $PWD/conf/local/$broker.conf
  echo "address 172.$host_net.0.254" >> $PWD/conf/local/$broker.conf
  echo "topic # both 2" >> $PWD/conf/local/$broker.conf

  cat $PWD/conf/local/$broker.conf

  docker run --rm --init -dit \
                -v $PWD/conf/local/$broker.conf:/mosquitto/config/mosquitto.conf \
                -v $PWD/logs:/mosquitto/log \
                --net ${SUB_LIST[$broker]} --ip 172.$host_net.0.250 \
                --name "local$broker" \
                eclipse-mosquitto

  #rm $PWD/conf/new.conf
done


#1 -> A
#2 -> A
#3 -> A
#4 -> B
#5 -> C
#6 -> C
#7 -> C


  # docker run --rm --init -dit \
    # -v ~/mosquitto/conf/B.conf:/mosquitto/config/mosquitto.conf \
    # -v ~/mosquitto/logs:/mosquitto/log \
    # --net mysubnet --ip 172.18.0.3 \
    # --name brokerB \
    # eclipse-mosquitto

  # docker run --rm --init -dit \
  #               -v ~/mosquitto/conf/C.conf:/mosquitto/config/mosquitto.conf \
  #               -v ~/mosquitto/logs:/mosquitto/log \
  #               --net mysubnet --ip 172.18.0.4 \
  #               --name brokerC \
  #               eclipse-mosquitto
#done
