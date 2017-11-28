### heapster安装文档
>由于缺少 Heapster 插件，dashboard 不能展示 Pod、Nodes 的 CPU、内存等 metric 图形


[下载官方最新heapster地址](https://github.com/kubernetes/heapster/releases)


因为最新的版本是Heapster v1.5.0-beta.2,还处于测试阶段，所以我们这边下载一个比较稳定的版本：

Heapster v1.4.3：

包含的镜像有：

	#gcr.io/google_containers/heapster-grafana-amd64:v4.2.0
	#gcr.io/google_containers/heapster-amd64:v1.3.0
	gcr.io/google_containers/heapster-grafana-amd64:v4.0.2
	gcr.io/google_containers/heapster-influxdb-amd64:v1.1.1
	gcr.io/google_containers/heapster-amd64:v1.4.3

	
pull：

	docker pull gcr.mirrors.ustc.edu.cn/google_containers/heapster-grafana-amd64:v4.0.2
	docker pull gcr.mirrors.ustc.edu.cn/google_containers/heapster-amd64:v1.4.3
	docker pull gcr.mirrors.ustc.edu.cn/google_containers/heapster-influxdb-amd64:v1.1.1

tag:

	docker tag gcr.mirrors.ustc.edu.cn/google_containers/heapster-grafana-amd64:v4.0.2 gcr.io/google_containers/heapster-grafana-amd64:v4.0.2
	docker tag gcr.mirrors.ustc.edu.cn/google_containers/heapster-amd64:v1.4.3 gcr.io/google_containers/heapster-amd64:v1.4.3
	docker tag gcr.mirrors.ustc.edu.cn/google_containers/heapster-influxdb-amd64:v1.1.1 gcr.io/google_containers/heapster-influxdb-amd64:v1.1.1






安装：

	mkdir -p /home/kubernetes/heapster && cd /home/kubernetes/heapster
	wget https://github.com/kubernetes/heapster/archive/v1.4.3.zip
	# 如果下载不下来，可以使用百度网盘下载,链接：http://pan.baidu.com/s/1miSmsCK 密码：4x4k
	yum install -y unzip
	unzip v1.4.3.zip

yaml文件：

	cd /home/kubernetes/heapster/heapster-1.4.3/deploy/kube-config/influxdb
	[root@localhost influxdb]# ls
	grafana.yaml  heapster.yaml  influxdb.yaml
	[root@localhost influxdb]# 


### 修改yaml文件：

grafana.yaml:

> 如果后续使用 kube-apiserver 或者 kubectl proxy 访问 grafana dashboard，则必须将 GF_SERVER_ROOT_URL 设置为 /api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/，否则后续访问grafana时访问时提示找不到http://192.168.122.148:8086/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/api/dashboards/home 页面

将GF_SERVER_ROOT_URL的值变为：

	- name: GF_SERVER_ROOT_URL
	- value: /api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/



运行：

	kubectl create -f grafana.yaml 
	kubectl create -f heapster.yaml 
	kubectl create -f influxdb.yaml

此外还需要运行一个rbac授权文件：

	cd /home/kubernetes/heapster/heapster-1.4.3/deploy/kube-config/rbac &&
	kubectl create -f heapster-rbac.yaml



检查结果：

Deployment:

	$ kubectl get deployments -n kube-system | grep -E 'heapster|monitoring'
	heapster               1         1         1            1           3h
	monitoring-grafana     1         1         1            1           46m
	monitoring-influxdb    1         1         1            1           3h  

pods:

	$ kubectl get pods -n kube-system | grep -E 'heapster|monitoring'
	heapster-7cf895f48f-7x5k8              1/1       Running   0          9m
	monitoring-grafana-6ccf7589cb-5ktn9    1/1       Running   0          9m
	monitoring-influxdb-67f8d587dd-hvxhh   1/1       Running   0          8m


验证dns是否解析正确：

	kubectl --namespace=kube-system exec -ti heapster-7cf895f48f-7x5k8  -- nslookup kubernetes.default

	kubectl --namespace=kube-system exec heapster-7cf895f48f-7x5k8  -- cat /etc/resolv.conf

### 浏览器访问：


http://192.168.122.148:8080/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana

	$ kubectl get svc -n kube-system|grep influxdb
	monitoring-influxdb    ClusterIP   10.254.212.214   <none>        8086/TCP        18m
	
	#http://192.168.122.148:8080/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb:8083/


通过代理访问：

	kubectl proxy --address='192.168.122.148' --port=8086 --accept-hosts='^*$'

	http://192.168.122.148:8086/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/

	http://192.168.122.148:8080/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb:8083/

	$kubectl get svc -n kube-system|grep influxdb
	monitoring-influxdb    NodePort    10.254.95.33     <none>        8086:32747/TCP,8083:32666/TCP   22m

	#在页面的 “Connection Settings” 的 Host 中输入 node IP， Port 中输入 8086 映射的 nodePort 如上面的 32747，点击 “Save” 即可（我的集群中的地址是192.168.122.148:32747）：

	https://github.com/kubernetes/heapster/issues/1279


### 问题汇总：

Q1：

	# kubectl logs -n kube-system  monitoring-grafana-6c478f96b8-xsffr
	Starting a utility program that will configure Grafana
	Starting Grafana in foreground mode
	t=2017-11-24T01:48:28+0000 lvl=crit msg="Failed to parse /etc/grafana/grafana.ini, open /etc/grafana/grafana.ini: no such file or directory%!(EXTRA []interface {}=[])"

A1：

大概意思是可以挂一个空的文件到镜像里面去或者用其他版本的镜像替换掉它，所以还是用heapster-grafana-amd64:v4.0.2版本的镜像！

	https://github.com/kubernetes/heapster/pull/1728
	https://github.com/kubernetes/heapster/issues/1709



Q2:

部署完成，dashboard查看不到任何数据,cpu，内存等，且容器日志报错：
1 reflector.go:190] k8s.io/heapster/metrics/heapster.go:322: Failed to list *v1.Pod: Get https://kubernetes.default/api/v1/pods?resourceVersion=0: dial tcp: lookup kubernetes.default on 10.254.200.200:53: dial udp 10.254.200.200:53: i/o timeout

