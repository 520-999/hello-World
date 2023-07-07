#!/bin/bash
# 安装kubernetes
. ./public_functions


logY "1. 本机信息↓↓"
logW "`lscpu | grep 'Core(s) per socket'` "
logW "kernel:         `uname -r` "
logW "firewalld:      `systemctl is-enabled firewalld` "
logW "firewalld:      `firewall-cmd --state` "
logW "selinux:        `getenforce` "
logW "`cat /proc/meminfo | grep MemTotal` " && echo ""

logW "2. 配置kubernetes的yum源"
logY "cat <<EOF > /etc/yum.repos.d/kubernetes.repo..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
gpgcheck=0
EOF
yum repolist | grep kubernetes
checkTF

logW "3. 安装kubelet kubeadm kubectl"
logY "yum -y install kubelet-1.17.6 kubeadm-1.17.6 kubectl-1.17.6"
yum -y install  kubeadm-1.17.6 && checkTF kubelet-1.17.6 && checkTF kubectl-1.17.6 && checkTF

logW "4. 启动kubelet"
logY "systemctl enable --now kubelet"
systemctl enable --now kubelet
checkTF

logY "5. 设置/etc/sysctl.d/k8s.conf"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
cat /etc/sysctl.d/k8s.conf
modprobe br_netfilter && sysctl --system  ##手动加载内核模块
checkTF

logW "6. 设置kubectl kubeadm tab键"
logY "kubectl completion bash >/etc/bash_completion.d/kubectl"
logY "kubeadm completion bash >/etc/bash_completion.d/kubeadm"
kubectl completion bash >/etc/bash_completion.d/kubectl
kubeadm completion bash >/etc/bash_completion.d/kubeadm
checkTF

logW "7. 安装ipvsadm ipset"
logY "yum -y install ipvsadm && checkTF ipset && checkTF"
yum -y install ipvsadm && checkTF ipset && checkTF

#logY "配置主机名"
#cat <<EOF > /etc/hosts
#127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
#192.168.1.20    master
#192.168.1.31    node1
#192.168.1.32    node2
#192.168.1.33    node3
#192.168.1.100   registry
#EOF
#cat /etc/hosts
