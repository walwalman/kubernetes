k8s 1.8.5实践
---
### 下载：

	mkdir -p /home/kubernetes && cd /home/kubernetes 
	wget https://github.com/kubernetes/kubernetes/releases/download/v1.8.5/kubernetes.tar.gz
	tar -xzvf kubernetes.tar.gz
	cd /home/kubernetes/kubernetes
	./cluster/get-kube-binaries.sh
	选择y之后，开始下载（kubernetes-server-linux-amd64.tar.gz和kubernetes-client-linux-amd64.tar.gz）...


下载完成之后，会在/home/kubernetes/kubernetes/server目录下看到：

	kubernetes-server-linux-amd64.tar.gz


/home/kubernetes/kubernetes/client目录下看到：

	kubernetes-client-linux-amd64.tar.gz





### 解压使用server端:

>说明:kubernetes-server-linux-amd64.tar.gz 已经包含了 client(kubectl) 二进制文件，所以不用单独下载kubernetes-client-linux-amd64.tar.gz文件

	cd /home/kubernetes/kubernetes/server
	tar -xzvf kubernetes-server-linux-amd64.tar.gz
	cd /home/kubernetes/kubernetes/server/kubernetes
	tar -xzvf kubernetes-src.tar.gz
	#将二进制文件拷贝到指定路径
	cd /home/kubernetes/kubernetes/server/kubernetes && cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /usr/local/bin/
	

检查文件:

	$ cd /usr/local/bin && ls kube*
	kube-apiserver  kube-controller-manager  kubectl  kubelet  kube-proxy  kube-scheduler




### 创建kubeconfig 文件

