#! /bin/bash
# install mysql
. ./public_functions

readonly mysql_Version="mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz"	# mysql压缩包名称
readonly mysql_Catalog="mysql-5.7.28-linux-glibc2.12-x86_64"		# 压缩包解压后的目录名称

logW "1. 添加用户 mysql"
logY "useradd mysql -M -s /sbin/nologin"
useradd mysql -M -s /sbin/nologin
if [[ $? -eq 0 || $? -eq 9 ]]; then
    logG "success ↑↑↑"
    echo " "
  else
    logR "fail ↑↑↑       -->> return $?"
    exit 0
  fi

logW "2. 创建目录并设置目录权限 /app/database  /data/3306  /binlog/3306"
logY "mkdir -p /app/database /data/3306 /binlog/3306"
mkdir -p /app/database /data/3306 /binlog/3306
logY "chown -R mysql.mysql /app /data /binlog"
chown -R mysql.mysql /app /data /binlog
checkTF

logW "3. 开始下载 $mysql_Version"
logY "curl -o /tmp/$mysql_Version -# -L -O  https://downloads.mysql.com/archives/get/p/23/file/$mysql_Version"
if [ -f /tmp/$mysql_Version ]; then
  checkTF
else
  curl -o /tmp/$mysql_Version -# -L -O https://downloads.mysql.com/archives/get/p/23/file/$mysql_Version
  checkTF
fi

logW "4. 开始解压 $mysql_Version 到 /app/database/"
logY "tar -xf /tmp/$mysql_Version -C /app/database"
tar -xf /tmp/$mysql_Version -C /app/database
checkTF

logW "5. 进入 /app/database/ 创建软链接"
logY "cd /app/database/"
cd /app/database/
logY "ln -s $mysql_Catalog mysql"
if [ -L /app/database/mysql ]; then
  logW "mysql File exists"
  checkTF
else
  ln -s $mysql_Catalog mysql
  checkTF
fi

logW "6. 设置环境变量"
logY "source /etc/profile && echo \$PATH && mysql -V"
grep '/app/database/mysql/bin' /etc/profile
if [ $? == 0 ]; then
  source /etc/profile && echo $PATH && mysql -V
  checkTF
else
  sed -i '$a export PATH="/app/database/mysql/bin:$PATH"' /etc/profile
  source /etc/profile && echo $PATH && mysql -V
  checkTF
fi

logW "7. 初始化数据库"
logY "mysqld --initialize-insecure --user=mysql --basedir=/app/database/mysql --datadir=/data/3306/"
rm -rf /data/3306/*
#rm -f /var/lock/subsys/mysql
mysqld --initialize-insecure --user=mysql --basedir=/app/database/mysql --datadir=/data/3306/
checkTF

logW "8. 创建配置文件"
logY "cat >/etc/my.cnf <<-EOF"
cat >/etc/my.cnf <<-EOF
[mysqld]
user=mysql
basedir=/app/database/mysql
datadir=/data/3306
server_id=6
port=3306
socket=/tmp/mysql.sock
[mysql]
socket=/tmp/mysql.sock
EOF
checkTF

logW "9. 启动mysql..."
cp /app/database/mysql/support-files/mysql.server /etc/init.d/mysqld
logY "server mysqld start"
service mysqld start
checkTF

logW "10. 查看mysql监听端口"
logY "ss -tupln | grep Netid && ss -tupln | grep mysql"
ss -tupln | grep Netid && ss -tupln | grep mysql
checkTF

logW "10. 放行3306端口"
getFirewalldStatus
if [[ $? -eq 0 ]]; then
  logY "firewall-cmd --zone=public --add-port="3306"/"tcp" --permanent"
  firewall-cmd --zone=public --add-port="3306"/"tcp" --permanent 2>/dev/null
  firewall-cmd --reload &>/dev/null
  echo ""
else
  logR "防火墙未开启"
  echo ""
fi

