#!/bin/bash -e

NODE=node1
IP_CIDR=$(vagrant ssh ${NODE} -c "ip a show eth0 | grep \"inet \" | awk '{print \$2}'" 2>/dev/null)
IP=${IP_CIDR%/*}

echo "Set server IP to $IP"

sed -i "s,^server_ip:.*,server_ip: $IP,g" settings.yaml

