#!/bin/bash -eux
# The script creates a QEMU image and attaches it to a Vagrant (libvirt) VM.
#
# What the script does:
# (1) It attaches a virtio-scsi controller to a domain if the domain doesn't have a controller yet.
# (2) It detects the next available /dev/sd* device name.
# (3) Create a qcow2 file under $DISKS_DIR and attach it to the provided domain.

NODE=$1
SIZE=30

DISKS_DIR=/tmp/hotplug_disks

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VAGRANT_DEPLOY=$(basename $TOP_DIR)
CONTROLLER_XML=$SCRIPTS_DIR/controller.xml

CACHE_DIR=$TOP_DIR/.cache
SSH_CONFIG=$CACHE_DIR/ssh-config-$NODE

mkdir -p $CACHE_DIR
vagrant ssh-config $NODE > $SSH_CONFIG

NODE_DISKS=$(ssh -F $SSH_CONFIG $NODE 'ls /sys/class/block | grep -e ^sd[a-z]$' || true)

if [ -z $NODE_DISKS ];then
  TARGET="sda"
else
  # stupidly find first unused device name in sd[a-z]
  for ((i=97; i<=122; i++)); do
    TARGET="$(printf "sd\x$(printf %x $i)")"

    used="no"
    for DISK in $NODE_DISKS; do
      if [ "$TARGET" = "$DISK" ]; then 
        used="true"
        break
      fi
    done 

    if [ "$used" = "no" ]; then
      break
    fi

    if [ $i -eq 122 ]; then
      echo "[Error] Run out of device names."
      exit 1
    fi
  done
fi

echo "Going to attach $TARGET to $NODE"

DOMAIN=${VAGRANT_DEPLOY}_${NODE}

# create disk image
mkdir -p $DISKS_DIR
FILE=$DISKS_DIR/$NODE-$TARGET.qcow2
qemu-img create -f qcow2 $FILE "${SIZE}"g

# attach virtio-scsi controller, it's more robust for hotplugging
if ! virsh dumpxml $DOMAIN | grep -q 'virtio-scsi'; then
  echo "Attach virtio-scsi controller to $DOMAIN"
  virsh attach-device --domain $DOMAIN --file $CONTROLLER_XML --live
fi

# attach device
XML_FILE=$DISKS_DIR/$NODE-$TARGET.xml
cat > $XML_FILE <<EOF
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$FILE'/>
      <target dev='$TARGET' bus='scsi'/>
      <wwn>0x5000c50015$(date +%s | sha512sum | head -c 6)</wwn>
    </disk>
EOF

virsh attach-device --domain $DOMAIN --file $XML_FILE --live
