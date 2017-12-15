
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