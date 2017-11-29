### 分布式负载测试

	mkdir -p /home/kubernetes/lb-test
	yum install -y git
	git clone https://github.com/rootsongjc/distributed-load-testing-using-kubernetes.git

	cd /home/kubernetes/lb-test/distributed-load-testing-using-kubernetes/kubernetes-config

	kubectl create -f sample-webapp-controller.yaml
	kubectl create -f sample-webapp-service.yaml


