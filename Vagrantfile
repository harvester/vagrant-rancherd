require 'yaml'

@root_dir = File.dirname(File.expand_path(__FILE__))
@settings = YAML.load_file(File.join(@root_dir, "settings.yaml"))
$workaround = "false"

def detect_runtime
  case @settings['kubernetes_version']
  when /v1.2[23].*(k3s|rke2).*/
    $workaround = "true"
  when /v1\.21.*(k3s|rke2).*/
  else
    puts "Unsupported Kubernetes runtime #{@settings['kubernetes_version']}"
    exit(1)
  end

  runtime_type = ""

  case @settings['kubernetes_version']
  when /.*k3s.*/
    runtime_type = "k3s"
  when /.*rke2.*/
    runtime_type = "rke2"
  else
    puts "Unsupported Kubernetes runtime #{@settings['kubernetes_version']}"
    exit(1)
  end

  File.open(File.join(@root_dir, "runtime"), "w") { |f| f.write runtime_type }
end

detect_runtime

$script0 = <<-SCRIPT0
zypper ref
zypper in -y apparmor-parser iptables wget

SCRIPT0

$script1 = <<-SCRIPT1

curl -sfL https://github.com/rancher/wharfie/releases/download/v0.5.2/wharfie-amd64  -o /usr/local/bin/wharfie && chmod +x /usr/local/bin/wharfie
curl -sfL https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

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
kubernetesVersion: #{@settings['kubernetes_version']}
rancherVersion: #{@settings['rancher_version']}

EOF

mkdir -p /etc/rancher/rke2/config.yaml.d/
cat > /etc/rancher/rke2/config.yaml.d/99-test.yaml << EOF
cni: multus,canal
disable: rke2-ingress-nginx

EOF

SCRIPT1


$script2 = <<-SCRIPT2

mkdir -p /etc/rancher/rancherd
cat > /etc/rancher/rancherd/config.yaml << EOF
role: agent 
token: somethingrandom
server: https://#{@settings['server_ip']}:8443
EOF

mkdir -p /etc/rancher/rke2/config.yaml.d/
cat > /etc/rancher/rke2/config.yaml.d/99-test.yaml << EOF
cni: multus,canal
disable: rke2-ingress-nginx

EOF

SCRIPT2


$script3 = <<-SCRIPT3

set -x

if [ "#{$workaround}" = "true" ]; then
  curl -sfL https://github.com/bk201/rancherd/releases/download/v0.0.1-alpha13-bk201.1/rancherd-amd64 -o /usr/local/bin/rancherd && chmod +x /usr/local/bin/rancherd
  curl -fL https://raw.githubusercontent.com/bk201/rancherd/dev/install.sh | INSTALL_RANCHERD_SKIP_DOWNLOAD=true sh -
else
  curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -
fi

SCRIPT3

Vagrant.configure("2") do |config|
  config.vm.box = "opensuse/Leap-15.3.x86_64"

  config.vm.define "node1" do |node|
    node.vm.hostname = "node1"
    node.vm.provider "libvirt" do |lv|
      lv.connect_via_ssh = false
      lv.qemu_use_session = false
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 4096
      lv.cpus = 4

      lv.storage :file, :size => '50G'
      lv.graphics_ip = '0.0.0.0'
    end
    node.vm.provision "shell", inline: $script0
    node.vm.provision "shell", inline: $script1
    node.vm.provision "shell", inline: $script3
  end

  config.vm.define "node2" do |node|
    node.vm.hostname = "node2"
    node.vm.provider "libvirt" do |lv|
      lv.connect_via_ssh = false
      lv.qemu_use_session = false
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 4096
      lv.cpus = 4

      lv.storage :file, :size => '50G'
      lv.graphics_ip = '0.0.0.0'
    end
    node.vm.provision "shell", inline: $script0
    node.vm.provision "shell", inline: $script2
    node.vm.provision "shell", inline: $script3
  end

  config.vm.define "node3" do |node|
    node.vm.hostname = "node3"
    node.vm.provider "libvirt" do |lv|
      lv.connect_via_ssh = false
      lv.qemu_use_session = false
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 4096
      lv.cpus = 4

      lv.storage :file, :size => '50G'
      lv.graphics_ip = '0.0.0.0'
    end
    node.vm.provision "shell", inline: $script0
    node.vm.provision "shell", inline: $script2
    node.vm.provision "shell", inline: $script3
  end

  config.vm.define "node4" do |node|
    node.vm.hostname = "node4"
    node.vm.provider "libvirt" do |lv|
      lv.connect_via_ssh = false
      lv.qemu_use_session = false
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 4096
      lv.cpus = 4

      lv.storage :file, :size => '50G'
      lv.graphics_ip = '0.0.0.0'
    end
    node.vm.provision "shell", inline: $script0
    node.vm.provision "shell", inline: $script2
    node.vm.provision "shell", inline: $script3
  end
end


