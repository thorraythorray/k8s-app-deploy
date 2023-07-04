## 部署安装
##### 安装k8s
```
bash src/k8s_setup.sh
```

##### 初始化
```
kubeadm --config config/kubeadm.yaml init
```

##### 安装网络插件
```
kubectl apply -f config/kube-flannel.yml
```

##### 配置各节点,註意替換node_join.sh中的join秘钥
```
bash src/k8s_cluster_setup.sh 192.168.1.22
```

#### 重新生成join token
```
kubeadm token create --print-join-command
```

##### 启动
```
kubectl apply -f rbac.yaml 
kubectl apply -f nfs-pv.yaml 
kubectl apply -f apps.yaml -f nginx.yaml
```

##### 部署https nginx configmap
```
# 主节点生成的server-key.pem server-cert.pem,用configmap会自动改名为tls.pem,tls.key
cd /root/ssl && kubectl create secret tls tls-secret --key server-key.pem --cert server-cert.pem
```

##### cert过期查看
```
kubeadm certs check-expiration
```

## 问题（持续更新）

dial tcp 192.168.1.99:6443: connect: connection refused
```
# kube-apiserver依赖etcd的2379端口，先查看etcd的容器有没有问题。重启kubelet后去查看容器log
systemctl restart kubelet
crictl --runtime-endpoint=unix:////var/run/containerd/containerd.sock ps -a
crictl --runtime-endpoint=unix:////var/run/containerd/containerd.sock logs 
```

kubeadm init error: CRI v1 runtime API is not implemented  
```
# 需要重新安装containerd.io
apt purge containerd.io
apt update # docker源
apt install containerd.io
rm /etc/containerd/config.toml
systemctl restart containerd
```

[ERROR CRI]: container runtime is not running
```
rm -rf /etc/containerd/config.toml
systemctl restart containerd
```

failed to get sandbox image \"registry.k8s.io/pause:3.6\": failed to pull image \"registry.k8s.io/pause:3.6\"
```
crictl --runtime-endpoint=unix:///run/containerd/containerd.sock images
ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9 registry.k8s.io/pause:3.6
```

The Service "redis-service" is invalid: spec.ports[0].nodePort: Invalid value: 6379: provided port is not in the valid range. The range of valid ports is 30000-32767
```
vim /etc/kubernetes/manifests/kube-apiserver.yaml 
# add:
- --service-node-port-range=1-65535

systemctl restart kubelet
```

Unexpected error getting claim reference to claim "mysql-sts/mysql-pvc-mysql-0": selfLink was empty, can't make reference
```
# nfs使用这个镜像
registry.cn-beijing.aliyuncs.com/pylixm/nfs-subdir-external-provisioner:v4.0.0
```

/proc/sys/net/bridge/bridge-nf-call-iptables does not exist
```
modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
```

同时存在cri-docker和contained sock，需要查看/etc/crictl.yaml使用的是哪一个socks
```
vim /etc/crictl.yaml

# runtime-endpoint: unix:///var/run/containerd/containerd.sock
# image-endpoint: unix:///var/run/containerd/containerd.sock
```

nfs无挂载权限
```
#添加no_root_squash权限
vim /etc/exports
/mnt/share 192.168.1.230(rw,sync,no_subtree_check,no_root_squash)
```