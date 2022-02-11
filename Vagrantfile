require 'yaml'

@root_dir = File.dirname(File.expand_path(__FILE__))
@settings = YAML.load_file(File.join(@root_dir, "settings.yaml"))

$script0 = <<-SCRIPT0
zypper ref
zypper in -y apparmor-parser iptables wget

SCRIPT0

$script1 = <<-SCRIPT1

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


curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -

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

curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -

SCRIPT2


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
  end

end


