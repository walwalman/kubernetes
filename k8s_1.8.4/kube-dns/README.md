### 安装kube-dns

>官方目录：kubernetes/cluster/addons/dns


镜像下载（根据官方使用的镜像来下载）：

	docker pull gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-sidecar-amd64:1.14.5
	docker pull gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.5
	docker pull gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-kube-dns-amd64:1.14.5

	docker tag gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-sidecar-amd64:1.14.5 gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.5
	docker tag gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.5 gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.5
	docker tag gcr.mirrors.ustc.edu.cn/google_containers/k8s-dns-kube-dns-amd64:1.14.5 gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.5


查看官方文件：


	$ cd /home/kubernetes/kubernetes/cluster/addons/dns
	$ ls
	kubedns-cm.yaml               kubedns-controller.yaml.sed  kubedns-svc.yaml.in   OWNERS               transforms2sed.sed
	kubedns-controller.yaml.base  kubedns-sa.yaml              kubedns-svc.yaml.sed  README.md
	kubedns-controller.yaml.in    kubedns-svc.yaml.base        Makefile              transforms2salt.sed

	$ ls *.yaml
	kubedns-cm.yaml  kubedns-sa.yaml

说明：

	kubedns-cm.yaml和kubedns-sa.yaml不需要进行修改,直接使用

### kubedns-svc.yaml文件的生成

>kubedns-svc.yaml有三种类型的模板文件，我们使用kubedns-svc.yaml.sed文件来生成kubedns-svc.yaml文件，替换$DNS_SERVER_IP为指定IP，我们这里使用10.254.200.200，这个地址也就是之前在kubelet中指定的--cluster-dns=10.254.200.200地址。

复制文件并替换变量：

	cp kubedns-svc.yaml.sed kubedns-svc.yaml
	sed -i 's/$DNS_SERVER_IP/10.254.200.200/g' kubedns-svc.yaml


### kubedns-controller.yaml文件生成

>kubedns-controller.yaml有三种类型的模板文件，我们使用kubedns-controller.yaml.sed文件来生成kubedns-controller.yaml文件，替换$DNS_DOMAIN为cluster.local,这个也是kubelet中指定过的--cluster-domain=cluster.local。

复制文件并替换变量：

	cp kubedns-controller.yaml.sed kubedns-controller.yaml
	sed -i 's/$DNS_DOMAIN/cluster.local./g' kubedns-controller.yaml

其中的镜像可以从代理地址(如：hub.c.163.com)下载之后，tag一下，即可。


重新列出一下需要用到的文件：

	$ ls *.yaml
	kubedns-cm.yaml  kubedns-controller.yaml  kubedns-sa.yaml  kubedns-svc.yaml

### 创建kube-dns:

>注意：需要配置kubelet的启动参数--cluster-dns=10.254.200.200 --cluster-domain=cluster.local

	kubectl create -f kubedns-cm.yaml
	kubectl create -f kubedns-sa.yaml
	kubectl create -f kubedns-svc.yaml
	kubectl create -f kubedns-controller.yaml

	也可以：
	kubectl create -f .


### 测试dns是否成功

##### 方式1：

test-nginx.yaml:

	apiVersion: extensions/v1beta1
	kind: Deployment
	metadata:
	  name: dep-nginx
	spec:
	  replicas: 2
	  template:
	    metadata:
	      labels:
	        run: pod-nginx
	    spec:
	      containers:
	      - name: nginx
	        image: nginx:1.9
	        ports:
	        - containerPort: 80


创建：

	kubectl create -f test-nginx.yaml
	kubectl expose deploy dep-nginx #暴露服务
	kubectl get services --all-namespaces |grep dep-nginx
	default       dep-nginx              ClusterIP   10.254.188.157   <none>        80/TCP          37m


再启动一个pod：

pod-nginx.yaml:

	apiVersion: v1
	kind: Pod
	metadata:
	  name: nginx
	spec:
	  containers:
	  - name: nginx
	    image: nginx:1.9
	    ports:
	    - containerPort: 80

创建：

	kubectl create -f pod-nginx.yaml

验证:

> 查看 /etc/resolv.conf 是否包含 kubelet 配置的 --cluster-dns 和 --cluster-domain

	$ kubectl exec  nginx -i -t -- /bin/bash
	root@nginx:/# cat /etc/resolv.conf
	nameserver 10.254.200.200
	search default.svc.cluster.local svc.cluster.local cluster.local localdomain
	options ndots:5
	root@nginx:/# 

>是否能够将服务 my-nginx 解析到上面显示的 Cluster IP 10.254.188.157

	root@nginx:/# ping dep-nginx                                                                                                                                                                                     
	PING dep-nginx.default.svc.cluster.local (10.254.188.157): 56 data bytes
	^C--- dep-nginx.default.svc.cluster.local ping statistics ---
	332 packets transmitted, 0 packets received, 100% packet loss
	

从结果来看，service名称可以正常解析，但是ping不通，这是正常的，因为直接ping ClusterIP是ping不通的，ClusterIP是根据IPtables路由到服务的endpoint上，只有结合ClusterIP加端口才能访问到对应的服务。




##### 方式2：

pod-busybox.yaml:

	apiVersion: v1
	kind: Pod
	metadata:
	  name: busybox
	  namespace: default
	spec:
	  containers:
	  - image: busybox
	    command:
	      - sleep
	      - "3600"
	    imagePullPolicy: IfNotPresent
	    name: busybox
	  restartPolicy: Always


创建并登陆容器：

	kubectl create -f pod-busybox.yaml
	kubectl exec -it busybox -- /bin/sh

输入命令：

	nslookup kubernetes 
	或
 	kubectl exec --namespace=default busybox -- nslookup kubernetes.default


输出结果：

	/ # nslookup kubernetes
	Server:    10.254.200.200
	Address 1: 10.254.200.200 kube-dns.kube-system.svc.cluster.local
	
	Name:      kubernetes
	Address 1: 10.254.0.1 kubernetes.default.svc.cluster.local


### 查看命令

	$ kubectl get ep kube-dns --namespace=kube-system
	NAME       ENDPOINTS                       AGE
	kube-dns   10.254.69.8:53,10.254.69.8:53   5h



### 问题汇总：

Q1：Back-off restarting failed container
Error syncing pod
Liveness probe failed: HTTP probe failed with statuscode: 503

A1：发现kube-controll.yaml的第88行有个 - --domain=cluster.local..多了个.




