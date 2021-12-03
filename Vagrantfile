
$script1 = <<-SCRIPT1
zypper ref

zypper rr -a && zypper ar  http://free.nchc.org.tw/opensuse/update/leap/15.3/oss/ update && zypper ar http://free.nchc.org.tw/opensuse/distribution/leap/15.3/repo/oss/ oss
zypper in -y apparmor-parser iptables wget

ARCH=amd64
KUBECTL_VERSION="v1.20.4"
curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

SCRIPT1


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
  end

  config.vm.provision "shell", inline: $script1
end


