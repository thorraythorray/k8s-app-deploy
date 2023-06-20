#!/bin/bash
which kubeadm
if [ $? == 0 ]; then
    echo "kubeadm exists!"
else
    swapoff -a
    sed -i 's/\/swap.img/#\/swap.img/' /etc/fstab
    apt update && apt-get install -y sshpass containerd nfs-common
    echo "deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add
    apt update
    apt install -y kubeadm=1.26.3-00
    cp config/kubeadm.yaml /etc/kubernetes/
fi