>kubernetes 1.4 开始支持由 kube-apiserver 为客户端生成 TLS 证书的 TLS Bootstrapping 功能，这样就不需要为每个客户端生成证书了；该功能当前仅支持为 kubelet 生成证书


	cd /etc/kubernetes/
	
	export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
	cat > token.csv <<EOF
	${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
	EOF

将生成token.cvs

	更新 token.csv 文件，分发到所有机器 (master 和 node）的 /etc/kubernetes/ 目录下，分发到node节点上非必需；
	重新生成 bootstrap.kubeconfig 文件，分发到所有 node 机器的 /etc/kubernetes/ 目录下；
	重启 kube-apiserver 和 kubelet 进程；
	重新 approve kubelet 的 csr 请求；



### bootstrap.kubeconfig


	cd /etc/kubernetes
	
	export KUBE_APISERVER="https://47.100.76.132:6443"
	
	kubectl config set-cluster kubernetes \
	  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
	  --embed-certs=true \
	  --server=${KUBE_APISERVER} \
	  --kubeconfig=bootstrap.kubeconfig


设置客户端认证参数

	kubectl config set-credentials kubelet-bootstrap \
  	--token=${BOOTSTRAP_TOKEN} \
  	--kubeconfig=bootstrap.kubeconfig

设置上下文参数

	kubectl config set-context default \
  	--cluster=kubernetes \
  	--user=kubelet-bootstrap \
  	--kubeconfig=bootstrap.kubeconfig


设置默认上下文

	kubectl config use-context default --kubeconfig=bootstrap.kubeconfig


### kube-proxy.kubeconfig

	export KUBE_APISERVER="https://47.100.76.132:6443"
	kubectl config set-cluster kubernetes \
		--certificate-authority=/etc/kubernetes/ssl/ca.pem \
		--embed-certs=true \
		--server=${KUBE_APISERVER} \
		--kubeconfig=kube-proxy.kubeconfig

设置客户端认证参数

	kubectl config set-credentials kube-proxy \
	  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
	  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
	  --embed-certs=true \
	  --kubeconfig=kube-proxy.kubeconfig

设置上下文参数

	kubectl config set-context default \
  	--cluster=kubernetes \
  	--user=kube-proxy \
  	--kubeconfig=kube-proxy.kubeconfig

设置默认上下文

	kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
	

### 分发 kubeconfig 文件
将两个 kubeconfig 文件分发到所有 Node 机器的 /etc/kubernetes/ 目录

	cp bootstrap.kubeconfig kube-proxy.kubeconfig /etc/kubernetes/



### kubectl 命令配置https

	export KUBE_APISERVER="https://47.100.76.132:6443"
	# 设置集群参数
	kubectl config set-cluster kubernetes \
	  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
	  --embed-certs=true \
	  --server=${KUBE_APISERVER}
	# 设置客户端认证参数
	kubectl config set-credentials admin \
	  --client-certificate=/etc/kubernetes/ssl/admin.pem \
	  --embed-certs=true \
	  --client-key=/etc/kubernetes/ssl/admin-key.pem
	# 设置上下文参数
	kubectl config set-context kubernetes \
	  --cluster=kubernetes \
	  --user=admin
	# 设置默认上下文
	kubectl config use-context kubernetes



### 启动apiserver



vi /usr/lib/systemd/system/kube-apiserver.service	


	[Unit]
	Description=Kubernetes API Service
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	After=network.target
	After=etcd.service
	
	[Service]
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/apiserver
	ExecStart=/usr/local/bin/kube-apiserver \
		    $KUBE_LOGTOSTDERR \
		    $KUBE_LOG_LEVEL \
		    $KUBE_ETCD_SERVERS \
		    $KUBE_API_ADDRESS \
		    $KUBE_API_PORT \
		    $KUBELET_PORT \
		    $KUBE_ALLOW_PRIV \
		    $KUBE_SERVICE_ADDRESSES \
		    $KUBE_ADMISSION_CONTROL \
		    $KUBE_API_ARGS
	Restart=on-failure
	Type=notify
	LimitNOFILE=65536
	
	[Install]
	WantedBy=multi-user.target


修改开始启动程序的路径：

	ExecStart=/usr/local/bin/kube-apiserver


配置：
	
	mkdir -p /etc/kubernetes && cd /etc/kubernetes


vi config

	###
	# kubernetes system config
	#
	# The following values are used to configure various aspects of all
	# kubernetes services, including
	#
	#   kube-apiserver.service
	#   kube-controller-manager.service
	#   kube-scheduler.service
	#   kubelet.service
	#   kube-proxy.service
	# logging to stderr means we get it in the systemd journal
	KUBE_LOGTOSTDERR="--logtostderr=true"
	
	# journal message level, 0 is debug
	KUBE_LOG_LEVEL="--v=0"
	
	# Should this cluster be allowed to run privileged docker containers
	KUBE_ALLOW_PRIV="--allow-privileged=false"
	
	# How the controller-manager, scheduler, and proxy find the apiserver
	KUBE_MASTER="--master=http://47.100.76.132:8080"
	#KUBE_ETCD_SERVERS="--etcd_servers=http://47.100.76.132:4001"


该配置文件同时被kube-apiserver、kube-controller-manager、kube-scheduler、kubelet、kube-proxy使用


vi apiserver

	###
	# kubernetes system config
	#
	# The following values are used to configure the kube-apiserver
	#
	
	# The address on the local server to listen to.
	KUBE_API_ADDRESS="--advertise-address=47.100.76.132 --bind-address=47.100.76.132 --insecure-bind-address=47.100.76.132"
	
	# The port on the local server to listen on.
	#KUBE_API_PORT="--port=8080"
	KUBE_API_PORT="--insecure-port=8080 --secure-port=6443"
	
	# Port minions listen on
	#KUBELET_PORT="--kubelet-port=10250"
	
	# Comma separated list of nodes in the etcd cluster
	KUBE_ETCD_SERVERS="--etcd-servers=https://47.100.76.132:2379"
	
	# Address range to use for services
	KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
	
	# default admission control policies
	KUBE_ADMISSION_CONTROL="--admission-control=ServiceAccount,NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"
	
	# Add your own!
	KUBE_API_ARGS="--authorization-mode=RBAC,Node --runtime-config=rbac.authorization.k8s.io/v1beta1 --kubelet-https=true --experimental-bootstrap-token-auth --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=30000-32767 --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem --enable-swagger-ui=true --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/lib/audit.log --event-ttl=1h"


启动apiserver:

	systemctl daemon-reload
	systemctl enable kube-apiserver
	systemctl start kube-apiserver


启动失败(journalctl -xe):

	Flag --kubelet-port has been deprecated, kubelet-port is deprecated and will be removed.
	invalid authentication config: open /etc/kubernetes/token.csv: no such file or directory
	
讲apiserver中的配置:

	#KUBELET_PORT="--kubelet-port=10250" 注释掉

	查看kubeconfig生成token.cvs


### kube-controller-manage启动

vi /etc/kubernetes/controller-manager

	###
	# The following values are used to configure the kubernetes controller-manager
	
	# defaults from config and apiserver should be adequate
	
	# Add your own!
	KUBE_CONTROLLER_MANAGER_ARGS="--address=127.0.0.1 \
								--service-cluster-ip-range=10.254.0.0/16 \
								--cluster-name=kubernetes \
								--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
								--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \
								--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \
								--root-ca-file=/etc/kubernetes/ssl/ca.pem \
								--leader-elect=true"

vi /usr/lib/systemd/system/kube-controller-manager.service

	[Unit]
	Description=Kubernetes Controller Manager
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	
	[Service]
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/controller-manager
	User=root
	ExecStart=/usr/local/bin/kube-controller-manager \
	            $KUBE_LOGTOSTDERR \
	            $KUBE_LOG_LEVEL \
	            $KUBE_MASTER \
	            $KUBE_CONTROLLER_MANAGER_ARGS
	Restart=on-failure
	LimitNOFILE=65536
	
	[Install]
	WantedBy=multi-user.target


启动kube-controller-manager

	systemctl daemon-reload
	systemctl enable kube-controller-manager
	systemctl start kube-controller-manager

启动报错:

	controllermanager.go:156] error starting controllers: error reading key for service account token controller: open /var/

	检查/etc/kubernetes/controller-manager配置



### kube-scheduler 启动

vi /usr/lib/systemd/system/kube-scheduler.service

	[Unit]
	Description=Kubernetes Scheduler Plugin
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	
	[Service]
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/scheduler
	User=root
	ExecStart=/usr/local/bin/kube-scheduler \
	            $KUBE_LOGTOSTDERR \
	            $KUBE_LOG_LEVEL \
	            $KUBE_MASTER \
	            $KUBE_SCHEDULER_ARGS
	Restart=on-failure
	LimitNOFILE=65536
	
	[Install]
	WantedBy=multi-user.target

vi /etc/kubernetes/scheduler

	###
	# kubernetes scheduler config
	
	# default config should be adequate
	
	# Add your own!
	KUBE_SCHEDULER_ARGS="--leader-elect=true --address=127.0.0.1 --master=http://47.100.76.132:8080"


启动:

	systemctl daemon-reload
 	systemctl enable kube-scheduler
 	systemctl start kube-scheduler


验证:

	$ curl -k http://47.100.76.132:8080/version
	{
	  "major": "1",
	  "minor": "8",
	  "gitVersion": "v1.8.5",
	  "gitCommit": "cce11c6a185279d037023e02ac5249e14daa22bf",
	  "gitTreeState": "clean",
	  "buildDate": "2017-12-07T16:05:18Z",
	  "goVersion": "go1.8.3",
	  "compiler": "gc",
	  "platform": "linux/amd64"
	}


kubectl验证:

	$ kubectl version
	Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.5", GitCommit:"cce11c6a185279d037023e02ac5249e14daa22bf", GitTreeState:"clean", BuildDate:"2017-12-07T16:16:03Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
	Server Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.5", GitCommit:"cce11c6a185279d037023e02ac5249e14daa22bf", GitTreeState:"clean", BuildDate:"2017-12-07T16:05:18Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}