A2:
	需要安装kube-dns解析域名地址,或者将- --source=kubernetes:https://kubernetes.default改成- --source=kubernetes:http://192.168.122.148:8080/?inClusterConfig=false其中inClusterConfig=false代表不使用service accounts中的kube config信息。

	https://github.com/kubernetes/heapster/issues/1655
	https://github.com/kubernetes/heapster/issues/1744
	http://tonybai.com/2017/01/20/integrate-heapster-for-kubernetes-dashboard/



Q3：

执行：kubectl --namespace=kube-system exec -ti heapster-7cf895f48f-7x5k8  -- nslookup kubernetes.default出现错误信息：
rpc error: code = 13 desc = invalid header field value "oci runtime error: exec failed: container_linux.go:247

A3：

	docker exec 报错是因为 /bin/bash 文件不存在，可以尝试 /bin/sh 等
	kubectl exec -it -n=kube-system  monitoring-influxdb-67f8d587dd-2js7v /bin/sh
	https://github.com/moby/moby/issues/29704


Q4：kube-dns正常，但是启动之后发现还是查看不到任何的数据，查看monitoring-influxdb-67f8d587dd-2js7vf容器log发现，POST /write?consistency=&db=k8s&precision=&rp=default HTTP/1.1" 204，不能将数据写入进去！！

A4：

	找到容器:
	docker exec -it xxxx /bin/sh
	cd /usr/bin 
	CREATE RETENTION POLICY "default" ON k8s DURATION 0d REPLICATION 1 DEFAULT

	curl -i -XPOST 'http://{influxdb_cluster_ip}:8086/query' --data-urlencode 'q=CREATE RETENTION POLICY "default" ON "k8s" DURATION INF REPLICATION 1 DEFAULT'

	其中：influxdb_cluster_ip地址用kubectl get svc --all-namespaces查看monitoring-influxdb的地址。

	curl -i -XPOST 'http://10.254.212.214:8086/query' --data-urlencode 'q=CREATE RETENTION POLICY "default" ON "k8s" DURATION INF REPLICATION 1 DEFAULT'
	
	而HTTP的204(No Content)响应, 就表示执行成功

	https://github.com/kubernetes/heapster/issues/1474
	https://github.com/kubernetes/kubernetes/issues/40346
	https://github.com/kubernetes/dashboard/issues/1584
	https://github.com/kubernetes/heapster/issues/1348#issuecomment-256480147
	https://github.com/kubernetes/heapster/issues/1143



Q5:monitoring-grafana没数据

A5：需要重新创建一下