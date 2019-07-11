subnet=$(docker inspect $1 --format '{{json .IPAM.Config }}' | tr -d 'Subnet " : {}[] /' | rev | cut -c 4- | rev)

echo "Publishing to $subnet$2 -- message $4 -- topic $3 "

docker run --init -it --rm --net $1 efrecon/mqtt-client pub -h $subnet$2 -t $3 -m $4