node部分
---

### kubelet启动

	cd /etc/kubernetes

	#创建clusterrolebinding "kubelet-bootstrap" created
	kubectl create clusterrolebinding kubelet-bootstrap \
  	--clusterrole=system:node-bootstrapper \
  	--user=kubelet-bootstrap

--user=kubelet-bootstrap 是在 /etc/kubernetes/token.csv 文件中指定的用户名，同时也写入了 /etc/kubernetes/bootstrap.kubeconfig 文件


vi /usr/lib/systemd/system/kubelet.service

	[Unit]
	Description=Kubernetes Kubelet Server
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	After=docker.service
	Requires=docker.service
	
	[Service]
	WorkingDirectory=/var/lib/kubelet
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/kubelet
	ExecStart=/usr/local/bin/kubelet \
	            $KUBE_LOGTOSTDERR \
	            $KUBE_LOG_LEVEL \
	            $KUBELET_API_SERVER \
	            $KUBELET_ADDRESS \
	            $KUBELET_PORT \
	            $KUBELET_HOSTNAME \
	            $KUBE_ALLOW_PRIV \
	            $KUBELET_POD_INFRA_CONTAINER \
	            $KUBELET_ARGS
	Restart=on-failure
	
	[Install]
	WantedBy=multi-user.target


vi /etc/kubernetes/kubelet


	###
	# kubernetes kubelet (minion) config
	
	# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
	KUBELET_ADDRESS="--address=0.0.0.0"
	
	# The port for the info server to serve on
	KUBELET_PORT="--port=10250"
	
	# You may leave this blank to use the actual hostname
	KUBELET_HOSTNAME="--hostname-override=47.100.76.132"
	
	
	# pod infrastructure container
	KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest"
	
	# Add your own!
	KUBELET_ARGS="--cluster_dns=10.254.200.200 \
	--cluster-domain=cluster.local \
	--cgroup-driver=systemd  \
	--experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
	--kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
	--cert-dir=/etc/kubernetes/ssl \
	--hairpin-mode promiscuous-bridge \
	--serialize-image-pulls=false"


