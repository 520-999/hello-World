#!/bin/bash
#
clear
. ./public_functions
. ./public_functions

#添加主机到/etc/hosts
set_Hosts() {
  logG "配置主机名文件 /etc/hosts"
  logY "sed -i -e '\$a 180.76.243.8 bd1; \$a 180.76.178.226 bd2'"
  sed -i -e'
    $a 180.76.243.8    node1
    $a 180.76.178.226  node2
  ' /etc/hosts
  checkTF
}


#生成管理机公钥
if [ -f ~/.ssh/id_rsa ];then
  logY "~/.ssh/id_rsa.pub 公钥已存在\n\n"
else
  ssh-keygen -f ~/.ssh/id_rsa -P '' -q
  checkTF
fi


#向被控主机传输公钥
set_Hosts_id_rsa() {
  logG "根据hosts文件向主机IP传输公钥"
  logY "ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no \$i"
  for i in `grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/hosts | grep -v '^127'`;do
    ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $i
    checkTF
  done
}
set_Hosts_id_rsa


#安装ansible软件
install_Ansible() {
  logG "开始安装ansible"
  logY "yum -y install ansible"
  yum -y install ansible
  checkTF
}
rpm -qa | grep ansible
if [ $? == 0 ];then
  logY "检测到 ansible 已安装\n\n"
else
  install_Ansible
fi


#修改ansible配置--inventory条目
logG "修改ansible配置文件如下"
grep '#inventory  *=' /etc/ansible/ansible.cfg
if [ $? == 0 ];then
  sed -i 's/#inventory\(  *=\)/inventory\1/' /etc/ansible/ansible.cfg
fi
#显示修改后的条目
grep 'inventory  *=' /etc/ansible/ansible.cfg

#修改ansible配置--host_key_checking条目
grep '#host_key_checking = False' /etc/ansible/ansible.cfg
if [ $? == 0 ];then
  sed -i 's/#host_key_checking = False/host_key_checking = False/' /etc/ansible/ansible.cfg
fi
#显示修改后的条目
grep 'host_key_checking = False' /etc/ansible/ansible.cfg
logG "\n\n"


#配置/etc/ansible/hosts文件
logG "修改清单文件 /etc/ansible/hosts"
grep '\[zu1\]' /etc/ansible/hosts
if [ $? == 0 ];then
  logY "组已存在，不做重复更改"
else
  grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*' /etc/hosts | grep -v '^127' | awk 'BEGIN {print "[zu1]"} {print $2}' >> /etc/ansible/hosts
  checkTF
fi
logG "\n\n"


logY "被控机器列表如下"
ansible all --list-host


