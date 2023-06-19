#!/bin/bash -e

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
KUBECTL="kubectl --kubeconfig=$TOP_DIR/kubeconfig"

clean_vagrant() {
  cd $TOP_DIR
  vagrant destroy -f --parallel
  rm -rf .vagrant
}

vagrant() {
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

vagrant_ssh() {
  machine=$1
  shift
  remote_command="$@"

  docker run -i --rm \
    -e LIBVIRT_DEFAULT_URI \
    -v /var/run/libvirt/:/var/run/libvirt/ \
    -v ~/.vagrant.d:/.vagrant.d \
    -v $(realpath "${PWD}"):${PWD} \
    -w $(realpath "${PWD}") \
    --network host \
    vagrantlibvirt/vagrant-libvirt:latest-slim \
      vagrant ssh $machine -c "$remote_command"
}

wait_rancherd_bootstrap() {
  node=$1

  echo "Waiting for Rancherd bootstrapped..."
  retries=0
  while [ $retries -lt 360 ]; do
    bootstrapped=$(vagrant_ssh $node sudo cat /var/lib/rancher/rancherd/bootstrapped 2>/dev/null || true)

    if [ -n "$bootstrapped" ]; then
      echo "Rancherd bootstrapped on $node."
      return
    fi

    echo -n "."
    sleep 10
    retries=$((retries+1))
  done
  echo "Timeout!"
  echo "===== Rancherd log ======"
  vagrant_ssh $node sudo journalctl -u rancherd
  exit 1
}

update_server_ip() {
  server=$1
  IP_CIDR=$(vagrant_ssh $server "ip a show eth0 | grep \"inet \" | awk '{print \$2}'" 2>/dev/null)
  IP=${IP_CIDR%/*}
  if [ -z "$IP" ]; then
    echo "Can't get node1 IP."
    exit 1
  fi
  echo "Set server IP to $IP"
  SERVER_IP=$IP yq e '.server_ip = strenv(SERVER_IP)' -i $TOP_DIR/settings.yaml
}

kube_env() {
  node=$1
  if [ ! -e $TOP_DIR/runtime ]; then
    echo "Fail to determine runtime."
    exit 1
  fi

  RUNTIME=$(cat $TOP_DIR/runtime)
  CONFIG_FILE="/etc/rancher/$RUNTIME/$RUNTIME.yaml"
  echo "Downloading $CONFIG_FILE to $TOP_DIR/kubeconfig"
  vagrant_ssh $node sudo cat $CONFIG_FILE 2>/dev/null > $TOP_DIR/kubeconfig

  IP_CIDR=$(vagrant_ssh $node "ip a show eth0 | grep \"inet \" | awk '{print \$2}'" 2>/dev/null)
  IP=${IP_CIDR%/*}
  sed -i "s,127.0.0.1:6443,$IP:6443," $TOP_DIR/kubeconfig
  cat $TOP_DIR/kubeconfig
}

wait_node_ready() {
  node=$1

  echo "Waiting for node $node to be ready..."
  retries=0
  while [ $retries -lt 180 ]; do
    node_line=$($KUBECTL get node $node | tail -n1)
    status=$(echo "$node_line" | awk '{print $2}')

    if [ "$status" = "Ready" ]; then
      echo "Node $node is ready."
      return
    fi
    echo -n "."
    sleep 10
    retries=$((retries+1))
  done
  echo "Timeout!"
  $KUBECTL get nodes
  exit 1
}

check_nodes_runtime() {
  expected_version=$1

  $KUBECTL get nodes | tail -n +2 | while read -r node_line; do
    node=$(echo "$node_line" | awk '{print $1}')
    version=$(echo "$node_line" | awk '{print $5}')
    if [ "$version" != "$expected_version" ]; then
      echo "Node ${node}'s version is $version, want $expected_version"
      exit 1
    else
      echo "Node ${node}'s version is $version. OK."
    fi
  done
}

yq e '.ci = true' $TOP_DIR/settings.yaml -i

clean_vagrant
trap clean_vagrant EXIT

vagrant up node1
wait_rancherd_bootstrap node1
kube_env node1
wait_node_ready node1
update_server_ip node1
vagrant up node2
wait_rancherd_bootstrap node2
wait_node_ready node2
check_nodes_runtime $(yq e .kubernetes_version $TOP_DIR/settings.yaml)
