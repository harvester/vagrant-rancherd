#!/bin/bash -e

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" &> /dev/null && pwd )"

ensure_command() {
  local cmd=$1
  if ! which $cmd &> /dev/null; then
    echo "$cmd is not installed."
    exit 1
  fi
}

wait_node_ready() {
  local node=$1
  local retries
  local status

  retries=0
  while [ true ]; do
    status=$(kubectl get nodes | grep "^$node" | awk '{print $2}')

    if [ "$status" = "Ready" ]; then
      echo "$node status is ready."
      break
    else
      echo "$node status is $status."
    fi

    if [ $retries -eq 60 ]; then
      echo "timeout to wait for $node to be ready!"
      exit 1
    fi

    retries=$((retries+1))
    echo "retry in 5 seconds..."
    sleep 5
  done
}

cluster_size=$(yq -e e '.cluster_size' $TOP_DIR/settings.yaml)

cd $TOP_DIR

# start server
echo "Start server node..."
vagrant up node1
./kube-env.sh
./update-server-ip.sh


export KUBECONFIG=$TOP_DIR/kubeconfig
while [ true ]; do
  echo "Check the first nodes status..."
  result=$(kubectl get nodes) || true
  if [[ $? -eq 0 ]]; then
    break
  fi
  echo "GET error: $result"
  echo "sleep 10 seconds and retry..."
  sleep 10
done

if [ $cluster_size -eq 1 ]; then
  echo "Skip provisioning agent nodes"
  exit 0
fi

# start agents
echo "Prepare to start agents..."
nodes=""
for (( i=2; i<=$cluster_size; i++)); do
  nodes+="node$i "
done

echo "Start agent node(s)..."
vagrant up $nodes

# check agent nodes ready
for (( i=2; i<=$cluster_size; i++)); do
  wait_node_ready "node$i"
done

kubectl get nodes