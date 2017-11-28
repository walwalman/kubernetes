### kubectl 命令配置https



### 设置https访问证书等

>如果配置了https://192.168.122.148:6443，则在Master命令行，输入指令时，需要设置参数运行，如：
>
>kubectl --server=https://192.168.122.148:6443 --insecure-skip-tls-verify=true --client-certificate=/etc/kubernetes/ssl/kubelet-client.crt --client-key=/etc/kubernetes/ssl/kubelet-client.key get nodes


为了方便跟http一样的使用，设置参数如下：



	export KUBE_APISERVER="https://192.168.122.148:6443"
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


然后即可使用如下命令了：

	kubectl get pods



问题：
 
q1:创建容器时，一直处于Pending,且查看kubelet发现日志错误：

	[root@localhost kubernetes]# systemctl status kubelet -l
	kubelet.service - Kubernetes Kubelet Server
	   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
	   Active: active (running) since Fri 2017-11-24 15:12:12 EST; 5min ago
	     Docs: https://github.com/GoogleCloudPlatform/kubernetes
	 Main PID: 12159 (kubelet)
	   CGroup: /system.slice/kubelet.service
	           鈹斺攢12159 /usr/local/bin/kubelet --logtostderr=true --v=0 --address=192.168.122.148 --hostname-override=192.168.122.148 --allow-privileged=true --pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest --cgroup-driver=systemd --cluster-dns=10.254.200.200 --experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig --kubeconfig=/etc/kubernetes/kubelet.kubeconfig --require-kubeconfig --cert-dir=/etc/kubernetes/ssl --cluster-domain=cluster.local --hairpin-mode promiscuous-bridge --serialize-image-pulls=false

	Nov 24 15:17:14 localhost.localdomain kubelet[12159]: W1124 15:17:14.661762   12159 container_manager_linux.go:872] MemoryAccounting not enabled for pid: 12159
	Nov 24 15:17:20 localhost.localdomain kubelet[12159]: E1124 15:17:20.464540   12159 summary.go:92] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
	Nov 24 15:17:20 localhost.localdomain kubelet[12159]: E1124 15:17:20.464569   12159 summary.go:92] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
	Nov 24 15:17:20 localhost.localdomain kubelet[12159]: W1124 15:17:20.464601   12159 helpers.go:847] eviction manager: no observation found for eviction signal allocatableNodeFs.available
	Nov 24 15:17:30 localhost.localdomain kubelet[12159]: E1124 15:17:30.496884   12159 summary.go:92] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
	Nov 24 15:17:30 localhost.localdomain kubelet[12159]: E1124 15:17:30.496920   12159 summary.go:92] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
	Nov 24 15:17:30 localhost.localdomain kubelet[12159]: W1124 15:17:30.496979   12159 helpers.go:847] eviction manager: no observation found for eviction signal allocatableNodeFs.available
	Nov 24 15:17:40 localhost.localdomain kubelet[12159]: E1124 15:17:40.516421   12159 summary.go:92] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
	Nov 24 15:17:40 localhost.localdomain kubelet[12159]: E1124 15:17:40.516495   12159 summary.go:92] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
	Nov 24 15:17:40 localhost.localdomain kubelet[12159]: W1124 15:17:40.516545   12159 helpers.go:847] eviction manager: no observation found for eviction signal allocatableNodeFs.available


A1:
	在kubectl配置中添加

	--runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice


Q2：发现镜像不能启动,一直处于pendding中。。。

A2:

	https://192.168.122.148:6443