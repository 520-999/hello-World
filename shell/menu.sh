#!/bin/bash
# 菜单显示和更换yun源
. ./public_functions

checkVersion && clear

#--------------------------------------------------------------------------------
switchYumRepoToAliYun() {			#更换yum源为阿里源
  logG "开始拉取阿里源..."
  logY "curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo"
  curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null
  checkTF && yum clean all && yum -y install postfix  && yum repolist
}

switchYumRepoToWangyi() {			#更换yum源为网易源
  logG "开始拉取网易源..."
  logY "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo"
  curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &> /dev/null
  checkTF && yum clean all && yum -y install postfix  && yum repolist
}
#--------------------------------------------------------------------------------菜单区

#输出提示语
printStartLog() {
  systemVersionName=`cat /etc/redhat-release`

  echo -e "
——————————————————————————————————————————————————————————————————————————————————————————————————————————
\e[1;31m                欢迎使用Linux工具箱 此系统版本：$systemVersionName                           \e[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————
      系统相关
—————————————————————
\e[31m
            1) docker菜单       2) 安装nginx      3) 安装kvm             4) 安装kubernetes
            5)                  6) 开关selinux    7) 设置yum用阿里源     8) 设置yum用网易源          \e[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————
           A1) 安装NFS         A2) 安装httpd     A3) 安装php7           A4) 创建随机密码 
           A5)                 A6)               A7)                    A8) 安装pxe_server
——————————————————————————————————————————————————————————————————————————————————————————————————————————"
}

#脚本执行入口
shellOnStart() {

  printStartLog

  logP "请输入有效的操作编号:"
  read menuNUM

  case $menuNUM in

    1)#docker相关
      bash docker.sh ;;

    2)#nginx相关
      bash nginx.sh ;;

    3)#安装kvm
      bash kvm.sh ;;

    4)#安装kubernetes
      bash kubernetes.sh ;;

    5)#
      
      ;;

    6)#
      selinux_Menu ;;

    7)#设置yum用阿里源
      switchYumRepoToAliYun ;;

    8)#设置yum用网易源
      switchYumRepoToWangyi ;;

A1|a1)#安装NFS
      bash nfs.sh ;;

A2|a2)#安装httpd
      bash httpd.sh ;;

A3|a3)#安装php7
      bash php7.sh ;;

A4|a4)#创建随机密码
      bash random.sh ;;

A8|a8)#安装pxe_server
      bash pxe_server.sh ;;

    *)
      logR "编号输入错误!! 请重新输入!!" && sleep 1 && clear && shellOnStart ;;
  esac
}
shellOnStart
