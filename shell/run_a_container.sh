#!/bin/bash
#
. ./public_functions

logW "1. 下载基础镜像"
logY "docker pull 180.76.232.94:5000/centos:7.6.1810"
docker pull 180.76.232.94:5000/centos:7.6.1810
checkTF

logW "2. 编写Dockfile文件"
logY "cat >/tmp/Dockerfile <<-EOF..."
cat >/tmp/Dockerfile <<-EOF
FROM 180.76.232.94:5000/centos:7.6.1810
RUN yum -y install httpd iproute
RUN echo "this is httpd 2020" >/var/www/html/index.html
ENV LANG=C
WORKDIR /var/www/html/
EXPOSE 80
CMD ["/usr/sbin/httpd","-DFOREGROUND"]
EOF
checkTF

logW "3. 根据Dockerfile创建镜像"
logY "docker build -t myos:httpd /tmp/"
docker build -t myos:httpd /tmp/ && echo ""

logW "4. 运行一个httpd容器"
logY "docker run -itd -p 80:80 myos:httpd"
docker run -itd -p 80:80 myos:httpd
checkTF

container_id=$(docker ps -a | grep myos:httpd | awk '{print $1}')
container_ip=$(docker inspect $container_id | grep '"IPAddress": "' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed '2d')
logW "5. 访问容器内httpd服务"
logY "curl \$container_ip: $container_ip"
curl $container_ip
checkTF
