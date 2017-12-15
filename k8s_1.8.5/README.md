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

	



