
Q1:

	The Pod "pod-mysql" is invalid: spec.containers[0].securityContext.privileged: Forbidden: disallowed by cluster policy


A1:

	kube-apiserver和kubelet的启动脚本中添加--allow_privileged=true，如果不添加的话，下面在部署calico的时候，会以下错误：
	每个节点修改/etc/kubernetes/config中的 KUBE_ALLOW_PRIV="--allow-privileged=true" 

	重启:
	systemctl restart kube-apiserver
	systemctl restart kubelet



q2:

	reatePodSandbox for pod "pod-mysql_default(417cc726-e158-11e7-8c00-00163e046907)" failed: rpc error: code = Unknown desc = failed to start sandbox container for pod "pod-mysql": Error response from daemon: driver failed programming external connectivity on endpoint k8s_POD_pod-mysql_default_417cc726-e158-11e7-8c00-00163e046907_206 (9227ca71c4fabebe24cc28c291ade9f4c44cd0ea0f58e81c37848635672ea59b): iptables failed: iptables --wait -t nat -A DOCKER -p tcp -d 0/0 --dport 3306 -j DNAT --to-destination 10.254.65.6:3306 ! -i docker0: iptables: No chain/target/match by that name.


A2:

	iptables -P INPUT ACCEPT 
	iptables -F   
	systemctl start iptables
	systemctl restart docker
	systemctl restart kube-apiserver


Q3:

	curl -v 10.254.0.1:443

	curl https://10.254.0.1:443/api/v1/endpoints?resourceVersion=0

	curl -k -v -XGET -H "Authorization: Bearer <JWT from service token>" -H "Accept: application/json, */*" -H "User-Agent: kube-dns/v1.6.0 (linux/amd64) kubernetes/3872cb9" https://10.254.0.1:443/api/v1/endpoints?resourceVersion=0

A3:

	iptables -t nat -A PREROUTING -d 10.254.0.1 -p tcp --dport 443 -j DNAT --to-destination 47.100.76.132:6443

	https://github.com/kubernetes/contrib/issues/2249
	https://github.com/coreos/coreos-kubernetes/issues/215

	https://github.com/kubernetes/kubeadm/issues/193

	systemctl stop kubelet
	systemctl stop docker
	iptables --flush
	iptables -tnat --flush
	systemctl start kubelet
	systemctl start docker

	The route problem can be solved by flush iptables.

	iptables -t nat -L -n


	systemctl disable firewalld;systemctl stop firewalld;iptables -P FORWARD ACCEPT

	https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md

	最后把所有服务都停止了，重新生成证书就好了~~



启动所有服务:



	systemctl restart etcd
	systemctl restart flanneld
	systemctl restart docker
	
	systemctl restart kube-apiserver
	
	systemctl restart kube-controller-manager
	
	systemctl restart kube-scheduler
	
	
	systemctl restart kubelet
	
	systemctl restart kube-proxy



 	kubectl exec test-68f5479cb5-zm62z  -- curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H  "Authorization: Bearer $TOKEN_VALUE" https://10.254.0.1



参考文档:


https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md
https://github.com/kubernetes/ingress-nginx


https://github.com/kubernetes/kubernetes/issues/51675

https://github.com/opsnull/follow-me-install-kubernetes-cluster/issues/184

https://github.com/kubernetes/kubernetes/issues/51675


https://github.com/opsnull/follow-me-install-kubernetes-cluster/issues/102

http://blog.gcalls.cn/blog/2017/01/Kubernetes%E9%9B%86%E7%BE%A4%E6%90%AD%E5%BB%BA.html


kubectl logs kubernetes-dashboard-6667f9b4c-6mtk4 -n kube-system