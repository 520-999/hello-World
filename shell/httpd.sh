#!/bin/bash
# httpd install
# 配置文件: /etc/httpd/conf/httpd.conf  协议: http  服务: httpd  默认监听端口: 80
. ./public_functions

checkVersion && clear

#----------------------------------------
logW "1.安装 httpd 软件" && logY "yum -y install httpd"
yum -y install httpd
checkTF

logW "2.启动 httpd 服务" && logY "systemctl enable --now httpd"
systemctl enable --now  httpd
checkTF

logW "3.生成 httpd 网页" && logY "cat >/var/www/html/index.html <<EOF..."
cat >/var/www/html/index.html << EOF
this is apche...
this is test page ...
EOF
checkTF

logW "4.访问 httpd 服务器" && logY "curl 127.0.0.1"
curl 127.0.0.1
checkTF

#添加虚拟主机
addVirtualHost() {

cat >/etc/httpd/conf.d/myvirtualhost.conf <<EOF
<VirtualHost  *:80>
  ServerName    www.qq.com	#网站的域名
  DocumentRoot  /var/www/qq	#网页文件路径
</VirtualHost>
EOF
}