创建目录

	mkdir -p /var/lib/kubelet

启动:

	systemctl daemon-reload
	systemctl enable kubelet
	systemctl start kubelet
	systemctl status kubelet

如果发现:

	Flag --require-kubeconfig has been deprecated, You no longer need to use --require-kubeconfig. This will be removed in a future version. Providing --kubeconfig enables API server mode, omitting --kubeconfig enables standalone mode unless --require-kubeconfig=true is also set. In the latter case, the legacy default kubeconfig path will be used until --require-kubeconfig is removed.

	删除Kubelet中的

	--require-kubeconfig \



kubelet 首次启动时向 kube-apiserver 发送证书签名请求，必须通过后 kubernetes 系统才会将该 Node 加入到集群。

 —kubeconfig=/etc/kubernetes/kubelet.kubeconfig中指定的kubelet.kubeconfig文件在第一次启动kubelet之前并不存在，

当通过CSR请求后会自动生成kubelet.kubeconfig文件，如果你的节点上已经生成了~/.kube/config文件，你可以将该文件拷贝到该路径下，并重命名为kubelet.kubeconfig，所有node节点可以共用同一个kubelet.kubeconfig文件，这样新添加的节点就不需要再创建CSR请求就能自动添加到kubernetes集群中。

同样，在任意能够访问到kubernetes集群的主机上使用kubectl —kubeconfig命令操作集群时，只要使用~/.kube/config文件就可以通过权限认证，因为这里面已经有认证信息并认为你是admin用户，对集群拥有所有权限


查看证书：

	[root@k8s-master1 kubernetes]#  kubectl get csr
	NAME                                                   AGE       REQUESTOR           CONDITION
	node-csr-oNpWoG411qiTyNekfYmWbU6PY0aXFQy5ZIETCEzdcCA   11m       kubelet-bootstrap   Pending
	[root@k8s-master1 kubernetes]# 

