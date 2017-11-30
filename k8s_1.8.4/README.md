## 在CentOS7.2上部署kubernetes1.8.4集群

### 注意事项

使用前，请先关闭防火墙！

	 systemctl stop firewalld
	 systemctl disable firewalld

以及查看linux服务器时间是否正确：

	date "+%Y-%m-%d" 


墙的问题：

	方法1：直接在docker hub和github上关联编译，生成镜像。下载走的是docker hub的网络。
	方法2：找一个代理地址，如将gcr.io替换成gcr.mirrors.ustc.edu.cn就很容易的可以下载墙外镜像了

新版本docker需要：

	iptables -P FORWARD ACCEPT



### [安装kubernetes_1.8.4](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/github_install.md)
>centos7.2部署kubernets1.8.4文档示例（内含配置文件等信息）


### [dashboard面板](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/dashboard/README.md)
>kubernetes web ui查看,cpu，内存需要安装heapster之后，再重新创建dashboard，即可看到！

![https-6443](https://raw.githubusercontent.com/zouhuigang/kubernetes/master/k8s_1.8.4/dashboard/images/20171128095851.png)


### [kube-dns](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/kube-dns/README.md)
>pod与pod之前通过类似域名的东西互相访问


### [heapster](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/heapster/README.md)
>Heapster是容器集群监控和性能分析工具，天然的支持Kubernetes和CoreOS,创建完成之后，可能需要重新创建下dashboard才会显示图像。

![https-6443](https://raw.githubusercontent.com/zouhuigang/kubernetes/master/k8s_1.8.4/heapster/images/20171128135148.png)

### [kubectl](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/kubectl.md)
>使用Https时需要更改kubectl参数，使得能正常使用！


### [traefik+ingress](https://github.com/zouhuigang/kubernetes/blob/master/k8s_1.8.4/traefik+ingress/README.md)
>Traefik是一款开源的反向代理与负载均衡工具。它最大的优点是能够与常见的微服务系统直接整合，可以实现自动化动态配置。目前支持Docker, Swarm, Mesos/Marathon, Mesos, Kubernetes, Consul, Etcd, Zookeeper, BoltDB, Rest API等等后端模型

