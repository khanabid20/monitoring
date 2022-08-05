#!/bin/bash

# Date: 2022/08/05
# Author: Abid Khan
# Description: This script loops over list of servers provide in a text file and deploy node-exporter container.
# Usage: 
#   $0

# Loop through nodes file line by line
while IFS= read -r line
do
    [ "${line:0:1}" = "#" ] && continue
    
    # Spilt the line and create an array
    entry=(${line//,/ })

    if command -v sshpass &> /dev/null
    then
        echo .........................................
        echo "Installing node-exporter on ${entry[0]}"
        echo '           `````````````' 
        echo
        sshpass -p "${entry[2]}" ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no ${entry[1]}@${entry[0]} /bin/bash <<EOF
        echo ...Pull image
        docker pull prom/node-exporter

        echo
        echo '...Run container (if not running/created)'
        docker start node-exporter || docker run --restart=unless-stopped -d --name node-exporter \
        --net="host" --pid="host" \
        -v "/:/host:ro,rslave"  \
        prom/node-exporter

        echo
        echo ...Check container status
        docker ps --filter "name=node-exporter"

        echo
        echo ...Check status of node-exporter metrics
        curl -s -o /dev/null -w "status code: %{http_code}" http://localhost:9100/metrics
EOF
    else
        echo "'sshpass' is not installed on ${entry[0]}"
    fi
done < node_lists.txt
