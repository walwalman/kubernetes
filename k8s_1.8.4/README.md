## 在CentOS7.2上部署kubernetes1.8.4集群




### [安装kubernetes_1.8.4](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/github_install.md)
>centos7.2部署kubernets1.8.4文档示例（内含配置文件等信息）


### [dashboard面板](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/dashboard/README.md)
>kubernetes web ui查看

![https-6443](https://raw.githubusercontent.com/zouhuigang/kubernetes/master/k8s_1.8.4/dashboard/images/20171128095851.png)


### [kube-dns](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/kube-dns/README.md)
>pod与pod之前通过类似域名的东西互相访问


### [heapster](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/heapster/README.md)
>Heapster是容器集群监控和性能分析工具，天然的支持Kubernetes和CoreOS,创建完成之后，可能需要重新创建下dashboard才会显示图像。


### [kubectl](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/kubectl.md)
>使用Https时需要更改kubectl参数，使得能正常使用！


### [traefik+ingress](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/traefik+ingress/README.md)
>Traefik是一款开源的反向代理与负载均衡工具。它最大的优点是能够与常见的微服务系统直接整合，可以实现自动化动态配置。目前支持Docker, Swarm, Mesos/Marathon, Mesos, Kubernetes, Consul, Etcd, Zookeeper, BoltDB, Rest API等等后端模型

