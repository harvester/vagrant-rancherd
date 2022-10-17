require 'yaml'

$root_dir = File.dirname(File.expand_path(__FILE__))
$settings = YAML.load_file(File.join($root_dir, "settings.yaml"))
$workaround = "false"
$runtime_type = ""

def detect_runtime
  case $settings['kubernetes_version']
  when /v1.2[234].*(k3s|rke2).*/
    $workaround = "true"
  when /v1\.21.*(k3s|rke2).*/
  else
    puts "Unsupported Kubernetes runtime #{$settings['kubernetes_version']}"
    exit(1)
  end

  case $settings['kubernetes_version']
  when /.*k3s.*/
    $runtime_type = "k3s"
  when /.*rke2.*/
    $runtime_type = "rke2"
  else
    puts "Unsupported Kubernetes runtime #{$settings['kubernetes_version']}"
    exit(1)
  end

  File.open(File.join($root_dir, "runtime"), "w") { |f| f.write $runtime_type }
end

detect_runtime

$provision_prepare = <<-PROVISION_PREPARE
zypper ref
zypper in -y apparmor-parser iptables wget

PROVISION_PREPARE

$provision_server_config = <<-PROVISION_SERVER_CONFIG
cat > /etc/bash.bashrc.local <<EOF
if [ -z "$KUBECONFIG" ]; then
    if [ -e /etc/rancher/rke2/rke2.yaml ]; then
        export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
    else
        export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
    fi
fi
export PATH="${PATH}:/var/lib/rancher/rke2/bin"
if [ -z "$CONTAINER_RUNTIME_ENDPOINT" ]; then
    export CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/k3s/containerd/containerd.sock
fi
if [ -z "$IMAGE_SERVICE_ENDPOINT" ]; then
    export IMAGE_SERVICE_ENDPOINT=unix:///var/run/k3s/containerd/containerd.sock
fi

# For ctr
if [ -z "$CONTAINERD_ADDRESS" ]; then
    export CONTAINERD_ADDRESS=/run/k3s/containerd/containerd.sock
fi
EOF


mkdir -p /etc/rancher/rancherd
cat > /etc/rancher/rancherd/config.yaml << EOF
role: cluster-init
token: somethingrandom
kubernetesVersion: #{$settings['kubernetes_version']}
rancherVersion: #{$settings['rancher_version']}
rancherValues:
  noDefaultAdmin: false
  bootstrapPassword: #{$settings['rancher_admin_passwd']}
  features: multi-cluster-management=false,multi-cluster-management-agent=false
EOF

mkdir -p /etc/rancher/rke2/config.yaml.d/
cat > /etc/rancher/rke2/config.yaml.d/99-vagrant-rancherd.yaml << EOF
cni: multus,canal
disable: rke2-ingress-nginx

EOF

PROVISION_SERVER_CONFIG


$provision_worker_config = <<-PROVISION_WORKER_CONFIG

mkdir -p /etc/rancher/rancherd
cat > /etc/rancher/rancherd/config.yaml << EOF
role: agent 
token: somethingrandom
server: https://#{$settings['server_ip']}:8443
EOF

mkdir -p /etc/rancher/rke2/config.yaml.d/
cat > /etc/rancher/rke2/config.yaml.d/99-vagrant-rancherd.yaml << EOF
cni: multus,canal
disable: rke2-ingress-nginx

EOF

PROVISION_WORKER_CONFIG


$provision_rancherd = <<-PROVISION_RANCHERD
if [ "#{$workaround}" = "true" ]; then
  curl -fL https://raw.githubusercontent.com/rancher/rancherd/harvester-dev/install.sh | sh -
else
  curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -
fi

PROVISION_RANCHERD

$wait_rancherd_bootstrapped = <<-WAIT_RANCHERD

echo "Waiting for Rancherd bootstrapped..."
  retries=0
  while [ $retries -lt 120 ]; do
    bootstrapped=$(sudo cat /var/lib/rancher/rancherd/bootstrapped 2>/dev/null || true)

    if [ -n "$bootstrapped" ]; then
      echo "Rancherd bootstrapped."
      exit 0
    fi

    echo "."
    sleep 10
    retries=$((retries+1))
  done
  echo "Rancherd can't bootstrap, you can check log with:"
  echo '$ vagrant ssh node1'
  echo '$ sudo journalctl -u rancherd'
  exit 1
WAIT_RANCHERD


Vagrant.configure("2") do |config|
  config.vm.box = "opensuse/Leap-15.3.x86_64"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  (1..4).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.provider "libvirt" do |lv|
        lv.driver = $settings['driver']
        lv.connect_via_ssh = false
        lv.qemu_use_session = false

        if $settings['driver'] == 'kvm'
          lv.cpu_mode = 'host-passthrough'
        end

        lv.memory = 4096
        lv.cpus = 4

        if $settings['ci']
          lv.management_network_name = 'vagrant-libvirt-ci'
          lv.management_network_address = '192.168.124.0/24'
        end

        lv.storage :file, :size => '50G', :device => 'vdb'
        lv.graphics_ip = '0.0.0.0'
      end

      node.vm.provision "shell", inline: $provision_prepare
      # The first node is server, others are workers
      if i > 1
        node.vm.provision "shell", inline: $provision_worker_config
        node.vm.provision "shell", inline: $provision_rancherd
      else
        node.vm.provision "shell", inline: $provision_server_config
        node.vm.provision "shell", inline: $provision_rancherd
        node.vm.provision "shell", inline: $wait_rancherd_bootstrapped
      end
    end
  end
end