通过证书（上面的Pending表示未授权的CSR 请求）：

	[root@localhost ~]#  kubectl certificate approve node-csr-oNpWoG411qiTyNekfYmWbU6PY0aXFQy5ZIETCEzdcCA
	certificatesigningrequest "node-csr-oNpWoG411qiTyNekfYmWbU6PY0aXFQy5ZIETCEzdcCA" approved
	[root@localhost ~]# 

再次查看证书:

	[root@k8s-master1 kubernetes]#  kubectl get csr
	NAME                                                   AGE       REQUESTOR           CONDITION
	node-csr-oNpWoG411qiTyNekfYmWbU6PY0aXFQy5ZIETCEzdcCA   12m       kubelet-bootstrap   Approved,Issued
	[root@k8s-master1 kubernetes]# 


自动生成了 kubelet kubeconfig 文件和公私钥：

	[root@k8s-master1 kubernetes]# ls -l /etc/kubernetes/kubelet.kubeconfig
	-rw------- 1 root root 2280 Dec 14 14:27 /etc/kubernetes/kubelet.kubeconfig

	[root@k8s-master1 kubernetes]#  ls -l /etc/kubernetes/ssl/kubelet*
	-rw-r--r-- 1 root root 1046 Dec 14 14:27 /etc/kubernetes/ssl/kubelet-client.crt
	-rw------- 1 root root  227 Dec 14 14:15 /etc/kubernetes/ssl/kubelet-client.key
	-rw-r--r-- 1 root root 1115 Dec 14 14:15 /etc/kubernetes/ssl/kubelet.crt
	-rw------- 1 root root 1675 Dec 14 14:15 /etc/kubernetes/ssl/kubelet.key
	[root@k8s-master1 kubernetes]# 


注：假如你更新kubernetes的证书，只要没有更新token.csv，当重启kubelet后，该node就会自动加入到kuberentes集群中，而不会重新发送certificaterequest，也不需要在master节点上执行kubectl certificate approve操作。前提是不要删除node节点上的/etc/kubernetes/ssl/kubelet*和/etc/kubernetes/kubelet.kubeconfig文件。否则kubelet启动时会提示找不到证书而失败



### 查看Node是否注册到了master中:

	[root@k8s-master1 kubernetes]# kubectl get node
	NAME            STATUS    ROLES     AGE       VERSION
	47.100.76.132   Ready     <none>    2m        v1.8.5
	[root@k8s-master1 kubernetes]# 


### kube-proxy启动

vi /usr/lib/systemd/system/kube-proxy.service

	[Unit]
	Description=Kubernetes Kube-Proxy Server
	Documentation=https://github.com/GoogleCloudPlatform/kubernetes
	After=network.target
	
	[Service]
	EnvironmentFile=-/etc/kubernetes/config
	EnvironmentFile=-/etc/kubernetes/proxy
	ExecStart=/usr/local/bin/kube-proxy \
	            $KUBE_LOGTOSTDERR \
	            $KUBE_LOG_LEVEL \
	            $KUBE_MASTER \
	            $KUBE_PROXY_ARGS
	Restart=on-failure
	LimitNOFILE=65536
	
	[Install]
	WantedBy=multi-user.target



vi /etc/kubernetes/proxy

	###
	# kubernetes proxy config
	
	# default config should be adequate
	
	# Add your own!
	KUBE_PROXY_ARGS="--bind-address=47.100.76.132 \
	--hostname-override=47.100.76.132 \
	--kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
	--cluster-cidr=10.254.0.0/16"


启动kube-proxy:

	systemctl daemon-reload
	systemctl enable kube-proxy
	systemctl start kube-proxy
	systemctl status kube-proxy



测试验证：

	kubectl run nginx --replicas=2 --labels="run=load-balancer-example" --image=nginx:1.9  --port=80
	kubectl expose deployment nginx --type=NodePort --name=example-service

