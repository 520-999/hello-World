#! /bin/bash
# 安装php
. ./public_functions

readonly php_Version="php72w"  #php的版本

logW "1. 安装epel源"
logY "yum -y install epel-release"
yum -y install epel-release
checkTF

logW "2. 安装php7源"
logY "rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm"
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
sleep 3 && echo ""

logW "3. 安装$php_Version"
logY "yum -y install ${php_Version}-{tidy,common,devel,pdo,mysql,gd,ldap,mbstring,mcrypt,fpm}"
yum -y install ${php_Version}-{tidy,common,devel,pdo,mysql,gd,ldap,mbstring,mcrypt,fpm}
checkTF

logW "4. 查看php版本"
logY "php -v" && php -v
checkTF

logW "5. 启动php-fpm"
logY "systemctl enable --now php-fpm"
systemctl enable --now  php-fpm
checkTF

logW "6. 显示php监听端口"
logY "netstat -tupln | grep Proto && netstat -tupln | grep php"
netstat -tupln | grep Proto && netstat -tupln | grep php
checkTF

logW "7. 放行9000端口"
getFirewalldStatus
if [[ $? -eq 0 ]]; then
  logY "firewall-cmd --zone=public --add-port="9000"/"tcp" --permanent"
  firewall-cmd --zone=public --add-port="9000"/"tcp" --permanent 2>/dev/null  && firewall-cmd --reload &>/dev/null
  echo ""
else
  logR "防火墙未开启"
  echo ""
fi
