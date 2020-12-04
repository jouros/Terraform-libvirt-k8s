#!/bin/bash

# Default image is only 2G, installation needs ~4G and overlay2 much more

# Resize, domain has to be running
virsh blockresize master1 /var/lib/libvirt/images/master1.qcow2 50G
virsh blockresize worker1 /var/lib/libvirt/images/worker1.qcow2 50G
virsh blockresize worker2 /var/lib/libvirt/images/worker2.qcow2 50G
virsh blockresize worker3 /var/lib/libvirt/images/worker3.qcow2 50G
virsh blockresize worker4 /var/lib/libvirt/images/worker4.qcow2 50G

# Reboot to reload new size
virsh reboot master1
virsh reboot worker1
virsh reboot worker2
virsh reboot worker3
virsh reboot worker4
