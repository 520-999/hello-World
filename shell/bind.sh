#!/bin/bash
# bind 配置文件:/etc/named.conf  #设置负责解析的域名
# 地址库文件：/var/named/	#完全合格的主机名与IP地址
# 协议: TCP/UDP(53)  服务: named
# bind（主程序） bind-chroot（ 提供牢笼政策,可选 运行时虚拟根环境：/var/named/chroot/ ）
. ./public_functions

#----------------------------------------
logW "1.安装 bind-chroot 软件" && logY "yum -y install bind-chroot"
yum -y install bind-chroot
checkTF

logW "2.安装 bind 软件" && logY "yum -y install bind"
yum -y install bind
checkTF

logW "3.启动 bind 服务" && logY "systemctl enable --now named"
systemctl enable --now named
checkTF

logY "未完待续"
