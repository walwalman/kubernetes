
首先要升级到CentOS7.2，有一个XFS的Bug在7.2系统被修复了。

如果你在使用loopback的devicemapper的话，当你的存储出现了问题后，正确的解决方案是：

	rm -rf /var/lib/docker

查看docker信息及存储驱动：

	docker info


docker 1.12.x
---

### 将OverlayFS加到module目录下

	echo "overlay" > /etc/modules-load.d/overlay.conf
	reboot
	lsmod | grep over

### 停止docker服务

	rm -rf /var/lib/docker

### 修改docker的配置文件

	vi /usr/lib/systemd/system/docker.service

找到：

	ExecStart=/usr/bin/dockerd-current \

加入参数：

	--storage-driver=overlay

变成：
	
	ExecStart=/usr/bin/dockerd-current \
        --storage-driver=overlay \


### 重启

	systemctl daemon-reload
	systemctl restart docker


docker 1.11.x
---

### 将OverlayFS加到module目录下

	echo "overlay" > /etc/modules-load.d/overlay.conf
	# lsmod | grep over
	overlay                42451  0
	reboot

### 配置Docker Daemon用OverlayFS启动

创建文件夹

	mkdir -p /etc/systemd/system/docker.service.d
	
加入参数：

	cat >/etc/systemd/system/docker.service.d/override.conf <<E
	[Service] 
	ExecStart= 
	ExecStart=/usr/bin/docker daemon --storage-driver=overlay -H fd:// 
	E

### 重启

	systemctl daemon-reload
	systemctl restart docker


其他方法
---

	docker daemon -s overlay
    docker daemon --storage-driver=overlay
	docker option : -s=overlay
