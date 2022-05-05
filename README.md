# Vagrantfile for deploying RKE2/K3s clusters with Rancherd

## Requirements

- Vagrant
- Vagrant-libvirt

## Usage

### Cluster initialization
Edit `settings.yaml` to modify `kubernetes_version` or `rancher_version`:

```
kubernetes_version: v1.23.6+k3s1
rancher_version: v2.6.4
```

Provision first node:

```
vagrant up node1
```

To generate a kubeconfig file, run:

```
./kube-env.sh
```

A file called `kubeconfig` will be created and you can export `KUBECONFIG` environment variable to it.


### Add more worker nodes

Update `server_ip` in settings:

```
./update-server-ip.sh
```

Start more worker nodes:

```
vagrant up node2
vagrant up node3
```

### Access Rancher Dashboard

We can port forward to Rancher dashboard:

```
kubectl port-forward --address <bind_address> service/rancher <bind_port>:443 -n cattle-system
```

The deafult password is the `rancher_admin_passwd` value in `settings.yaml` file.
