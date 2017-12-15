### 部署 Daemon Set

以 Daemon Set 的方式在每个 node 上启动一个 traefik，并使用 hostPort 的方式让其监听每个 node 的 80 端口(有没有感觉这就是个 NodePort? 不过区别就是这个 Port 后面有负载均衡器


	kubectl create -f traefik-ds.yanl


监听每个node的80端口和8580端口,80 提供正常服务，8580 是其自带的 UI 界面




### 让traefik支持免费https证书(Let's Encrypt)


创建用户名和密码:

	htdigest -c user.dat traefik guest #输入密码之后，得到一个文件user.dat(zhg和1ooooof)

	建一个名为 guest 的用户，并存储在 user.dat 中，用于后面的密码验证

得到uset.dat

	zhg:traefik:54923e7537f7a0523fa7a4ac362d418d

为 Traefik 准备一个 PVC，用于存储 ACME 生成的认证文件，这里我们命名为 traefik

	加载这一 PVC，并在其中生成空文件acme.json。
	chmod 600 acme.json


启动:

	kubectl create -f ingress-rbac.yaml 

创建配置文件:

	kubectl create cm traefik --from-file config.toml --dry-run -o yaml > config.map.yaml
	kubectl apply -f config.map.yaml



查看dep:

	[root@k8s-master1 ingressResource]# kubectl get deployment --all-namespaces
	NAMESPACE     NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
	default       nginx                        2         2         2            2           2h
	kube-system   traefik-ingress-controller   1         0         0            0           10m
	[root@k8s-master1 ingressResource]# 


测试https:

	curl -H Host:traefik.fake-domain.com http://127.0.0.1
	curl -k https://traefik.fake-domain.com


出现问题:

	Error creating: pods "traefik-ingress-controller-85ccfbff94-" is forbidden



Q2:

	Error creating TLS config: permissions 755 for acme.json are too open, please use 600"

A2:正确创建文件,不要使用echo "" >> acme.json创建空文件，这不是空文件

	 touch acme.json && chmod 600 acme.json

Q3:

	msg="Error preparing server: get directory at 'https://acme-v01.api.letsencrypt.org/directory': failed to get json "https://acme-v01.api.letsencrypt.org/directory": Get https://acme-v01.api.letsencrypt.org/directory: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)"

A3:

	#docker run -itd --name=puppet1 --net host devopsil/puppet bash
	https://github.com/kubernetes/charts/issues/1013


Q4:

Failed to list *v1.Service: services is forbidden: User "system:serviceaccount:default:default" cannot list services at the cluster scope

a4:

	没有创建rbac认证


参考文档:


http://blog.51cto.com/heshengkai/1981997

http://blog.fleeto.us/content/shi-yong-lets-encrypt-qing-song-jia-gu-traefik-ingress-controller

https://ruiming.me/use-traefik-reverse-proxy-in-the-docker-swarm-mode-cluster/

https://www.bountysource.com/issues/44275264-permissions-issues-with-kubernetes-configmap

https://blog.osones.com/en/kubernetes-ingress-controller-with-traefik-and-lets-encrypt.html

https://stackoverflow.com/questions/44480405/configuring-lets-encrypt-with-traefik-using-helm

http://blog.51cto.com/heshengkai/1981997

https://www.cnblogs.com/zhenyuyaodidiao/p/6739099.html