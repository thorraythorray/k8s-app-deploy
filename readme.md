#### 安装k8s
```
bash install/k8s_setup.sh
```

#### 配置各节点,註意替換node_setup.sh中的join秘鑰
```
bash install/node_launcher.sh cluster_ip
```

#### 启动
```
kubectl apply -f rbac.yaml -f nfs-pv.yaml -f apps.yaml -f nginx.yaml
```