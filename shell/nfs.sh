#!/bin/bash
#NFS 配置文件:/etc/exports 协议: NFS(2049) RPC(111) 服务: nfs-server
#查看服务器的共享 showmount -e IP
#客户端访问nfs需要安装nfs-utils
#开机挂载 IP:/public /mnt nfs defaults,_netdev 0 0
. ./public_functions

checkVersion && clear

#----------------------------------------
logW "1.安装 rpcbind 软件" && logY "yum -y install rpcbind"
yum -y install rpcbind
checkTF

logW "2.启动 rpcbind 服务" && logY "systemctl enable --now  rpcbind"
systemctl enable --now  rpcbind
checkTF

logW "3.安装 nfs-utils 软件" && logY "yum -y install nfs-utils"
yum -y install nfs-utils
checkTF

logW "4.启动 nfs 服务" && logY "systemctl enable --now nfs"
systemctl enable --now nfs
checkTF

logW "5.共享 /mnt 目录，书写配置文件" && logY "cat >/etc/exports << EOF..."
cat >/etc/exports << EOF
/mnt     *(ro)
#/public 192.168.1.0(ro)
#/public 192.168.1.20(ro)
EOF
checkTF

logW "6.重启 nfs 服务" && logY "systemctl restart nfs"
systemctl restart nfs
checkTF

logW "7.查看共享" && logY "showmount -e 127.0.0.1"
showmount -e 127.0.0.1
checkTF

echo "提示：开机挂载请在/etc/fstab添加此格式内容: IP:/public /mnt nfs defaults,_netdev 0 0"
