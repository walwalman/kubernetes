
### k8s通过ceph的pool

1)创建一个pool:

	sudo ceph --cluster ceph osd pool create kube 1024 1024

结果：

	$ ceph --cluster ceph osd pool create kube 1024 1024
	pool 'kube' created

2)认证：

	sudo ceph --cluster ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'

结果：

	$ sudo ceph --cluster ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'
	[client.kube]
	        key = AQAYByBaNyXkFxAA9EaJkh2UJT8Ct5aasdU4Jw==

3)让每个namespace都可以访问

	sudo ceph --cluster ceph auth get-key client.kube

结果：

	$ sudo ceph --cluster ceph auth get-key client.kube
	AQAYByBaNyXkFxAA9EaJkh2UJT8Ct5aasdU4Jw==

4)在namespace=default中创建一个密钥

	kubectl create secret generic ceph-secret-kube --type="kubernetes.io/rbd" --from-literal=key='AQAYByBaNyXkFxAA9EaJkh2UJT8Ct5aasdU4Jw==' --namespace=default

结果：

	secret "ceph-secret-kube" created

--from-literal=key=就是第三步的显示结果




### 执行

	cd /home/kubernetes/ceph/test2
	kubectl create -f ceph-storage-fast-rbd.yml --namespace=default
	kubectl create -f ceph-pvc.yml --namespace=default



### 测试


	kubectl create -f pod.yml --namespace=default




还是报这个错误：

	Warning  ProvisioningFailed  12s (x2 over 27s)  persistentvolume-controller  Failed to provision volume with StorageClass "fast-rbd": failed to create rbd image: exit status 1, command output: rbd: extraneous parameter --image-feature

最后发现是ceph-common的版本跟之前ceph集群的版本不一致导致的，更新到最新版本的即可解决这个问题！！！




	rbd create kube/ceph-claim --size 5120 --image-format 2 --image-feature layering
	rbd map kube/ceph-claim --name client.admin


https://www.cnblogs.com/breezey/p/6558967.html