查看

	[root@k8s-master1 kubernetes]#  kubectl get pods  -o wide
	NAME                    READY     STATUS              RESTARTS   AGE       IP        NODE
	nginx-c999fd64f-2fkzz   0/1       ContainerCreating   0          3m        <none>    47.100.76.132
	nginx-c999fd64f-prphp   0/1       ContainerCreating   0          3m        <none>    47.100.76.132
	[root@k8s-master1 kubernetes]# kubectl describe pod nginx-c999fd64f-2fkzz


运行成功

	[root@k8s-master1 kubernetes]#  kubectl get pods  -o wide
	NAME                    READY     STATUS    RESTARTS   AGE       IP            NODE
	nginx-c999fd64f-2fkzz   1/1       Running   0          13m       10.254.65.2   47.100.76.132
	nginx-c999fd64f-prphp   1/1       Running   0          13m       10.254.65.3   47.100.76.132
	[root@k8s-master1 kubernetes]# 
	 

验证(查看访问地址)：

	$ kubectl describe svc example-service
	Name:                     example-service
	Namespace:                default
	Labels:                   run=load-balancer-example
	Annotations:              <none>
	Selector:                 run=load-balancer-example
	Type:                     NodePort
	IP:                       10.254.6.45
	Port:                     <unset>  80/TCP
	TargetPort:               80/TCP
	NodePort:                 <unset>  31090/TCP
	Endpoints:                10.254.65.2:80,10.254.65.3:80
	Session Affinity:         None
	External Traffic Policy:  Cluster
	Events:                   <none>

测试访问地址:

 	curl 10.254.65.2:80


问题汇总：

Q1：

	$ kubectl get node
	NAME            STATUS     ROLES     AGE       VERSION
	47.100.76.132   NotReady   <none>    5d        v1.8.5

A1：

	kubectl delete node 47.100.76.132

	systemctl restart kubelet
	

Q2:
	etcd不能启动
	the server is already initialized as member before, starting as etcd member
	
A2:

	rm -rf /var/lib/etcd2
	还是不行
	删除重安装etcd
	vi /etc/etcd/etcd.conf


q3:

	Failed at step CHDIR spawning /usr/bin/etcd: No such file or directory

	Failed at step CHDIR spawning /usr/bin/etcd: No such file or directory

A3:

	vi /usr/lib/systemd/system/etcd.service将User=etcd改为:
	User=root

	#启动
	systemctl daemon-reload
	systemctl restart etcd

	发现还是有问题，
	WorkingDirectory=/var/lib/etcd 这个目录没创建
	mkdir -p /var/lib/etcd


Q4:

	[root@k8s-master1 etcd]# etcdctl  set /coreos.com/network/config '{"Network":"10.254.0.0/16"}'
	Error:  client: etcd cluster is unavailable or misconfigured; error #0: dial tcp 127.0.0.1:2379: getsockopt: connection refused
	; error #1: dial tcp 127.0.0.1:4001: getsockopt: connection refused
	
	error #0: dial tcp 127.0.0.1:2379: getsockopt: connection refused
	error #1: dial tcp 127.0.0.1:4001: getsockopt: connection refused


A4:

	etcd is configured but not etcdctl. Try setting the environment variable ETCDCTL_ENDPOINTS=http://10.11.51.166:2379 for etcdctl or adding an internal client listener on 127.0.0.1 via ETCD_LISTEN_CLIENT_URLS="http://10.11.51.166:2379,http://127.0.0.1:2379" for etcd so the etcdctl defaults work.

	https://github.com/coreos/etcd/issues/7349

	我的方法是修改:
	vi /etc/etcd/etcd.conf
	ETCD_LISTEN_CLIENT_URLS="http://47.100.76.132:2379,http://127.0.0.1:2379"



Q5 : POD不能访问外网的问题


A5：
	
	===============================
	=  pod->docker0网卡->外网      =
	=  pod->Flannel网卡->其他pod   =
	===============================

安装traceroute

	yum install -y traceroute

