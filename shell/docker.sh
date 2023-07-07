#!/bin/bash
# 交互式-安装docker仓库distribution 安装docker-ce 设置docker相关配置文件 显示docker相关命令

. ./public_functions

install_Docker_Distribution() {			#安装docker仓库
  logW "1. 开始安装docker仓库..."
  logY "yum -y install docker-distribution"
  yum -y install docker-distribution
  checkTF

  logW "2. 启动docker仓库服务..."
  logY "systemctl enable --now docker-distribution"
  systemctl enable --now docker-distribution
  checkTF

  logW "3. 检测防火墙，如果开启则放行docker仓库端口"
  logY "getFirewalldStatus"
  getFirewalldStatus  
    if [[ $? -eq 0 ]]; then
      firewall-cmd --add-service=docker-registry --permanent 2>/dev/null
      echo ""
    else
      logR "防火墙未开启"
      echo ""
    fi

  logW "4. 开始访问仓库..."
  logY "curl 127.0.0.1:5000/v2/_catalog"
  curl 127.0.0.1:5000/v2/_catalog
  checkTF
}

install_Docker_ce() {				#安装docker-ce
  logW "1. 准备docker-ce yum源"
  logY "curl https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
  curl https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null > /etc/yum.repos.d/docker-ce.repo
  yum clean all > /dev/null && yum repolist | grep docker
  checkTF
 
  logW "2. 开始安装docker-ce"
  logY "yum -y install docker-ce-cli-18.09.9 containerd.io docker-ce-18.09.9"
  yum -y install docker-ce-cli-18.09.9 containerd.io docker-ce-18.09.9 ## --show-duplicates
  checkTF

  logW "3. 启动docker服务"
  logY "systemctl enable --now docker"
  systemctl enable --now docker
  checkTF

  logW "4. 显示docker版本信息"
  logY "docker --version"
  docker --version
  checkTF
}

set_Daemon.Json() {				#设置daemon.json文件

  logW "1. 创建daemon.json文件并写入内容"
  logY "cat <<-EOF >/etc/docker/daemon.json..."
cat <<-EOF >/etc/docker/daemon.json
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "registry-mirrors": ["https://hub-mirror.c.163.com"],
    "insecure-registries": ["180.76.232.94:5000","registry:5000"]
  }
EOF
  checkTF

  logW "2. 重启docker"
  logY "systemctl restart docker"
  systemctl restart docker
  checkTF

  logW "3. 查看daemon.json内容"
  logY "cat /etc/docker/daemon.json"
  cat /etc/docker/daemon.json
  checkTF 
}

open_ip_forward() {			#开启地址转换
  logG "1. 开启IP地址转换"
  logY "net.ipv4.ip_forward = 1"
  cat /etc/sysctl.conf  | grep -E '^net\.ipv4\.ip_forward = (0|1)$' 2&> /dev/null
  if [[ $? -eq 0 ]]; then
    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
    sysctl -p
  else
    sed -i '$a net.ipv4.ip_forward = 1' /etc/sysctl.conf
    sysctl -p
  fi
}

#docker常用命令
docker_Command() {
  echo -e "\e[33m docker常用命令列表↓↓ \e[0m"
  echo
  echo "   docker info						//查看docker信息"  
  echo "   docker inspect ubuntu:18.04				//查看镜像信息"
  echo "   docker inspect -f {{".Architecture"}} ubuntu:18.04	//精确查看信息"
  echo
  echo "   docker pull ubuntu:18.04				//下载ubuntu"
  echo "   pull hub.c.163.com/public/ubuntu:18.04		//从163下载ubuntu"
  echo "   docker tag ubuntu:latest myubuntu:latest		//打标签"
  echo "   docker push NAME[:TAG] && docker push test:latest"	//上传
  echo "   docker save -o ubuntu_18.04.tar ubuntu:18.04		//导出镜像"
  echo "   docker load -i ubuntu_18.04.tar			//加载镜像"
  echo "   docker load < ubuntu_18.04.tar			//加载镜像"
  echo "   docker commit -m \"Addid a new file\" -a \"Docker Newbee\" c547e35fa1fd  test:0.1"
  echo "   docker build -t Dockerfil"
  echo "   cat ubuntu-18.04-x86_64-minimal.tar.gz | docker import - ubuntu:18.04"
  echo "   docker image help"
  echo "   docker run -itd ubuntu:18.04"
  echo "   docker run ubuntu:18.04 /bin/ls /"
  echo "   docker container wait containerID"
  echo "   docker logs containerID --details -ft"
  echo "   docker (pause unpause stop start restart prune) containerID"
  echo "   docker (attach exec -it rm) containerID"
  echo "   journalctl -u docker.service"  
  echo "   docker history / search / rm / rmi / prune"
  echo "   docker inspect /top /stats containerID"
  echo "   docker cp / diff / port / update containerID"
}

#查看仓库镜像详情
repoistry_Curl() {

  echo -n "请按 127.0.0.1:5000 的格式输入ip地址和端口号: "
  read repoip
  ## 对输入的参数进行检查
  echo $repoip | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,6}$'
  if [[ $? -ne 0 ]]; then
    logR "输入不合法, 请重新输入!" && sleep 1
    repoistry_Curl
  fi
  imageInfo=$(curl $repoip/v2/_catalog 2>/dev/null)
  imageName=$(echo $imageInfo | tr -d '{}[]""'| awk -F ":" '{print $2}' | tr "," ' ')
  imageCount=`echo $imageName | xargs -n1 | wc -l`
  
  ##统计镜像数量##
  if [[ "$imageName" != "" ]]; then
    echo -e "仓库共有$imageCount个镜像"
  else
    logR "仓库为空" && curl $repoip/v2/_catalog 2>/dev/null
  fi

  ##显示所有镜像的版本号##
  for i in $imageName
  do
    echo -e "`curl $repoip/v2/$i/tags/list 2>/dev/null`"
  done
}

#菜单区
printStartLog() {				#输出提示语
  systemVersionName=`cat /etc/redhat-release`

  echo -e "
——————————————————————————————————————————————————————————————————————————————————————————————————————————
                  欢迎使用Linux工具箱 此系统版本：$systemVersionName
——————————————————————————————————————————————————————————————————————————————————————————————————————————
      Docker相关
—————————————————————
\e[1;33m
           1) 安装docker仓库      2) 安装docker     3) 设置daemon.json    4) open_ip_forward
           5) 查看docker仓库      6)                7) docker常用命令     8) 返回主菜单            \e[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————"
}

#脚本执行入口
shellOnStart() {

  printStartLog

  echo -n "请输入操作编号: "
  read menuNUM

  case $menuNUM in

    1)#安装docker仓库
      install_Docker_Distribution ;;

    2)#安装docker-ce
      install_Docker_ce ;;

    3)#设置daemon.json文件
      set_Daemon.Json ;;

    4)#docker常用命令
      open_ip_forward ;;

    5)#查看docker仓库
      repoistry_Curl ;;

    6)#
      bash docker.sh ;;

    7)#
      docker_Command ;;

    8)#返回主菜单
      bash menu.sh ;;

    *)
      logR "编号输入错误!! 请重新输入!!" && sleep 1 && clear && shellOnStart ;;
  esac
}

shellOnStart
