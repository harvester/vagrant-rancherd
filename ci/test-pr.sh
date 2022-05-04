#!/bin/bash -ex

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

# virsh net-destroy --network default
# virsh net-undefine default

sudo usermod -a -G libvirt $USER
groups
newgrp libvirt
groups

if ! kvm-ok; then
  yq e '.driver = "qemu"' $TOP_DIR/settings.yaml -i
fi

yq e '.ci = true' $TOP_DIR/settings.yaml -i

sudo vagrant up node1
sudo vagrant ssh node1 -c hostname