#查看pod中的默认网卡

	[root@k8s-master1 ~]# kubectl exec busybox -- ifconfig
	eth0      Link encap:Ethernet  HWaddr 02:42:0A:FE:03:06  
	          inet addr:10.254.3.6  Bcast:0.0.0.0  Mask:255.255.255.0
	          inet6 addr: fe80::42:aff:fefe:306/64 Scope:Link
	          UP BROADCAST RUNNING MULTICAST  MTU:1472  Metric:1
	          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
	          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
	          collisions:0 txqueuelen:0 
	          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)
	
	lo        Link encap:Local Loopback  
	          inet addr:127.0.0.1  Mask:255.0.0.0
	          inet6 addr: ::1/128 Scope:Host
	          UP LOOPBACK RUNNING  MTU:65536  Metric:1
	          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
	          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
	          collisions:0 txqueuelen:1 
	          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
	
	[root@k8s-master1 ~]# 

pod中的默认网卡为eth0

### master服务器上的网卡

	[root@k8s-master1 ~]# ifconfig
	docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1472
	        inet 10.254.3.1  netmask 255.255.255.0  broadcast 0.0.0.0
	        ether 02:42:11:b4:9c:57  txqueuelen 0  (Ethernet)
	        RX packets 29704  bytes 10027848 (9.5 MiB)
	        RX errors 0  dropped 0  overruns 0  frame 0
	        TX packets 29038  bytes 13013719 (12.4 MiB)
	        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
	
	eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
	        inet 10.81.128.152  netmask 255.255.252.0  broadcast 10.81.131.255
	        ether 00:16:3e:04:69:07  txqueuelen 1000  (Ethernet)
	        RX packets 2322  bytes 273695 (267.2 KiB)
	        RX errors 0  dropped 0  overruns 0  frame 0
	        TX packets 3745  bytes 298249 (291.2 KiB)
	        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
	
	eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
	        inet 47.100.76.132  netmask 255.255.252.0  broadcast 47.100.79.255
	        ether 00:16:3e:04:5a:0f  txqueuelen 1000  (Ethernet)
	        RX packets 129087  bytes 45184233 (43.0 MiB)
	        RX errors 0  dropped 0  overruns 0  frame 0
	        TX packets 60916  bytes 72327928 (68.9 MiB)
	        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
	
	flannel0: flags=4305<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST>  mtu 1472
	        inet 10.254.3.0  netmask 255.255.0.0  destination 10.254.3.0
	        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 500  (UNSPEC)
	        RX packets 1679  bytes 94024 (91.8 KiB)
	        RX errors 0  dropped 0  overruns 0  frame 0
	        TX packets 1679  bytes 120944 (118.1 KiB)
	        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

 traceroute 8.8.8.8

查看eth0设备的IP，这个IP应该就是之前traceroute得到的IP


	在Master节点运行ifconfig，我们看到flannel0网卡的IP和之前Pod里的默认网卡的网段是重叠的。所以Pod中的请求就会走这个设备。

	Pod访问公网应该走的是节点上的Docker0设备。flannel0是Flannel的虚拟网卡，这个网络自然是不通外网的。为了解决这个问题，我们运行：
	
	/sbin/iptables -t nat -I POSTROUTING -s 10.254.3.0/24 -j MASQUERADE
	其中10.254.3.0/24就是flannel0设备的IP。


查看iptables:

	iptables -t nat -L -n

发现:

	Chain POSTROUTING (policy ACCEPT)
	target     prot opt source               destination         
	MASQUERADE  all  --  10.254.3.0/24        0.0.0.0/0           
	KUBE-POSTROUTING  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes postrouting rules */
	MASQUERADE  all  --  10.254.3.0/24        0.0.0.0/0      


之前就有这条规则

	MASQUERADE  all  --  10.254.3.0/24        0.0.0.0/0    

没办法了!!

修改
	/usr/lib/sysctl.d/00-system.conf

	net.bridge.bridge-nf-call-iptables=1
	net.bridge.bridge-nf-call-ip6tables=1



