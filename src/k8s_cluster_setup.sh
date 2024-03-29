#!/bin/bash
NODE_IP=$1
if [ ! $NODE_IP ]; then
    echo "node ip required"
    exit
fi
echo "$NODE_IP start deploy"

MASTER_IP='192.168.1.99'
KUBE_CONFIG_PATH=/etc/kubernetes
KUBE_HOME=$(pwd)

sshpass -p 123 scp -o StrictHostKeyChecking=no /etc/apt/sources.list root@$NODE_IP:/etc/apt/

sshpass -p 123 scp -o StrictHostKeyChecking=no $KUBE_CONFIG_PATH/admin.conf $KUBE_HOME/config/kubeadm.yaml $KUBE_HOME/src/_node_join.sh $KUBE_HOME/src/fix-kube-join.sh root@$NODE_IP:/root/

sshpass -p 123 ssh root@$NODE_IP -tt bash /root/_node_join.sh $NODE_IP $MASTER_IP