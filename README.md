# Vagrantfile for testing rancherd deployment

## Requirements

- vagrant
- vagrant-libvirt


## Usage

### Cluster initialization
Edit `settings.yaml` to modify `kubernetes_version` or `rancher_version`:

```
server_ip: 192.168.121.79
kubernetes_version: v1.21.7+rke2r1
rancher_version: v2.6-11a7451ffee557897197fc624af03ac6fd34a9f0-head
```

Provision first node:

```
vagrant up node1
```

To generate a kubeconfig file, run:

```
./rke2-env.sh
```

A file called `kubeconfig` will be created and you can export `KUBECONFIG` environment variable to it.


### Add more nodes

Update `server_ip` in settings:

```
./update-server-ip.sh
```

Start second node:

```
vagrant up node2
```
