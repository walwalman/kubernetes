1）创建ceph的disk image

	rbd create ceph-image -s 128


2)创建pv和pvc

	kubectl create -f ceph-pv.yaml
	kubectl create -f ceph-pv.yaml

3)创建测试pod

	docker pull elasticsearch:1.7.1
	docker tag elasticsearch:1.7.1 registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/elasticsearch:1.7.1
	docker push registry.cn-hangzhou.aliyuncs.com/zhg_docker_ali_r/elasticsearch:1.7.1
	


如果不对image格式化，不创建ceph-secret，那么pod将一直处于CreatingContainer状态

参考文档：

http://blog.csdn.net/xuguokun1986/article/details/53708562

http://www.damonyi.cc/%E4%BD%BF%E7%94%A8ceph-rbd%E4%BD%9C%E4%B8%BAkubernetes-%E5%8D%B7/