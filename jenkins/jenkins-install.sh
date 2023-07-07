#!/bin/bash

jenkins_download() {
  curl -L "https://d.pcs.baidu.com/file/3fe322959u250bef1d323b71cccc758f?fid=440301275-250528-684740497991830&rt=pr&sign=FDtAERV-DCb740ccc5511e5e8fedcff06b081203-%2Ft2xebU%2FZehi6fx%2FB4x0XScCd7I%3D&expires=8h&chkbd=0&chkv=2&dp-logid=2922417975967752832&dp-callid=0&dstime=1660119983&r=255466804&origin_appid=&file_type=0" --output "jenkins-2.263.1-1.1.noarch.rpm" -A "pan.baidu.com" -b "BDUSS=Ux4ZDZHdnRwaHZLWmt5M29TaU1qMkE3akNLc2dISHJyaFVBYXJvd2RaOEpveGxqSUFBQUFBJCQAAAAAAAAAAAEAAAA4GgQ6d2luN19saW51eF8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAkW8mIJFvJiN"
}

jenkins_download

#放行防火墙和关闭selinux
systemctl enable --now firewalld
firewall-cmd --set-default-zone=trusted && setenforce 0
sed -i '/SELINUX/s/enforcing/permissive/' /etc/selinux/config && sleep 5
#装软件启动服务
yum  install git postfix mailx java-11-openjdk
systemctl enable --now postfix
#安装jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo --no-check-certificate
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum clean all && yum repolist && yum install jenkins-2.164.3
systemctl enable --now jenkins

