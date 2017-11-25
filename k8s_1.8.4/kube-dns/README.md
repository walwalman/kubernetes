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




问题汇总：

Q1：Back-off restarting failed container
Error syncing pod
Liveness probe failed: HTTP probe failed with statuscode: 503

A1：发现kube-controll.yaml的第88行有个 - --domain=cluster.local..多了个.




