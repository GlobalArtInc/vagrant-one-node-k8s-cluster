
# Vagrantfile and Scripts to Automate Kubernetes Setup using Kubeadm

A fully automated setup for CKA, CKAD, and CKS practice labs is tested on the following systems:

- Windows
- Ubuntu Desktop
- Mac Intel-based systems

If you are MAC Silicon user, Please use the follwing repo.

- [Vagrant Kubeadm Setup on MAC Silicon](https://github.com/techiescamp/vagrant-kubeadm-mac-silicon)

## Setup Prerequisites

- A working Vagrant setup using Vagrant + VirtualBox

## TODO
Switch to ansible

## Documentation

Current k8s version for CKA, CKAD, and CKS exam: 1.29. 

The setup is updated with 1.29 cluster version.

Refer to this link for documentation full: https://devopscube.com/kubernetes-cluster-vagrant/


## Prerequisites

1. Working Vagrant setup
2. 8 Gig + RAM workstation as the Vms use 3 vCPUS and 4+ GB RAM

## For MAC/Linux Users

The latest version of Virtualbox for Mac/Linux can cause issues.

Create/edit the /etc/vbox/networks.conf file and add the following to avoid any network-related issues.
<pre>* 0.0.0.0/0 ::/0</pre>

or run below commands

```shell
sudo mkdir -p /etc/vbox/
echo "* 0.0.0.0/0 ::/0" | sudo tee -a /etc/vbox/networks.conf
```

So that the host only networks can be in any range, not just 192.168.56.0/21 as described here:
https://discuss.hashicorp.com/t/vagrant-2-2-18-osx-11-6-cannot-create-private-network/30984/23

## Bring Up the Cluster

To provision the cluster, execute the following commands.

```shell
git clone https://github.com/scriptcamp/vagrant-kubeadm-kubernetes.git
cd vagrant-kubeadm-kubernetes
vagrant plugin install vagrant-disksize
vagrant up
```
## Set Kubeconfig file variable

```shell
cd vagrant-kubeadm-kubernetes
cd configs
export KUBECONFIG=$(pwd)/config
```

or you can copy the config file to .kube directory.

```shell
cp config ~/.kube/
```

## Install Kubernetes Dashboard

The dashboard is automatically installed by default, but it can be skipped by commenting out the dashboard version in _settings.yaml_ before running `vagrant up`.

If you skip the dashboard installation, you can deploy it later by enabling it in _settings.yaml_ and running the following:
```shell
vagrant ssh -c "/vagrant/scripts/dashboard.sh" master
```

## Kubernetes Dashboard Access

To get the login token, copy it from _config/token_ or run the following command:
```shell
kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}"
```

Make the dashboard accessible:
```shell
kubectl proxy
```

Open the site in your browser:
```shell
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
```

## Post Install
```shell
vagrant ssh -c "/vagrant/scripts/helm.sh" master
vagrant ssh -c "/vagrant/scripts/configure/ingress.sh" master
vagrant ssh -c "/vagrant/scripts/configure/dashboard.sh" master
vagrant ssh -c "/vagrant/scripts/configure/local-path-provisioner.sh" master
vagrant ssh -c "/vagrant/scripts/configure/registry.sh" master
```

## To shutdown the cluster,

```shell
vagrant halt
```

## To restart the cluster,

```shell
vagrant up
```

## To destroy the cluster,

```shell
vagrant destroy -f
```

