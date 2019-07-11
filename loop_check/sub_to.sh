subnet=$(docker inspect $1 --format '{{json .IPAM.Config }}' | tr -d 'Subnet " : {}[] /' | rev | cut -c 4- | rev)

echo "Subscribing to $subnet$2"

docker run --init -it --rm --net $1 efrecon/mqtt-client sub -h $subnet$2 -t '#' -v
