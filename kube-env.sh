#!/bin/bash -e

NODE="node1"

if [ ! -e runtime ]; then
  echo "Fail to determine runtime."
  exit 1
fi

RUNTIME=$(cat runtime)
CONFIG_FILE="/etc/rancher/$RUNTIME/$RUNTIME.yaml"
echo "Downloading $CONFIG_FILE"
vagrant ssh ${NODE} -c "sudo cat $CONFIG_FILE" 2>/dev/null > kubeconfig

IP_CIDR=$(vagrant ssh ${NODE} -c "ip  a show eth0 | grep \"inet \" | awk '{print \$2}'" 2>/dev/null)
IP=${IP_CIDR%/*}
sed -i "s,127.0.0.1:6443,$IP:6443," kubeconfig