修改网络

主要是开启桥接相关支持，这个是 flannel 需要的配置，具体是否需要，看自己的网络组件选择的是什么。

修改/usr/lib/sysctl.d/00-system.conf,将net.bridge.bridge-nf-call-iptables改成1.之后修改当前内核状态

	echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables


	iptables -P FORWARD ACCEPT（关闭:iptables -P FORWARD DROP）




参考文档:

	https://www.tuicool.com/articles/uERzUvm
	http://zxc0328.github.io/2017/10/26/k8s-setup-1-7/
	http://dockone.io/question/1350
	http://dockone.io/question/1301
	https://github.com/kubernetes/kubernetes/issues/40182
	https://github.com/k8sp/sextant/issues/525
	
	https://github.com/JunfeiYang/Python_project/issues/1


### 上面一堆操作之后，又发现了之前遇到的难题，之前是重启服务器，重装软件发现没问题了，现在终于发现又问题了dial tcp 10.254.0.1:443: i/o timeout

https://10.254.0.1:443/api/v1/services?resourceVersion=0: dial tcp 10.254.0.1:443: i/o timeout

出在了flanneld上，停止了，就能访问


解决方案：

	  curl -v https://10.254.0.1
	  systemctl stop flanneld
	  systemctl stop docker
	  ip link delete docker0 #删除虚拟网卡

启动即可：

	systemctl start flanneld
	systemctl start docker
	systemctl start kubelet





### iptables 如果没有重要规则，执行清空
	iptables -P INPUT ACCEPT
	iptables -F



删除转发
	iptables -t nat -nL --line-number
	iptables -t nat -D POSTROUTING 1  //删除nat表中postrouting的第一条规则 

	在nat表中postrouting的最后插入
	iptables -t nat -A POSTROUTING -s 10.254.3.0/24 -j MASQUERADE

	ping -c 3 www.baidu.com

	docker exec xxx ping -c 3 www.baidu.com
	
最后发现是docker不能访问外网的问题

测试：

	docker run --name test -d -t -i nginx：1.9

	docker exec de7f1336 ping -c 3 www.baidu.com

	[root@k8s-master1 ~]# docker exec de7f1336 ping -c 3 www.baidu.com
	PING www.a.shifen.com (220.181.111.188): 56 data bytes
	64 bytes from 220.181.111.188: icmp_seq=0 ttl=50 time=29.240 ms
	64 bytes from 220.181.111.188: icmp_seq=1 ttl=50 time=29.268 ms
	64 bytes from 220.181.111.188: icmp_seq=2 ttl=50 time=29.249 ms
	--- www.a.shifen.com ping statistics ---
	3 packets transmitted, 3 packets received, 0% packet loss
	round-trip min/avg/max/stddev = 29.240/29.252/29.268/0.000 ms
	[root@k8s-master1 ~]# 

	发现能访问,说明单用docker能访问,在pod里面就 不能访问

	发现用baidu.com的ip可以访问：
	[root@k8s-master1 ~]# docker exec de7f1336 ping -c 3 111.13.100.91
	PING 111.13.100.91 (111.13.100.91): 56 data bytes
	64 bytes from 111.13.100.91: icmp_seq=0 ttl=48 time=27.432 ms
	64 bytes from 111.13.100.91: icmp_seq=1 ttl=48 time=27.259 ms
	64 bytes from 111.13.100.91: icmp_seq=2 ttl=48 time=27.248 ms
	--- 111.13.100.91 ping statistics ---
	3 packets transmitted, 3 packets received, 0% packet loss
	round-trip min/avg/max/stddev = 27.248/27.313/27.432/0.084 ms
	[root@k8s-master1 ~]# 
	能访问，这说明是dns解析有问题了，没有将域名解析出来。

	装个kube-dns服务就好了

	https://github.com/zouhuigang/kubernetes/tree/master/k8s_1.8.4/kube-dns


http://blog.51yip.com/linux/1404.html 
	




	

