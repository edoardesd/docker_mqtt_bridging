#!/usr/bin/env bash

GLOBAL_BRK_NUM=3
NUM_ROUNDS=5
rounds=(1 2 3 4 5)
HOST_NAME="10.79.1.112"
PORT="1883"
topics=(10 100 500 1000 2000 5000 10000 50000)
publishers=(1 10 100 500 1000)
sub=10
NUM_OF_MSG=1000
RECORD_INTERVAL=0.1

killall mosquitto_sub
killall mosquitto_pub
ssh antedo "killall mosquitto_sub && killall mosquitto_pub"

##### SUBSCRIBERS #####
echo "Creating $sub subscribers..."
for i in `seq $sub`;
	do
		seq_port=$(($PORT + $i % $GLOBAL_BRK_NUM))
		echo "Sub number $i on port $seq_port"

		nohup mosquitto_sub -h $HOST_NAME -p $seq_port -I i -t '#' -q 2 >/dev/null 2>&1 &
	done
echo "Done!"

sleep 3
##### END SUB #####


for round in "${rounds[@]}";
	do
	for topic_n in "${topics[@]}";
		do
		for pub in "${publishers[@]}";
			do
				echo "--------------------------------------------"
				echo "Case PUB: ${pub} SUB: ${sub} #TOPICS: ${topic_n} ROUND: ${round}"
				##### LOGGING #####
				nohup ssh cluster "psrecord 23004 --interval ${RECORD_INTERVAL} --log ~/bridging-results/3brokers/pub1node/broker1883_TOPIC${topic_n}_SUB${sub}_PUB${pub}_ROUND${round}.txt" &
				nohup ssh cluster "psrecord 23409 --interval ${RECORD_INTERVAL} --log ~/bridging-results/3brokers/pub1node/broker1884_TOPIC${topic_n}_SUB${sub}_PUB${pub}_ROUND${round}.txt" &
				nohup ssh cluster "psrecord 23434 --interval ${RECORD_INTERVAL} --log ~/bridging-results/3brokers/pub1node/broker1885_TOPIC${topic_n}_SUB${sub}_PUB${pub}_ROUND${round}.txt" &

				sleep 4
				##### END LOGGING #####
				ssh antedo "mosquitto_sub -v -h ${HOST_NAME} -p ${PORT} -t '#' -q 2 | ts '%Y%m%d-%H:%M:%.S'" > ~/Dropbox/phd_edo/mqtt-bridging/3brokers/pub1node//sub_TOPIC${topic_n}_SUB${sub}_PUB${pub}_ROUND${round}.txt &
				##### PUB #####
				echo "Starting publishing"
				ssh antedo "~/mqtt/bin/mqtt-benchmark --broker tcp://${HOST_NAME}:${PORT} --numTopics ${topic_n} --qos 2 --clients=${pub} --count ${NUM_OF_MSG} --quiet=true --topic /client/data/10/10" | tail -10 > ~/Dropbox/phd_edo/mqtt-bridging/3brokers/pub1node/pubstat_TOPIC${topic_n}_SUB${sub}_PUB${pub}_ROUND${round}.txt

				echo "DONE!"

				sleep 10
				##### Kill psrecord and other clients #####
				ssh antedo "killall mosquitto_sub && killall mosquitto_pub"
				echo "Kill recording"
				ssh cluster "killall psrecord"
			done
		done
	done