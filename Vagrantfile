
$script1 = <<-SCRIPT1
zypper ref

zypper in -y apparmor-parser iptables wget


mkdir -p /etc/rancher/rke2/config.yaml.d/

cat > /etc/rancher/rke2/config.yaml.d/90-harvester-server.yaml <<EOF
disable: rke2-ingress-nginx
EOF

mkdir -p /etc/rancher/rancherd
cat > /etc/rancher/rancherd/config.yaml << EOF
role: cluster-init
token: somethingrandom
kubernetesVersion: stable:rke2
rancherVersion: v2.6-44b8030a00b29f9f5354c645f3a90ede2eea53e0-head
rancherValues:
  features: multi-cluster-management=false
EOF

curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -

SCRIPT1


Vagrant.configure("2") do |config|
  config.vm.box = "opensuse/Leap-15.3.x86_64"

  config.vm.define "node1" do |node|
    node.vm.hostname = "node1"
    node.vm.provider "libvirt" do |lv|
      lv.connect_via_ssh = false
      lv.qemu_use_session = false
      lv.cpu_mode = 'host-passthrough'
      lv.memory = 2048
      lv.cpus = 4

      lv.storage :file, :size => '50G'
      lv.graphics_ip = '0.0.0.0'
    end
  end

  config.vm.provision "shell", inline: $script1
end


