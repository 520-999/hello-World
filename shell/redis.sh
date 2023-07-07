#!/bin/bash
#install redis
. ./public_functions

readonly redis_Version="7.0.8.tar.gz"  #redis压缩包名称
readonly redis_Catalog="redis-7.0.8"   #压缩包解压后的目录名称

logW "1. 开始下载redis"
logY "curl -o /tmp/$redis_Version -# -L -O https://github.com/redis/redis/archive/$redis_Version"
curl -o /tmp/$redis_Version -# -L -O https://github.com/redis/redis/archive/$redis_Version
checkTF

logW "2. 开始解压redis"
logY "tar -xf /tmp/$redis_Version -C /tmp/"
tar -xf /tmp/$redis_Version -C /tmp/
checkTF

logW "3. 编译安装redis到/usr/local/$redis_Catalog"
logY "cd /tmp/$redis_Catalog && make && make install"
cd /tmp/$redis_Catalog
#sed 's@^PREFIX?=/usr/local$@PREFIX?=/usr/local/redis@g' src/Makefile
make && make install PREFIX=/usr/local/$redis_Catalog
checkTF

logW "4. 添加redis到环境变量"
logY "sed -i '\$a export PATH=\$PATH:/usr/local/$redis_Catalog/bin/' /etc/bashrc && source /etc/bashrc"
grep -q '^export PATH=$PATH:/usr/local/'$redis_Catalog'/bin/$' /etc/bashrc && logG "  环境变量已存在\n"
if [[ $? != 0 ]];then
  sed -i '$a export PATH=$PATH:/usr/local/'$redis_Catalog'/bin/' /etc/bashrc && logG "success ↑↑↑\n"
  source /etc/bashrc
fi

logW "5. 初始化redis (需交互)"
logY "bash /tmp/$redis_Catalog/utils/install_server.sh"
sed -i '/^_pid_1_exe=/,+6s/^/#/' /tmp/$redis_Catalog/utils/install_server.sh
bash /tmp/$redis_Catalog/utils/install_server.sh && echo ''

logW "6. 启动redis服务"
logY "service redis_6379 start"
service redis_6379 start
checkTF

logW "7. 显示redis监听端口"
logY "netstat -tupln | grep Proto && netstat -tupln | grep redis"
netstat -tupln | grep Proto && netstat -tupln | grep redis
checkTF

rm -rf /tmp/$redis_Version /tmp/$redis_Catalog
