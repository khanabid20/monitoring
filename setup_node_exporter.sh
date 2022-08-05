#!/bin/bash

# Date: 2022/08/05
# Author: Abid Khan
# Description: This script loops over list of servers provide in a text file and deploy node-exporter container.
# Usage: 
#   $0 <ssh_password>

# Make sure don't leave the password here
SSH_PASSWD="${1:-here}"

# Loop through nodes file line by line, each line is ssh hostname
while IFS= read -r node
do
    [ "${node:0:1}" = "#" ] && continue
    if command -v sshpass &> /dev/null
    then
        echo .........................................
        echo "Installing node-exporter on ${node//*@/}"
        echo '           `````````````' 
        echo
        sshpass -p "${SSH_PASSWD}" ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no ${node//$'\r'/} /bin/bash <<EOF
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
        echo "'sshpass' is not installed on ${node//*@/}"
    fi
done < node_lists.txt
