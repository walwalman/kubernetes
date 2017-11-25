### dashboard插件

>经过前面的k8s 1.8.4安装之后，继续安装dashboard插件...

	cd /home/kubernetes/kubernetes/cluster/addons/dashboard
	[root@localhost dashboard]# ls
	dashboard-controller.yaml  dashboard-service.yaml  MAINTAINERS.md  README.md
	[root@localhost dashboard]# 


官方没有rbac.yaml这个文件，自己创建~~

新加了 dashboard-rbac.yaml 文件，定义 dashboard 使用的 RoleBinding


查看需要使用的镜像：

	gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3

	docker pull registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-amd64:v1.6.3

	docker tag registry.cn-hangzhou.aliyuncs.com/google-containers/kubernetes-dashboard-amd64:v1.6.3 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3



创建：

	[root@localhost dashboard]# kubectl create -f dashboard-controller.yaml 
	deployment "kubernetes-dashboard" created
	[root@localhost dashboard]# kubectl create -f dashboard-service.yaml 
	service "kubernetes-dashboard" created
	[root@localhost dashboard]# 



显示：

![./images/20171124181132.png](./images/20171124181132.png)


问题汇总：

Q1：访问,出现roles.rbac.authorization.k8s.io is forbidden: User "system:serviceaccount:kube-system:default" cannot list roles.rbac.authorization.k8s.io at the cluster scope

![./images/20171124162934.png](./images/20171124162934.png)


A1：出现这个问题是：

因为在dashboard-controller.yaml 中没有指定rbac用户：

	 spec:
	      serviceAccountName: dashboard  #指定用户
	      containers:
	      - name: kubernetes-dashboard
	        image: gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3

[https://github.com/kubernetes/dashboard/issues/1803](https://github.com/kubernetes/dashboard/issues/1803)

	


由于缺少 Heapster 插件，当前 dashboard 不能展示 Pod、Nodes 的 CPU、内存等 metric 图形；





