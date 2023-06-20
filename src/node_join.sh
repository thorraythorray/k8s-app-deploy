#!/bin/bash

NODE_IP=$1
MASTER_IP=$2
KUBE_CONFIG_PATH=/etc/kubernetes

function check_node_env() {
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
    fi

    if [ -e "/root/kubeadm.yaml" && ! -e $KUBE_CONFIG_PATH/kubeadm.yaml ]; then
        cp /root/admin.conf /root/kubeadm.yaml $KUBE_CONFIG_PATH/
    fi

    env | grep "KUBECONFIG"
    if [ $? != 0 ]; then
        echo "export KUBECONFIG=/etc/kubernetes/admin.conf" > /etc/profile.d/kubeconfig.sh
    fi
}


function join_cluster() {
    export KUBECONFIG=$KUBE_CONFIG_PATH/admin.conf

    crictl --runtime-endpoint=unix:///var/run/containerd/containerd.sock images | grep kube-apiserver
    if [ $? != 0 ]; then
        echo "start pull images..."
        kubeadm config images pull --config /etc/kubernetes/kubeadm.yaml
        ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9 registry.k8s.io/pause:3.6
    fi

    kubectl get nodes -A -o wide | grep "$NODE_IP"
    if [ $? != 0 ]; then
        echo "start join master ..."
        modprobe br_netfilter
        echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
        echo 1 > /proc/sys/net/ipv4/ip_forward
        # TODO 替换token
        kubeadm join 192.168.1.99:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:599d194171448604aa2c3668910c95b8c43a2e19b22c1a54c83a30bd8fb1a477
    fi
    echo "$NODE_IP joine done!"
}


function main() {
    check_node_env
    join_cluster
}


main