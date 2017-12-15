http://47.100.76.132:8080/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/


Error: 'tls: oversized record received with length 20527'
Trying to reach: 'https://10.254.65.4:9090/'



https生成证书：

	cd /etc/kubernetes/ssl
	openssl pkcs12 -export -in admin.pem  -out admin.p12 -inkey admin-key.pem
	#输入密码，如: 123456,将生成一个新文件admin.p12

将生成的admin.p12证书下载到你的电脑上，然后点击改文件，导入的你的电脑，导出的时候记住你设置的密码，导入的时候还要用到

导入证书之后，即可打开：

浏览器访问：

	 https://47.100.76.132:6443/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy

