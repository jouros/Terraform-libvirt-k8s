# Terraform and Ansible scripts to deploy K8s Kubernets cluster on Debian Buster KVM vm

Terraform v0.13.5

ansible 2.9.6

## Initialize empty folder
terraform init

## Set terraform-provider-libvirt for Ubuntu 20.04 (my Ansible host) 

wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Ubuntu_20.04.amd64.tar.gz

tar xvfz terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Ubuntu_20.04.amd64.tar.gz

cd .terraform/plugins

mkdir -p ./registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64

mv terraform-provider-libvirt .terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64/

Note! You probably have to setup some libvirt & qemu settings for 'permission denied' or virsh without sudo etc. things

Check parameter details for Terraform libvirt provider: https://github.com/dmacvicar/terraform-provider-libvirt


## Terraform init

terraform plan 

terraform init

## Set your variables and execute

terraform apply

## Resize default debian qcow2

./resize_default_debian_qcow2.sh

## Install master1 with Ansible

ansible-playbook master-playbook-1.yml

## Install worker nodes with Ansible

ansible-playbook node-playbook.yml

## K8s is ready, have fun :)

joro@master1:~$ kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
master1   Ready    master   27m     v1.19.4
worker1   Ready    <none>   4m18s   v1.19.4
worker2   Ready    <none>   4m18s   v1.19.4
worker3   Ready    <none>   4m18s   v1.19.4
worker4   Ready    <none>   4m18s   v1.19.4


