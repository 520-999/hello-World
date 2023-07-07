#!/bin/bash
#安装kvm并启动一个虚拟机

. ./public_functions

#----------------------------------------
logG "判断硬件是否支持虚拟化，系统是否支持kvm模块"
logY "lscpu | grep vmx && lsmod | grep kvm"
lscpu | grep vmx
checkTF
lsmod | grep kvm
checkTF

logG "开始安装虚拟化软件"
logY "yum -y install qemu-kvm libvirt-daemon libvirt-daemon-driver-qemu libvirt-client"
yum -y install qemu-kvm libvirt-daemon libvirt-daemon-driver-qemu libvirt-client
checkTF

logG "启动虚拟化服务"
logY "systemctl enable --now libvirtd"
systemctl enable --now libvirtd
checkTF

logG "libvirtd信息↓↓"
virsh version

create_Virtualbridge() {

 logG "创建虚拟网卡文件"
 logY "cat >/etc/libvirt/qemu/networks/vbr.xml << EOF..."
cat >/etc/libvirt/qemu/networks/vbr.xml <<-EOF
<network>
  <name>vbr</name>
  <forward mode='nat'/>
  <bridge name='vbr' stp='on' delay='0'/>
  <ip address='192.168.100.254' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.100' end='192.168.100.200'/>
    </dhcp>
  </ip>
</network>
EOF
checkTF

  logG "应用虚拟网卡文件"
  logY "virsh net-define /etc/libvirt/qemu/networks/vbr.xml"
  virsh net-define /etc/libvirt/qemu/networks/vbr.xml
  checkTF

  logG "启动虚拟网卡"
  logY "virsh net-start vbr"
  virsh net-autostart vbr
  virsh net-start vbr
  checkTF
}

virsh net-list --all | grep vbr
if [ $? -eq 0 ]; then
  logG "虚拟网卡vbr已存在"
  logG "启动vbr..."
  virsh net-autostart vbr
  virsh net-start vbr 2> dev/null
else
  create_Virtualbridge 
fi

logG "虚拟网卡信息↓↓"
virsh net-list


logG "创建虚拟机配置文件image_Mould.xml.mould"
logY "cat >/etc/libvirt/qemu/image_Mould.xml.mould <<-EOF..."
cat >/etc/libvirt/qemu/image_Mould.xml.mould <<-EOF
<domain type='kvm'>
  <name>image_Mould</name>
  <memory unit='KB'>2248000</memory>
  <currentMemory unit='KB'>2248000</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <boot dev='hd'/>
    <bootmenu enable='yes'/>
    <bios useserial='yes'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough'>
  </cpu>
  <clock offset='localtime'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/qemu-kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/image_Mould.img'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='bridge'>
      <source bridge='vbr'/>
      <model type='virtio'/>
    </interface>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <serial type='pty'></serial>
    <console type='pty'>
      <target type='serial'/>
    </console>
    <memballoon model='virtio'></memballoon>
  </devices>
</domain>
EOF
checkTF

readonly qcow2_Image_Mould="CentOS-7-x86_64-GenericCloud-2009.qcow2"

download_Qcow2() {
  curl -o /var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud-2009.qcow2 --create-dirs -# -c -O ftp://mybd.work/CentOS-7-x86_64-GenericCloud-2009.qcow2
}

if [ -f /var/lib/libvirt/images/$qcow2_Image_Mould ]; then
  logY "模板镜像$qcow2_Image_Mould 已存在，无需下载"
else
  logG "开始下载$qcow2_Image_Mould 到 /var/lib/libvirt/images/"
  download_Qcow2
  checkTF
fi

readonly vmhost1="centos7.9-1"

create_Virtualhost() {

  dir="/var/lib/libvirt/images"
  logG "开始创建$vmhost1虚拟机镜像盘..."
  logY "qemu-img create -f qcow2 -b $dir/$qcow2_Image_Mould  $dir/$vmhost1.img 30G"
  qemu-img create -f qcow2 -b $dir/$qcow2_Image_Mould  $dir/${vmhost1}.img 30G
  checkTF
  qemu-img info $dir/$vmhost1.img

  logG "开始创建$vmhost1虚拟机配置文件..."
  logY "virsh define /etc/libvirt/qemu/$vmhost1.xml"
  cp /etc/libvirt/qemu/image_Mould.xml.mould /etc/libvirt/qemu/${vmhost1}.xml
  sed -i "s/image_Mould/${vmhost1}/g" /etc/libvirt/qemu/${vmhost1}.xml
  virsh define /etc/libvirt/qemu/${vmhost1}.xml
  checkTF

  logG "启动虚拟机$vmhost1"
  logY "virsh start $vmhost1"
  virsh start $vmhost1
  checkTF
  virsh list --all
}

#判断即将要创建的虚拟机是否存在，若不存在就创建
for i in `virsh list --all | awk 'NR>1 {print $2}' | xargs -L1`
do
  if [ "$vmhost1" == $i ]; then
     logG "$vmhost1已存在"
     exit 0
  else
     create_Virtualhost
     exit 0
  fi
done
