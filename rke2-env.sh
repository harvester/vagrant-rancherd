#!/bin/bash -e

NODE="node1"
vagrant ssh ${NODE} -c "sudo cat /etc/rancher/rke2/rke2.yaml" 2>/dev/null > kubeconfig

IP_CIDR=$(vagrant ssh ${NODE} -c "ip  a show eth0 | grep \"inet \" | awk '{print \$2}'" 2>/dev/null)
IP=${IP_CIDR%/*}
sed -i "s,127.0.0.1:6443,$IP:6443," kubeconfig

