#!/bin/bash -ex

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

vagrant(){
  docker run -i --rm \
    -e LIBVIRT_DEFAULT_URI \
    -v /var/run/libvirt/:/var/run/libvirt/ \
    -v ~/.vagrant.d:/.vagrant.d \
    -v $(realpath "${PWD}"):${PWD} \
    -w $(realpath "${PWD}") \
    --network host \
    vagrantlibvirt/vagrant-libvirt:latest-slim \
      vagrant $@
}

# virsh net-destroy --network default
# virsh net-undefine default

if ! kvm-ok; then
  yq e '.driver = "qemu"' $TOP_DIR/settings.yaml -i
fi

yq e '.ci = true' $TOP_DIR/settings.yaml -i

vagrant up node1
vagrant ssh node1 -c hostnamectl
